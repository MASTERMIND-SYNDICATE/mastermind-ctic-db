import os, sys, requests, psycopg
PGHOST=os.getenv("PGHOST","127.0.0.1")
PGPORT=int(os.getenv("PGPORT","55432"))
PGDB=os.getenv("PGDATABASE","cticdb")
PGUSER=os.getenv("PGUSER","ctic")
PGPASS=os.getenv("PGPASSWORD","cticpw")
MISP_URL=os.getenv("MISP_URL","").rstrip("/")
MISP_KEY=os.getenv("MISP_KEY","")

def upsert_indicator(cur, value, itype, source="MISP"):
    cur.execute("""
      INSERT INTO indicators(value,type,source) VALUES(%s,%s,%s)
      ON CONFLICT (value) DO UPDATE SET type=EXCLUDED.type, source=EXCLUDED.source
    """,(value, itype, source))

def pull_misp():
    if not (MISP_URL and MISP_KEY):
        print("MISP not configured; inserting demo IOC")
        return [{"value":"198.51.100.13","type":"ip"},{"value":"malicious.example","type":"domain"}]
    try:
        r=requests.post(f"{MISP_URL}/events/restSearch",
                        headers={"Authorization":MISP_KEY,"Accept":"application/json"},
                        json={"last":"24h","returnFormat":"json"}, timeout=15)
        r.raise_for_status()
        out=[]
        for ev in r.json().get("response",[]):
            for a in ev.get("Attribute",[]):
                t=a.get("type"); v=a.get("value")
                if not v or not t: continue
                if   t in ("ip","ip-src","ip-dst"): k="ip"
                elif t in ("domain","hostname","domain|ip"): k="domain"
                elif t in ("url",): k="url"
                elif t in ("sha256","sha1","md5"): k="hash"
                elif t in ("email-src","email-dst"): k="email"
                else: continue
                out.append({"value":v,"type":k})
        return out
    except Exception as e:
        print("MISP pull error:", e); return []

def main():
    iocs=pull_misp()
    if not iocs: 
        print("No IoCs"); return
    with psycopg.connect(host=PGHOST, port=PGPORT, user=PGUSER, password=PGPASS, dbname=PGDB) as conn:
        with conn.cursor() as cur:
            for i in iocs: upsert_indicator(cur, i["value"], i["type"])
        conn.commit()
    print(f"Upserted {len(iocs)} indicators")
if __name__=="__main__": main()
