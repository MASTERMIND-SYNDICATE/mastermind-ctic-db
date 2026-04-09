# Architecture

This document describes the system architecture, data model, and integration
points of the Open-CTIC platform.

---

## System Overview

Open-CTIC is a containerised stack that collects, normalises, and visualises
cyber threat intelligence data. Five Docker services collaborate over a
private bridge network:

| Service           | Role                                       | Image                   |
|-------------------|--------------------------------------------|-------------------------|
| **postgres**      | Primary datastore (schema, views, seed)    | postgres:16-alpine      |
| **etl**           | MISP indicator ingestion (looping)         | Dockerfile.etl          |
| **wazuh-sightings** | Wazuh sighting matching (single-run)    | Dockerfile.etl          |
| **grafana**       | Dashboard visualisation                    | grafana/grafana:10.4.2  |
| **pgadmin**       | Database administration GUI                | dpage/pgadmin4:8.6      |

---

## Data Flow

```
 ┌──────────────┐     ┌──────────────┐
 │  MISP Server │     │ Wazuh Manager│
 └──────┬───────┘     └──────┬───────┘
        │                    │
        v                    v
 ┌──────────────────────────────────────┐
 │         ETL Pipeline (Python)        │
 │  - Fetch attributes / events         │
 │  - Normalise types                   │
 │  - Build OCSF payloads              │
 │  - Deduplicate                       │
 └──────────────────┬───────────────────┘
                    │
                    v
 ┌──────────────────────────────────────┐
 │          PostgreSQL (cticdb)          │
 │                                      │
 │  Core: incidents, indicators,        │
 │        sightings, organizations      │
 │  Taxonomy: ttps, vectors, campaigns, │
 │           regimes, sources           │
 │  OCSF: dim_*, sec_event,            │
 │        event_indicator               │
 │  Views: vw_kpis, vw_ale_by_sector,  │
 │         vw_top_ttps, vw_reporting_lag│
 │  Audit: etl_runs                     │
 └──────────┬──────────┬────────────────┘
            │          │
            v          v
     ┌──────────┐ ┌──────────┐
     │ Grafana  │ │ pgAdmin  │
     └──────────┘ └──────────┘
```

1. **Ingestion** -- the ETL containers pull data from external threat feeds
   (MISP for indicators, Wazuh for security events).
2. **Normalisation** -- raw attributes are mapped to canonical types and
   wrapped in OCSF-compliant JSON payloads.
3. **Storage** -- normalised data is upserted into PostgreSQL with
   deduplication via unique constraints and match fingerprints.
4. **Visualisation** -- Grafana queries reporting views to render KPI panels,
   time-series charts, and compliance dashboards.

---

## Database Schema

### Core Tables

- **organizations** -- entities tracked by the CTI centre (sector, size, country).
- **incidents** -- security incidents linked to an organisation with severity and status.
- **indicators** -- IOCs with type classification (IP, domain, hash, URL, email) and OCSF payload.
- **sightings** -- observations of indicators in the wild with source system and dedup fingerprint.
- **impacts** -- financial and operational impact per incident (1:1).

### Taxonomy Tables

- **vectors** -- attack vectors (phishing, ransomware, SQL injection, etc.).
- **ttps** -- MITRE ATT&CK techniques with technique IDs.
- **campaigns** -- named threat campaigns with tags.
- **regimes** -- regulatory frameworks (GDPR, HIPAA).
- **sources** -- intelligence sources (reports, news, regulators).

### Junction Tables

Many-to-many relationships are modelled with junction tables:
`incident_indicators`, `incident_vectors`, `incident_ttps`,
`incident_regimes`, `incident_sources`, `indicator_campaign`,
`campaign_indicator`.

### OCSF Layer

Dimension tables (`dim_user`, `dim_host`, `dim_ip`, `dim_file`, `dim_url`)
and the `sec_event` fact table provide an OCSF-aligned security event model.
The `event_indicator` table links security events to matched indicators.

### Reporting Views

| View                        | Purpose                                          |
|-----------------------------|--------------------------------------------------|
| `vw_kpis`                   | High-level counts (incidents, indicators, etc.)  |
| `vw_ale_by_sector_24m`      | Annualised Loss Expectancy by sector             |
| `vw_top_ttps_12m`           | Most common MITRE techniques (12-month window)   |
| `vw_reporting_lag_72h`      | Disclosure compliance (GDPR/HIPAA 72-hour rule)  |
| `vw_incidents_missing_sources` | Data quality: incidents without linked sources |
| `misp_attribute`            | MISP-compatible attribute view                   |

---

## ETL Pipeline

### MISP Pull (`etl/misp_pull.py`)

- Calls MISP REST API `/attributes/restSearch.json`.
- Maps attribute types to canonical indicator types via `TYPE_MAP`.
- Upserts into `public.indicators` using `ON CONFLICT (value) DO UPDATE`.
- Maintains `first_seen` / `last_seen` window with `LEAST` / `GREATEST`.
- Stores OCSF indicator event (class_id=1003) as JSONB.

### Wazuh Sightings (`etl/wazuh_sightings.py`)

- Fetches events from the Wazuh security events API.
- Falls back to mock data (`etl/mock/wz.json`) if Wazuh is not configured.
- Matches event text against all known indicator values.
- Inserts sightings with OCSF detection finding payload (class_id=1002).
- Deduplicates via `ON CONFLICT DO NOTHING`.

### Audit Trail

Every ETL run is recorded in `public.etl_runs` with start/finish timestamps,
insert/update/error counts, and a status flag.

---

## Extensibility

- **New feeds** -- add a new ETL module in `etl/` following the same pattern
  (fetch, normalise, upsert, audit).
- **New dashboards** -- drop Grafana JSON files into `infra/grafana/dashboards/`.
- **Schema extensions** -- add numbered migration files in `schema/` (e.g. `003_*.sql`).
- **Additional integrations** -- OpenCTI, Zeek, Suricata, Sigma rules.
