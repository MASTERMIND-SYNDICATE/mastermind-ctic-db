# CTIC Architecture

***

## Overview

A modular cyber threat intelligence stack built for research, reporting, and operational use—integrating:  
- **ETL pipelines** (Python; MISP, Wazuh sources)  
- **Relational database** (Postgres)  
- **Dashboards** (Grafana)  
- **Admin GUI** (PgAdmin)  
- All orchestrated via **Docker Compose**  

***

## Components

- **Postgres:** Stores incidents, indicators, TTPs, campaigns, impacts, and sightings.  
- **ETL Container(s):** Ingests indicators and sightings (MISP, Wazuh, demo/mock data).  
- **Grafana:** Dashboards for KPIs, sector risk levels, top TTPs, compliance.  
- **PgAdmin:** Admin/maintainer GUI for Postgres.  
- **Docker Compose:** Automates, orchestrates, and secures all services.  

***

## Data Flow

```mermaid
graph TD
    etl[ETL Pipeline (Python)] --> pg[Postgres]
    pg --> grafana[Grafana Dashboards]
    misp[MISP API]
    wazuh[Wazuh API]
    misp --> etl
    wazuh --> etl
    seed[Seed Data]
    seed --> pg
```

**1. ETL pulls indicators and sightings from live feeds or demo sources.**  
**2. Inserts structured events into Postgres, applying normalization & deduplication.**  
**3. Grafana dashboards query KPIs, ALE, TTPs, and compliance metrics from DB views.**

***

## Diagram

- Main pipeline (see above or included ERD/flowchart image in `/erd/`).  
- Database schema diagrams are located in `/erd/` and `/schema/`.  

***

## Extensibility

- Add new ETL feeds (OpenCTI, Zeek, Sigma, etc.).  
- Expand DB schema or materialized views for compliance, analytics, or custom reporting.  
- Integrate with additional visualization tools beyond Grafana if needed.  

***

## Next Steps

- See [Setup Guide](setup.md) for deployment.  
- Explore Grafana dashboards ([usage.md](usage.md)).  
- Review hardening and security guidance ([security.md](security.md)).  

***


