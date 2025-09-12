import os, sys, requests, psycopg, datetime as dt
PGHOST=os.getenv("PGHOST","127.0.0.1")
PGPORT=int(os.getenv("PGPORT","55432"))
PGDB=os.getenv("PGDATABASE","cticdb")
PGUSER=os.getenv("PGUSER","ctic")
PGPASS=os.getenv("PGPASSWORD","cticpw")
WAZUH_API=os.getenv("WAZUH_API","")   # e.g., https://wazuh:55000
WAZUH_USER=os.getenv("WAZUH_USER","")
WAZUH_PASS=os.getenv("WAZUH_PASS","")

def iter_events():
    if not WAZUH_API: 
        # demo: create a sighting for the demo IOC if present
        yield {"ioc":"198.51.100.13","src":"WazuhDemo","context":"demo-event"}
        return
    try:
        r=requests.get(f"{WAZUH_API}/security/events", auth=(WAZUH_USER,WAZUH_PASS), verify=False, timeout=10)
        r.raise_for_status()
        for ev in r.json().get("data",[]):
            ioc = ev.get("indicator") or ev.get("srcip") or ev.get("url")
            if ioc: yield {"ioc":ioc, "src":"Wazuh", "context":ev.get("rule","")}
    except Exception as e:
        print("Wazuh API error:", e)

def main():
    with psycopg.connect(host=PGHOST, port=PGPORT, user=PGUSER, password=PGPASS, dbname=PGDB) as conn:
        with conn.cursor() as cur:
            for ev in iter_events():
                cur.execute("SELECT indicator_id FROM indicators WHERE value=%s LIMIT 1",(ev["ioc"],))
                row=cur.fetchone()
                if not row: continue
                cur.execute("""
                  INSERT INTO sightings(indicator_id, seen_on, src_system, context)
                  VALUES (%s,%s,%s,%s)
                """,(row[0], dt.date.today(), ev["src"], ev["context"]))
        conn.commit()
    print("Sightings ingest complete")
if __name__=="__main__": main()
