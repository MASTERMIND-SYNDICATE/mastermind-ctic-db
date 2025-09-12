# Usage Guide

## Dashboards
Open Grafana at [http://127.0.0.1:3000](http://127.0.0.1:3000)  
- Login: `admin` / `admin` **Note:** The default password has been changed by RJ   
- Open dashboard: **CTIC KPI**  
- Panels display incidents, indicators, campaigns, sightings, TTPs, ALE by sector, and disclosure lag.

## ETL
Run the ETL manually:
```bash
docker compose up etl
```
Logs will show inserted IOCs and sightings.

## SQL Queries
Query directly with `psql`. Example:
```sql
SELECT * FROM vw_reporting_lag_72h WHERE overdue;
```
