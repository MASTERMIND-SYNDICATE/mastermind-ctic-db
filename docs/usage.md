# Usage Guide

This guide covers day-to-day usage of the Open-CTIC platform, including
dashboards, ETL operations, and SQL examples.

---

## Grafana Dashboards

Open Grafana at http://localhost:3000 (default credentials configured in `.env`).

### CTIC KPI Dashboard

The main dashboard provides an operational overview:

| Panel                       | Description                                    |
|-----------------------------|------------------------------------------------|
| IoCs by Type                | Pie chart of indicator type distribution        |
| Latest Indicators           | Table of the 20 most recent indicators          |
| Recent Sightings            | Sighting detail with indicator join              |
| Total Indicators            | Stat panel with total IOC count                 |
| Sightings (Time Range)      | Stat panel with sighting count in selected range|
| Campaigns Total             | Stat panel with campaign count                  |
| Indicators First Seen       | Time series of new indicators per day           |
| Sightings by Source System  | Time series grouped by `src_system`             |

### CTIC IoC / Event Dashboard

Focused on IOC-to-event matching:

| Panel                       | Description                                    |
|-----------------------------|------------------------------------------------|
| KPI: Indicators             | Total indicator count                          |
| KPI: Active Indicators      | Indicators seen in the last 30 days            |
| KPI: Events                 | Total security events                          |
| KPI: Matched Events         | Events linked to at least one indicator        |
| Matches per day             | Time series of daily match counts              |
| Top 20 IoCs by match count  | Bar chart of the most-matched indicators       |
| Recent IoC Matches          | Detailed match table                           |
| Sightings per day           | Time series grouped by source system           |

### Template Variables

Both dashboards support Grafana template variables:

- `$src_system` -- filter sightings by source system.
- `$type` -- filter indicators by type.

---

## ETL Operations

### Running the MISP Pull

The ETL container runs automatically on startup. To trigger a manual run:

```bash
docker compose exec etl python -u -m etl.misp_pull
```

### Running Wazuh Sightings

```bash
docker compose exec wazuh-sightings python -u -m etl.wazuh_sightings
```

### Monitoring ETL Runs

```sql
SELECT job, started_at, finished_at, status, inserted_count, error_count, notes
FROM etl_runs
ORDER BY started_at DESC
LIMIT 10;
```

### Adjusting the Pull Interval

Set `ETL_INTERVAL_SEC` in `.env` and restart the ETL container:

```bash
docker compose restart etl
```

---

## SQL Query Examples

### Compliance: Over-72-Hour Disclosures

Identify incidents that exceeded the GDPR/HIPAA 72-hour notification window:

```sql
SELECT
    incident_id,
    org_name,
    regime,
    discovered_on,
    notify_date,
    days_to_notify,
    overdue
FROM vw_reporting_lag_72h
WHERE overdue = TRUE
ORDER BY days_to_notify DESC;
```

### Risk: Annualised Loss Expectancy by Sector

```sql
SELECT sector, ale_usd
FROM vw_ale_by_sector_24m;
```

### Threat Landscape: Top MITRE ATT&CK Techniques

```sql
SELECT name, mitre_id, incident_count
FROM vw_top_ttps_12m
LIMIT 10;
```

### Data Quality: Incidents Missing Sources

```sql
SELECT incident_id, org_name
FROM vw_incidents_missing_sources;
```

### Campaign Analysis: Shared Indicators

Identify campaigns that reuse multiple indicators:

```sql
SELECT c.name, COUNT(*) AS shared_iocs
FROM indicator_campaign ic
JOIN campaigns c USING (campaign_id)
GROUP BY c.name
HAVING COUNT(*) >= 2
ORDER BY shared_iocs DESC;
```

### KPI Summary

```sql
SELECT * FROM vw_kpis;
```

---

## Data Operations

### Importing Custom Data

Load additional indicators from a CSV file:

```bash
docker compose exec -T postgres psql -U ctic -d cticdb -c "\
COPY indicators (value, type, source, first_seen, last_seen)
FROM STDIN WITH (FORMAT csv, HEADER true);" < my_indicators.csv
```

### Exporting Data

```bash
docker compose exec postgres psql -U ctic -d cticdb -c \
  "COPY (SELECT * FROM vw_kpis) TO STDOUT WITH CSV HEADER;" > kpis.csv
```

### Resetting the Database

```bash
docker compose down -v
docker compose up -d
```

This destroys all data and recreates the database from the schema and seed files.
