#!/usr/bin/env python3
import os, json, time, warnings
from datetime import datetime, timedelta, timezone

import psycopg2
import psycopg2.extras
import requests
from requests.packages.urllib3.exceptions import InsecureRequestWarning
import logging

# --- Logging Setup ---
logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s", force=True)
log = logging.getLogger("wazuh_sightings")

# --- Config ---
PG_DSN       = os.getenv("PG_DSN", "dbname=cticdb user=ctic password=cticpw host=postgres port=5432")
SRC_SYSTEM   = os.getenv("WAZUH_SRC", "wazuh")
MOCK_PATH    = os.getenv("WZ_MOCK_PATH", "etl/mock/wz.json")

WAZUH_URL    = os.getenv("WAZUH_URL")
WAZUH_USER   = os.getenv("WAZUH_USER")
WAZUH_PASS   = os.getenv("WAZUH_PASS")
WAZUH_INSECURE   = os.getenv("WAZUH_INSECURE", "false").lower() == "true"
LOOKBACK_MIN     = int(os.getenv("WAZUH_QUERY_MINUTES", "60"))
LIMIT            = int(os.getenv("WAZUH_LIMIT", "500"))
INTERVAL_SEC     = int(os.getenv("ETL_INTERVAL_SEC", "0"))  # 0 = run once

if WAZUH_INSECURE:
    warnings.filterwarnings("ignore", category=InsecureRequestWarning)

def pg():
    return psycopg2.connect(PG_DSN)

def ensure_tables():
    with pg() as conn, conn.cursor() as cur:
        cur.execute("""
        CREATE TABLE IF NOT EXISTS public.sightings(
          sighting_id   BIGSERIAL PRIMARY KEY,
          indicator_id  BIGINT NOT NULL,
          src_system    TEXT   NOT NULL,
          context       JSONB  NOT NULL,
          ocsf          JSONB
        );
        """)
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
        );
        """)

def fetch_wazuh_events():
    if not (WAZUH_URL and WAZUH_USER and WAZUH_PASS):
        if not os.path.exists(MOCK_PATH):
            return []
        with open(MOCK_PATH, "r", encoding="utf-8") as f:
            data = json.load(f)
        return [json.dumps(ev, separators=(",", ":"), ensure_ascii=False)
                for ev in (data if isinstance(data, list) else [])]

    base = WAZUH_URL.rstrip("/")
    auth = (WAZUH_USER, WAZUH_PASS)
    since = (datetime.now(timezone.utc) - timedelta(minutes=LOOKBACK_MIN)).isoformat()
    params = {"limit": LIMIT, "q": f"timestamp>={since}"}
    try:
        resp = requests.get(f"{base}/security/events", params=params,
                            auth=auth, verify=not WAZUH_INSECURE, timeout=30)
        resp.raise_for_status()
        js = resp.json()
        items = js.get("data", {}).get("items") or js.get("data") or []
        seq = items if isinstance(items, list) else [items]
        return [json.dumps(ev, separators=(",", ":"), ensure_ascii=False) for ev in seq]
    except Exception as e:
        try:
            if os.path.exists(MOCK_PATH):
                with open(MOCK_PATH, "r", encoding="utf-8") as f:
                    data = json.load(f)
                return [json.dumps(ev, separators=(",", ":"), ensure_ascii=False)
                        for ev in (data if isinstance(data, list) else [])]
        except:
            pass
        log.warning("wazuh fetch failed: %s", e)
        return []

def build_ocsf(raw_event_json, indicator_value, indicator_type, indicator_id):
    try:
        raw_event = json.loads(raw_event_json)
    except Exception:
        raw_event = {}
    ocsf_obj = {
        "event_class_id": 1002,
        "category": "threat detection",
        "severity": "medium",
        "timestamp": raw_event.get("timestamp", datetime.utcnow().isoformat()),
        "actor": {"type": "system", "name": "wazuh"},
        "target": {"type": indicator_type, "value": indicator_value},
        "observable": {"type": indicator_type, "value": indicator_value},
        "data": raw_event,
        "indicator_id": indicator_id
    }
    log.debug("inserting OCSF: %s", ocsf_obj)
    return ocsf_obj

def run_once():
    ensure_tables()
    events = fetch_wazuh_events()
    log.info("events=%d", len(events))

    with pg() as conn:
        run_id = None
        try:
            with conn.cursor() as cur:
                cur.execute(
                    "INSERT INTO public.etl_runs(job, started_at) VALUES(%s, now()) RETURNING etl_run_id",
                    ("wazuh_sightings",),
                )
                run_id = cur.fetchone()[0]

            inserted = 0
            if events:
                with conn.cursor(cursor_factory=psycopg2.extras.DictCursor) as cur:
                    cur.execute("SELECT indicator_id, value, type FROM public.indicators")
                    indicators = cur.fetchall()

                for event_json in events:
                    for indicator in indicators:
                        if indicator["value"] in event_json:
                            ocsf_record = build_ocsf(event_json, indicator["value"], indicator["type"], indicator["indicator_id"])
                            with conn.cursor() as cur2:
                                cur2.execute("""
                                    INSERT INTO public.sightings(indicator_id, src_system, seen_on, context, ocsf)
                                    VALUES (%s, %s, now(), %s, %s)
                                    ON CONFLICT DO NOTHING
                                """, (
                                    indicator["indicator_id"],
                                    SRC_SYSTEM,
                                    json.dumps({"raw": event_json, "ingested_at": datetime.utcnow().isoformat()}),
                                    json.dumps(ocsf_record)  # critical: always json.dumps!
                                ))
                            inserted += 1
                status, notes = "ok", f"{inserted} sightings inserted"
            else:
                status, notes = "ok", "no events"

            with conn.cursor() as cur:
                cur.execute("""
                    UPDATE public.etl_runs
                       SET finished_at   = now(),
                           status         = %s,
                           inserted_count = %s,
                           notes          = %s
                     WHERE etl_run_id     = %s
                """, (status, inserted, notes, run_id))
            conn.commit()
            log.info("inserted=%d status=%s", inserted, status)
            return inserted

        except Exception as e:
            try:
                conn.rollback()
                if run_id is None:
                    with conn.cursor() as cur:
                        cur.execute(
                            "INSERT INTO public.etl_runs(job, started_at, status, error_count, notes) VALUES(%s, now(), %s, 1, %s)",
                            ("wazuh_sightings", "error", f"error={e}"),
                        )
                else:
                    with conn.cursor() as cur:
                        cur.execute("""
                            UPDATE public.etl_runs
                               SET finished_at = now(),
                                   status       = %s,
                                   error_count  = error_count + 1,
                                   notes        = %s
                             WHERE etl_run_id   = %s
                        """, ("error", f"error={e}", run_id))
                conn.commit()
            except Exception:
                conn.rollback()
            log.error("%s", e)
            return 0

def main():
    if INTERVAL_SEC <= 0:
        run_once()
        return
    while True:
        try:
            run_once()
        except Exception as e:
            log.error("%s", e)
        time.sleep(INTERVAL_SEC)

if __name__ == "__main__":
    main()
