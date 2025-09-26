#!/usr/bin/env python3
import os, json, time, warnings
from datetime import datetime, timedelta, timezone

import psycopg2
import psycopg2.extras
import requests
from requests.packages.urllib3.exceptions import InsecureRequestWarning

# --- Config ---
PG_DSN       = os.getenv("PG_DSN", "dbname=cticdb user=ctic password=cticpw host=postgres port=5432")
SRC_SYSTEM   = os.getenv("WAZUH_SRC", "wazuh")
MOCK_PATH    = os.getenv("WZ_MOCK_PATH", "etl/mock/wz.json")

WAZUH_URL    = os.getenv("WAZUH_URL")             # e.g. https://wazuh:55000
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
    # Keep compatible with existing DB (etl_runs has etl_run_id PK, job, status with CHECK in ('ok','error'))
    with pg() as conn, conn.cursor() as cur:
        cur.execute("""
        CREATE TABLE IF NOT EXISTS public.sightings(
          sighting_id   BIGSERIAL PRIMARY KEY,
          indicator_id  BIGINT NOT NULL,
          src_system    TEXT   NOT NULL,
          context       JSONB  NOT NULL
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
    # Return a list[str] of compact JSON blobs to scan
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
        # Fallback to mock if present
        try:
            if os.path.exists(MOCK_PATH):
                with open(MOCK_PATH, "r", encoding="utf-8") as f:
                    data = json.load(f)
                return [json.dumps(ev, separators=(",", ":"), ensure_ascii=False)
                        for ev in (data if isinstance(data, list) else [])]
        except:
            pass
        print(f"[warn] wazuh fetch failed: {e}")
        return []

UPSERT_SQL = """
WITH src(rawtxt) AS (SELECT * FROM unnest(%s::text[])),
matches AS (
  SELECT i.indicator_id, rawtxt
  FROM src
  JOIN public.indicators i
    ON POSITION(i.value IN rawtxt) > 0
)
INSERT INTO public.sightings(indicator_id, src_system, seen_on, context)
SELECT m.indicator_id, %s::text,
       now(),
       jsonb_build_object('raw', m.rawtxt, 'ingested_at', now())
FROM matches m
ON CONFLICT DO NOTHING
RETURNING 1;
"""


def run_once():
    ensure_tables()
    events = fetch_wazuh_events()
    print(f"[info] events={len(events)}")

    with pg() as conn:
        run_id = None
        try:
            # Start run row with NULL status to avoid CHECK violation
            with conn.cursor() as cur:
                cur.execute(
                    "INSERT INTO public.etl_runs(job, started_at) VALUES(%s, now()) RETURNING etl_run_id",
                    ("wazuh_sightings",),
                )
                run_id = cur.fetchone()[0]

            inserted = 0
            if events:
                with conn.cursor() as cur:
                    cur.execute(UPSERT_SQL, (events, SRC_SYSTEM))
                    inserted = cur.rowcount
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
            print(f"[info] inserted={inserted} status={status}")
            return inserted

        except Exception as e:
            # Recover from aborted txn and mark the run as error
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
            print(f"[error] {e}")
            return 0

def main():
    if INTERVAL_SEC <= 0:
        run_once()
        return
    while True:
        try:
            run_once()
        except Exception as e:
            print(f"[error] {e}")
        time.sleep(INTERVAL_SEC)

if __name__ == "__main__":
    main()
