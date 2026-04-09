#!/usr/bin/env python3
"""Wazuh sightings ingestion pipeline.

Fetches security events from a Wazuh manager (or a local mock file),
matches them against known indicators in the database, and records
sightings with an OCSF-compliant payload.

Usage:
    python -m etl.wazuh_sightings               # single run
    ETL_INTERVAL_SEC=60 python -m etl.wazuh_sightings  # loop
"""

from __future__ import annotations

import json
import logging
import time
import warnings
from datetime import UTC, datetime, timedelta
from typing import Any

import psycopg2
import psycopg2.extras
import requests
from requests.packages.urllib3.exceptions import InsecureRequestWarning

from etl import config
from etl.db import ensure_tables, get_connection

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
)
log = logging.getLogger("etl.wazuh_sightings")

# ---------------------------------------------------------------------------
# Wazuh / mock event fetcher
# ---------------------------------------------------------------------------


def _load_mock_events(path: str) -> list[str]:
    """Load events from a local JSON mock file."""
    try:
        with open(path, encoding="utf-8") as fh:
            data = json.load(fh)
        events = data if isinstance(data, list) else []
        return [json.dumps(ev, separators=(",", ":"), ensure_ascii=False) for ev in events]
    except (FileNotFoundError, json.JSONDecodeError) as exc:
        log.warning("Cannot load mock events from %s: %s", path, exc)
        return []


def fetch_events() -> list[str]:
    """Fetch Wazuh security events or fall back to mock data.

    Returns a list of JSON-encoded event strings.
    """
    if not (config.WAZUH_URL and config.WAZUH_USER and config.WAZUH_PASS):
        log.info("Wazuh not configured — loading mock events")
        return _load_mock_events(config.WZ_MOCK_PATH)

    if config.WAZUH_INSECURE:
        warnings.filterwarnings("ignore", category=InsecureRequestWarning)

    base = config.WAZUH_URL.rstrip("/")
    since = (datetime.now(UTC) - timedelta(minutes=config.WAZUH_QUERY_MINUTES)).isoformat()

    try:
        resp = requests.get(
            f"{base}/security/events",
            params={"limit": config.WAZUH_LIMIT, "q": f"timestamp>={since}"},
            auth=(config.WAZUH_USER, config.WAZUH_PASS),
            verify=not config.WAZUH_INSECURE,
            timeout=30,
        )
        resp.raise_for_status()
        body = resp.json()
        items = body.get("data", {}).get("items") or body.get("data") or []
        if not isinstance(items, list):
            items = [items]
        log.info("Fetched %d events from Wazuh", len(items))
        return [json.dumps(ev, separators=(",", ":"), ensure_ascii=False) for ev in items]
    except requests.RequestException as exc:
        log.warning("Wazuh fetch failed (%s) — falling back to mock", exc)
        return _load_mock_events(config.WZ_MOCK_PATH)


# ---------------------------------------------------------------------------
# OCSF builder
# ---------------------------------------------------------------------------


def build_ocsf_sighting(
    raw_json: str,
    indicator_value: str,
    indicator_type: str,
    indicator_id: int,
) -> dict[str, Any]:
    """Build an OCSF Detection Finding event (class_id=1002)."""
    try:
        raw_event = json.loads(raw_json)
    except (json.JSONDecodeError, TypeError):
        raw_event = {}

    return {
        "event_class_id": 1002,
        "category": "threat detection",
        "severity": "medium",
        "timestamp": raw_event.get("timestamp", datetime.now(UTC).isoformat()),
        "actor": {"type": "system", "name": "wazuh"},
        "target": {"type": indicator_type, "value": indicator_value},
        "observable": {"type": indicator_type, "value": indicator_value},
        "data": raw_event,
        "indicator_id": indicator_id,
    }


# ---------------------------------------------------------------------------
# Indicator matching & sighting insertion
# ---------------------------------------------------------------------------


def _load_indicators(conn: Any) -> list[dict[str, Any]]:
    """Load all known indicators from the database."""
    with conn.cursor(cursor_factory=psycopg2.extras.DictCursor) as cur:
        cur.execute("SELECT indicator_id, value, type FROM public.indicators")
        return [dict(row) for row in cur.fetchall()]


def match_and_insert(conn: Any, events: list[str]) -> int:
    """Match events against indicators and insert sightings.

    Returns the number of sightings inserted.
    """
    if not events:
        return 0

    indicators = _load_indicators(conn)
    if not indicators:
        log.info("No indicators in database — nothing to match")
        return 0

    inserted = 0
    for event_json in events:
        for ind in indicators:
            if ind["value"] not in event_json:
                continue

            ocsf = build_ocsf_sighting(event_json, ind["value"], ind["type"], ind["indicator_id"])
            context = json.dumps(
                {
                    "raw": event_json,
                    "ingested_at": datetime.now(UTC).isoformat(),
                }
            )

            with conn.cursor() as cur:
                cur.execute(
                    """
                    INSERT INTO public.sightings
                        (indicator_id, src_system, seen_on, context, ocsf)
                    VALUES (%s, %s, CURRENT_DATE, %s, %s)
                    ON CONFLICT DO NOTHING
                    """,
                    (
                        ind["indicator_id"],
                        config.WAZUH_SRC,
                        context,
                        json.dumps(ocsf),
                    ),
                )
            inserted += 1

    return inserted


# ---------------------------------------------------------------------------
# Orchestrator
# ---------------------------------------------------------------------------


def run_once() -> int:
    """Execute a single Wazuh sightings cycle.

    Returns the number of sightings inserted.
    """
    log.info("Starting Wazuh sightings cycle")
    conn = get_connection()
    ensure_tables(conn)

    # Record ETL run start.
    run_id: int | None = None
    try:
        with conn, conn.cursor() as cur:
            cur.execute(
                "INSERT INTO public.etl_runs (job, started_at) "
                "VALUES ('wazuh_sightings', now()) RETURNING etl_run_id",
            )
            run_id = cur.fetchone()[0]

        events = fetch_events()
        log.info("Processing %d events", len(events))
        inserted = match_and_insert(conn, events)

        status = "ok"
        notes = f"{inserted} sightings inserted" if events else "no events"

        with conn.cursor() as cur:
            cur.execute(
                """
                UPDATE public.etl_runs
                   SET finished_at = now(),
                       status = %s,
                       inserted_count = %s,
                       notes = %s
                 WHERE etl_run_id = %s
                """,
                (status, inserted, notes, run_id),
            )
        conn.commit()
        log.info("Cycle complete: inserted=%d", inserted)
        return inserted

    except Exception as exc:
        log.exception("Wazuh sightings cycle failed")
        try:
            conn.rollback()
            with conn.cursor() as cur:
                if run_id is not None:
                    cur.execute(
                        """
                        UPDATE public.etl_runs
                           SET finished_at = now(),
                               status = 'error',
                               error_count = error_count + 1,
                               notes = %s
                         WHERE etl_run_id = %s
                        """,
                        (str(exc), run_id),
                    )
                else:
                    cur.execute(
                        "INSERT INTO public.etl_runs "
                        "(job, started_at, status, error_count, notes) "
                        "VALUES ('wazuh_sightings', now(), 'error', 1, %s)",
                        (str(exc),),
                    )
            conn.commit()
        except psycopg2.Error:
            log.exception("Failed to record ETL error")
        return 0
    finally:
        conn.close()


def main() -> None:
    """Entry point with optional looping."""
    interval = config.ETL_INTERVAL_SEC
    if interval <= 0:
        run_once()
        return

    while True:
        try:
            run_once()
        except Exception:
            log.exception("Unexpected error in run loop")
        time.sleep(interval)


if __name__ == "__main__":
    main()
