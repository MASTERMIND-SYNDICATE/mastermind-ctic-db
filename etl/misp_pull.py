#!/usr/bin/env python3
import os, logging, warnings
from datetime import datetime, timezone

import requests
from requests.packages.urllib3.exceptions import InsecureRequestWarning
import psycopg2

# ---- logging ----
logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
log = logging.getLogger("misp_pull")

# ---- config ----
ALLOWED = {"ip-dst","ip-src","domain","hostname","url","md5","sha1","sha256","filename|sha256"}
TYPE_MAP = {
    "ip-dst":"ip-dst","ip-src":"ip-src","domain":"domain","hostname":"hostname","url":"url",
    "md5":"md5","sha1":"sha1","sha256":"sha256","filename|sha256":"filename|sha256",
    "uri":"url","uri-dst":"url","link":"url","fqdn":"hostname","malware-sample":"filename|sha256"
}

def map_type(t: str | None):
    t = (t or "").lower()
    m = TYPE_MAP.get(t, t)
    return m if m in ALLOWED else None

def dsn():
    return dict(
        host=os.getenv("PGHOST","postgres"),
        port=int(os.getenv("PGPORT","5432")),
        dbname=os.getenv("PGDATABASE","cticdb"),
        user=os.getenv("PGUSER","ctic"),
        password=os.getenv("PGPASSWORD","cticpw"),
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
          last_seen    TIMESTAMPTZ
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
    url = (os.getenv("MISP_URL","").rstrip("/"))
    key = os.getenv("MISP_KEY")  # use MISP_KEY from .env
    verify = os.getenv("MISP_VERIFY_SSL","false").lower() == "true"
    if not verify:
        warnings.simplefilter("ignore", InsecureRequestWarning)
        requests.packages.urllib3.disable_warnings(InsecureRequestWarning)

    if not url or not key:
        raise RuntimeError("MISP_URL or MISP_KEY missing")

    since_days = int(os.getenv("MISP_SINCE_DAYS","7"))
    limit = int(os.getenv("MISP_LIMIT","500"))
    payload = {"timestamp": f"-{since_days}d", "limit": limit}

    headers = {
        "Authorization": key,
        "Content-Type": "application/json",
        "Accept": "application/json",
    }

    r = requests.post(f"{url}/attributes/restSearch.json",
                      headers=headers, json=payload, verify=verify, timeout=60)
    r.raise_for_status()
    j = r.json()
    return (j.get("response", {}).get("Attribute")
            or j.get("data")
            or [])

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
                cur.execute("""
                  INSERT INTO public.indicators(value, type, source, first_seen, last_seen)
                  VALUES(%s,%s,'misp',%s,%s)
                  ON CONFLICT (value) DO UPDATE
                    SET first_seen = LEAST(COALESCE(public.indicators.first_seen, EXCLUDED.first_seen), EXCLUDED.first_seen),
                        last_seen  = GREATEST(COALESCE(public.indicators.last_seen,  EXCLUDED.last_seen),  EXCLUDED.last_seen)
                  RETURNING (xmax=0) AS ins
                """, (value, t, seen, seen))
                if cur.fetchone()[0]: inserted += 1
                else: updated += 1
            except Exception as e:
                errors += 1
                log.warning("row error: %s", e)
    return inserted, updated, errors

def run_once():
    conn = psycopg2.connect(**dsn())
    ensure_tables(conn)

    # start run row (no intermediate status to satisfy status CHECK)
    with conn, conn.cursor() as cur:
        cur.execute(
            "INSERT INTO public.etl_runs(job, started_at) VALUES(%s, now()) RETURNING etl_run_id",
            ("misp_pull",),
        )
        run_id = cur.fetchone()[0]

    status = "ok"
    notes = None
    ins = upd = err = 0
    try:
        attrs = fetch_attributes()
        ins, upd, err = upsert_attrs(conn, attrs)
        if err:
            status = "error"
            notes = f"errors={err}"
    except Exception as e:
        status = "error"
        notes = f"error={e}"

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
