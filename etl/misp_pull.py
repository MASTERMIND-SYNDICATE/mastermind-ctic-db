#!/usr/bin/env python3
"""MISP indicator ingestion pipeline.

Pulls IOC attributes from a MISP instance, normalises them to the
Open-CTIC indicator schema with an OCSF-compliant payload, and upserts
them into PostgreSQL.  Each run is audited in ``public.etl_runs``.

Usage:
    python -m etl.misp_pull          # single run
    ETL_INTERVAL_SEC=300 python -m etl.misp_pull  # loop every 5 min
"""

from __future__ import annotations

import json
import logging
import warnings
from datetime import UTC, datetime
from typing import Any

import psycopg2
import requests
from requests.packages.urllib3.exceptions import InsecureRequestWarning

from etl import config
from etl.db import ensure_tables, get_connection

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
)
log = logging.getLogger("etl.misp_pull")

# ---------------------------------------------------------------------------
# MISP type normalisation
# ---------------------------------------------------------------------------

ALLOWED_TYPES = frozenset(
    {
        "ip-dst",
        "ip-src",
        "domain",
        "hostname",
        "url",
        "md5",
        "sha1",
        "sha256",
        "filename|sha256",
    }
)

TYPE_MAP: dict[str, str] = {
    "ip-dst": "ip-dst",
    "ip-src": "ip-src",
    "domain": "domain",
    "hostname": "hostname",
    "url": "url",
    "md5": "md5",
    "sha1": "sha1",
    "sha256": "sha256",
    "filename|sha256": "filename|sha256",
    "uri": "url",
    "uri-dst": "url",
    "link": "url",
    "fqdn": "hostname",
    "malware-sample": "filename|sha256",
}


def normalise_type(raw_type: str) -> str | None:
    """Map a raw MISP attribute type to a canonical indicator type."""
    mapped = TYPE_MAP.get((raw_type or "").lower(), (raw_type or "").lower())
    return mapped if mapped in ALLOWED_TYPES else None


# ---------------------------------------------------------------------------
# MISP API client
# ---------------------------------------------------------------------------


def fetch_attributes() -> list[dict[str, Any]]:
    """Fetch IOC attributes from the configured MISP instance."""
    url = config.MISP_URL.rstrip("/") if config.MISP_URL else ""
    key = config.MISP_KEY

    if not url or not key:
        log.error("MISP_URL or MISP_KEY not configured — skipping fetch")
        return []

    if not config.MISP_VERIFY_SSL:
        warnings.filterwarnings("ignore", category=InsecureRequestWarning)

    headers = {
        "Authorization": key,
        "Content-Type": "application/json",
        "Accept": "application/json",
    }
    payload: dict[str, Any] = {
        "returnFormat": "json",
        "limit": config.MISP_LIMIT,
    }
    if config.MISP_TAGS:
        payload["tags"] = config.MISP_TAGS.split(",")

    try:
        resp = requests.post(
            f"{url}/attributes/restSearch.json",
            headers=headers,
            json=payload,
            verify=config.MISP_VERIFY_SSL,
            timeout=60,
        )
        resp.raise_for_status()
        body = resp.json()
        attrs = body.get("response", {}).get("Attribute") or body.get("data") or []
        log.info("Fetched %d attributes from MISP (%s)", len(attrs), url)
        return attrs
    except requests.RequestException as exc:
        log.error("MISP request failed: %s", exc)
        return []


# ---------------------------------------------------------------------------
# OCSF builder
# ---------------------------------------------------------------------------


def build_ocsf_indicator(attr: dict[str, Any]) -> dict[str, Any]:
    """Build an OCSF Threat Intel indicator event (class_id=1003)."""
    return {
        "event_time": datetime.now(UTC).isoformat(),
        "event_class_id": 1003,
        "category": "threat intelligence",
        "severity": "info",
        "actor": {"type": "system", "name": "misp"},
        "observable": {
            "type": attr.get("type"),
            "value": attr.get("value"),
        },
        "source": "misp",
        "data": attr,
    }


# ---------------------------------------------------------------------------
# Database upsert
# ---------------------------------------------------------------------------


def upsert_attributes(conn: Any, attrs: list[dict[str, Any]]) -> tuple[int, int, int]:
    """Upsert MISP attributes into ``public.indicators``.

    Returns:
        Tuple of (inserted, updated, errors).
    """
    inserted = updated = errors = 0

    with conn, conn.cursor() as cur:
        for attr in attrs:
            value = (attr.get("value") or "").strip()
            ind_type = normalise_type(attr.get("type", ""))
            if not value or not ind_type:
                continue

            ts = int(attr.get("timestamp") or 0) or int(datetime.now(UTC).timestamp())
            seen = datetime.fromtimestamp(ts, UTC)
            ocsf = build_ocsf_indicator({**attr, "value": value, "type": ind_type})

            try:
                cur.execute(
                    """
                    INSERT INTO public.indicators
                        (value, type, source, first_seen, last_seen, ocsf)
                    VALUES (%s, %s, 'misp', %s, %s, %s)
                    ON CONFLICT (value) DO UPDATE SET
                        type       = EXCLUDED.type,
                        source     = EXCLUDED.source,
                        first_seen = LEAST(
                            COALESCE(indicators.first_seen, EXCLUDED.first_seen),
                            EXCLUDED.first_seen
                        ),
                        last_seen  = GREATEST(
                            COALESCE(indicators.last_seen, EXCLUDED.last_seen),
                            EXCLUDED.last_seen
                        ),
                        ocsf       = EXCLUDED.ocsf
                    RETURNING (xmax = 0) AS is_insert
                    """,
                    (value, ind_type, seen, seen, json.dumps(ocsf)),
                )
                if cur.fetchone()[0]:
                    inserted += 1
                else:
                    updated += 1
            except psycopg2.Error as exc:
                errors += 1
                log.warning("Row error for value=%s: %s", value, exc)

    return inserted, updated, errors


# ---------------------------------------------------------------------------
# Orchestrator
# ---------------------------------------------------------------------------


def run_once() -> None:
    """Execute a single MISP pull cycle."""
    log.info("Starting MISP pull cycle")
    conn = get_connection()
    ensure_tables(conn)

    # Record ETL run start.
    with conn, conn.cursor() as cur:
        cur.execute(
            "INSERT INTO public.etl_runs (job, started_at) "
            "VALUES ('misp_pull', now()) RETURNING etl_run_id",
        )
        run_id = cur.fetchone()[0]

    status, notes = "ok", None
    inserted = updated = errors = 0

    try:
        attrs = fetch_attributes()
        log.info("Processing %d attributes", len(attrs))
        inserted, updated, errors = upsert_attributes(conn, attrs)
        if errors:
            status = "error"
            notes = f"errors={errors}"
    except Exception as exc:
        status, notes = "error", str(exc)
        log.exception("MISP pull failed")

    # Record ETL run completion.
    with conn, conn.cursor() as cur:
        cur.execute(
            """
            UPDATE public.etl_runs
               SET finished_at = now(),
                   status = %s,
                   inserted_count = %s,
                   updated_count = %s,
                   error_count = %s,
                   notes = %s
             WHERE etl_run_id = %s
            """,
            (status, inserted, updated, errors, notes, run_id),
        )

    conn.close()
    log.info(
        "Cycle complete: inserted=%d updated=%d errors=%d",
        inserted,
        updated,
        errors,
    )


def main() -> None:
    """Entry point — run once (looping is handled by the container)."""
    run_once()


if __name__ == "__main__":
    main()
