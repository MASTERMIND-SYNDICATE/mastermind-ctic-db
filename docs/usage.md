# CTIC Usage Guide

***

## Grafana Dashboards

Visit → [http://127.0.0.1:3000](http://127.0.0.1:3000)  

**Default login:** `admin / admin` *(change after first login)*  

**Main Dashboard:** `CTIC KPI`  

**Panels include:**  
- Total incidents, indicators, campaigns, and sightings (last 30 days).  
- Recent sightings/events by source system (Wazuh, Zeek, etc.).  
- ALE (Annualized Loss Expectancy) by sector.  
- Disclosure/reporting lag for compliance (GDPR, HIPAA).  
- Top TTPs (MITRE techniques) in last 12 months.  

***

## ETL Operations

**Manual Run:**  
```bash
docker compose up etl
```  

Logs will display inserted indicators and sightings from demo or live sources.  

***

## Example SQL Queries

```sql
-- Over-72h disclosures (GDPR/HIPAA)
SELECT i.incident_id, o.name, r.name AS regime, ir.notify_date, i.discovered_on,
       (ir.notify_date - i.discovered_on) AS days_to_notify
FROM incidents i
JOIN organizations o USING (org_id)
JOIN incident_regimes ir USING (incident_id)
JOIN regimes r USING (regime_id)
WHERE ir.notified_flag = TRUE
  AND (ir.notify_date - i.discovered_on) > 3
ORDER BY days_to_notify DESC;
```  

More examples available in `/queries/demo_pg.sql`.  

***

## Data Operations

- Query via **psql**, **PgAdmin**, or **Grafana Explore**.  
- Demo data available in `/seed/` (CSV format).  
- Reset ETL pipeline by reloading CSVs or restoring from `/seed/` backup.  

***

## Common Tasks

- Import indicators from CSV or API using ETL scripts.  
- View or export dashboard KPIs for compliance reporting.  
- Download event or sighting exports (e.g., `ocsf_indicators.jsonl`) for sharing or analysis.  

***

## FAQ & Troubleshooting

- **No data or dashboards empty:** Ensure ETL containers are active (`docker compose ps`).  
- **Login issues:** Reset Grafana/PgAdmin passwords in `.env` and restart containers.  
- **Slow queries:** Check Postgres resource usage and tune indexes for larger datasets.  

***

**Ready for production, demo, and reporting.**  
See [Setup Guide](setup.md) or [Architecture](architecture.md) for full deployment and pipeline details.  

***
