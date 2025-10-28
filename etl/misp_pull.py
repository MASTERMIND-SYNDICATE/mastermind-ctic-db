#!/usr/bin/env python3
from dotenv import load_dotenv
load_dotenv()

import os, logging, warnings, json
from datetime import datetime, timezone
import requests
from requests.packages.urllib3.exceptions import InsecureRequestWarning
import psycopg2

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s", force=True)
log = logging.getLogger("misp_pull")

ALLOWED = {"ip-dst", "ip-src", "domain", "hostname", "url", "md5", "sha1", "sha256", "filename|sha256"}
TYPE_MAP = {
    "ip-dst":"ip-dst", "ip-src":"ip-src", "domain":"domain", "hostname":"hostname", "url":"url",
    "md5":"md5", "sha1":"sha1", "sha256":"sha256", "filename|sha256":"filename|sha256",
    "uri":"url", "uri-dst":"url", "link":"url", "fqdn":"hostname", "malware-sample":"filename|sha256"
}

def map_type(t):
    t = (t or "").lower()
    m = TYPE_MAP.get(t, t)
    return m if m in ALLOWED else None

def dsn():
    return dict(
        host=os.getenv("PGHOST", "postgres"),
        port=int(os.getenv("PGPORT", "5432")),
        dbname=os.getenv("PGDATABASE", "cticdb"),
        user=os.getenv("PGUSER", "ctic"),
        password=os.getenv("PGPASSWORD", "cticpw"),
    )

def ensure_tables(conn):
    with conn, conn.cursor() as cur:
        cur.execute("""
            CREATE TABLE IF NOT EXISTS public.indicators(
              indicator_id BIGSERIAL PRIMARY KEY,
              value        TEXT UNIQUE NOT NULL,
              type         TEXT NOT NULL,
              source       TEXT NOT NULL,
              first_seen   TIMESTAMPTZ,
              last_seen    TIMESTAMPTZ,
              ocsf         JSONB
            );""")
        cur.execute("""
            CREATE TABLE IF NOT EXISTS public.etl_runs(
              etl_run_id     BIGSERIAL PRIMARY KEY,
              job            TEXT NOT NULL,
              started_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
              finished_at    TIMESTAMPTZ,
              status         TEXT,
              inserted_count INT DEFAULT 0,
              updated_count  INT DEFAULT 0,
              error_count    INT DEFAULT 0,
              notes          TEXT
            );""")

def fetch_attributes():
    url = os.getenv("MISP_URL", "https://host.docker.internal").rstrip("/")
    key = os.getenv("MISP_KEY")
    verify = os.getenv("MISP_VERIFY_SSL", "false").lower() == "true"
    if not verify:
        warnings.simplefilter("ignore", InsecureRequestWarning)
        requests.packages.urllib3.disable_warnings(InsecureRequestWarning)
    if not url or not key:
        log.error("MISP_URL or MISP_KEY missing")
        raise RuntimeError("MISP_URL or MISP_KEY missing")
    limit = int(os.getenv("MISP_LIMIT", 100))
    payload = {"returnFormat": "json", "limit": limit}
    headers = {
        "Authorization": key,
        "Content-Type": "application/json",
        "Accept": "application/json",
    }
    try:
        r = requests.post(
            f"{url}/attributes/restSearch.json",
            headers=headers,
            data=json.dumps(payload),
            verify=verify,
            timeout=60
        )
        r.raise_for_status()
        j = r.json()
        log.info("POST to MISP executed successfully [URL: %s, Limit: %d]", url, limit)
        log.info("Payload sent: {'returnFormat':..., 'limit':...}")
        return (j.get("response", {}).get("Attribute") or j.get("data") or [])
    except Exception as e:
        log.error("Request to MISP failed: %s", e)
        return []

def build_ocsf_indicator(a):
    """
    Builds an OCSF-compliant indicator event from raw MISP attribute.
    Extend fields as needed for full OCSF.
    """
    return {
        "event_time": datetime.utcnow().isoformat(),
        "event_class_id": 1003,  # OCSF Threat Intel event
        "category": "threat intelligence",
        "severity": "info",
        "actor": {"type": "system", "name": "misp"},
        "observable": {
            "type": a.get("type"),
            "value": a.get("value")
        },
        "source": "misp",
        "data": a
    }

def upsert_attrs(conn, attrs):
    inserted = updated = errors = 0
    with conn, conn.cursor() as cur:
        for a in attrs:
            try:
                value = a.get("value")
                t = map_type(a.get("type"))
                if not value or not t:
                    continue
                ts = int(a.get("timestamp") or 0) or int(datetime.now(timezone.utc).timestamp())
                seen = datetime.fromtimestamp(ts, timezone.utc)
                ocsf = build_ocsf_indicator({**a, "value": value, "type": t, "source": "misp", "timestamp": ts})
                cur.execute("""
                  INSERT INTO public.indicators(value, type, source, first_seen, last_seen, ocsf)
                  VALUES(%s,%s,'misp',%s,%s,%s)
                  ON CONFLICT (value) DO UPDATE
                    SET type = EXCLUDED.type,
                        source = EXCLUDED.source,
                        first_seen = LEAST(COALESCE(public.indicators.first_seen, EXCLUDED.first_seen), EXCLUDED.first_seen),
                        last_seen  = GREATEST(COALESCE(public.indicators.last_seen,  EXCLUDED.last_seen),  EXCLUDED.last_seen),
                        ocsf = EXCLUDED.ocsf
                  RETURNING (xmax=0) AS ins
                """, (value, t, seen, seen, json.dumps(ocsf)))
                if cur.fetchone()[0]: inserted += 1
                else: updated += 1
            except Exception as e:
                errors += 1
                log.warning("row error: %s", e)
    return inserted, updated, errors

def export_ocsf_indicators(attrs, fname="ocsf_indicators.jsonl"):
    with open(fname, "w") as f:
        for attr in attrs:
            ocsf = build_ocsf_indicator(attr)
            f.write(json.dumps(ocsf) + "\n")
    log.info("Exported %d OCSF indicator events to %s", len(attrs), fname)

def run_once():
    log.info("Starting MISP pull ETL.")
    conn = psycopg2.connect(**dsn())
    ensure_tables(conn)
    with conn, conn.cursor() as cur:
        cur.execute(
            "INSERT INTO public.etl_runs(job, started_at) VALUES(%s, now()) RETURNING etl_run_id",
            ("misp_pull",),
        )
        run_id = cur.fetchone()[0]
    status, notes = "ok", None
    ins = upd = err = 0
    try:
        attrs = fetch_attributes()
        log.info("Fetched %d attributes from MISP.", len(attrs))
        ins, upd, err = upsert_attrs(conn, attrs)
        export_ocsf_indicators(attrs)
        if err:
            status = "error"
            notes = f"errors={err}"
    except Exception as e:
        status = "error"
        notes = f"error={e}"
        log.error("Script error: %s", e)
    with conn, conn.cursor() as cur:
        cur.execute("""
            UPDATE public.etl_runs
               SET finished_at=now(),
                   status=%s,
                   inserted_count=%s,
                   updated_count=%s,
                   error_count=%s,
                   notes=%s
             WHERE etl_run_id=%s
        """, (status, ins, upd, err, notes, run_id))
    conn.close()
    log.info("Upserted %d IoCs (inserted %d, updated %d). Errors=%d", ins+upd, ins, upd, err)

def main():
    run_once()

if __name__ == "__main__":
    main()
