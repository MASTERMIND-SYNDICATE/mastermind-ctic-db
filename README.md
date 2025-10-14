# OPEN-CTIC  
**Developed & Maintained by [Mastermind Syndicate LLC](https://github.com/MASTERMIND-SYNDICATE)**  

An open-source **Cyber Threat Intelligence Center (CTIC)** stack built with Docker.  
Designed for SMBs, universities, and researchers to collect, store, and visualize cyber incident data aligned to **MITRE ATT&CK** and **OCSF** frameworks.

---

## 🚀 Features
- **Postgres** — Relational database with schema + reporting views for incidents, indicators, campaigns, TTPs, impacts, and compliance.  
- **ETL (Python)** — Ingest pipeline for indicators and sightings (demo + production feeds; MISP-ready).  
- **Grafana** — Dashboards for KPIs, TTP frequency, ALE by sector, and compliance/disclosure lags.  
- **PgAdmin** — Developer GUI for direct Postgres access.  
- **Docker Compose** — Reproducible end-to-end local deployment.  

---

## 📘 Documentation
- [Setup Guide](docs/README.md)  
- [Architecture Overview](docs/ARCHITECTURE.md)  
- [Usage Notes](docs/OPERATIONS.md)  
- [Security Notes](docs/SECURITY.md)  
- [Roadmap](docs/ROADMAP.md)  
- [Sample Queries](queries/)  
- [Data Model & Lineage](schema/)  

---

## ⚡ Quickstart
```
git clone https://github.com/MASTERMIND-SYNDICATE/open-ctic.git
cd open-ctic/infra
docker compose up -d
```

**Grafana:** [http://127.0.0.1:3000](http://127.0.0.1:3000)  
**PgAdmin:** [http://127.0.0.1:8080](http://127.0.0.1:8080)

**Default Database Credentials**
```
Host: 127.0.0.1
Port: 55432
Database: cticdb
User: ctic
Password: cticpw
```

---

## 🧠 Data & Analytics
- **Seed Data:** `/seed/` → incidents.csv, indicators.csv, impacts.csv, ttps.csv, campaigns.csv, etc.  
- **Analytics:** `/queries/` → demo_pg.sql for ALE, KPIs, and compliance lag analysis.  
- **Dashboards:** `/infra/grafana/` → pre-provisioned Grafana JSON configs.  

---

## 📄 License
MIT License — see [LICENSE](LICENSE).

---

## 👤 Maintainer
**Raymond James**  
📧 raymondjames@mastermindsyndicate.tech  

---

## 🏗️ Credits
- Mastermind Syndicate LLC  
- MITRE ATT&CK  
- MISP Project  
- OCSF  
- Grafana & PostgreSQL  
