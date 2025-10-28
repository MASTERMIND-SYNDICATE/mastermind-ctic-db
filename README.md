# OPEN-CTIC  
**Developed & Maintained by [Mastermind Syndicate LLC](https://github.com/MASTERMIND-SYNDICATE)**  

An open-source **Cyber Threat Intelligence Center (CTIC)** stack built with Docker.  

**Purpose:**  
CTIC collects, standardizes, and analyzes cyber incidents, indicators, and sightings for SMBs, universities, and researchers—aligned with **MITRE ATT&CK** and **OCSF** frameworks, ready for operational use, reporting, and compliance.

***

## 🚩 Table of Contents
- [Project Summary](#project-summary)
- [Features](#-features)
- [Quickstart](#-quickstart)
- [Documentation](#-documentation)
- [Seed Data & Dashboards](#-data--analytics)
- [Security Notes](#-security)
- [License](#-license)
- [Maintainer](#-maintainer)
- [Credits](#-credits)

***

## 🚀 Features
- **Postgres** — Relational schema & reporting views (incidents, indicators, campaigns, TTPs, impacts, compliance).  
- **ETL (Python)** — Automated pipeline feeds for indicators & sightings; MISP/Wazuh-ready.  
- **Grafana** — Dashboards for KPIs, TTP trends, sector ALE, compliance/disclosure lags.  
- **PgAdmin** — Dev/admin GUI for direct Postgres access.  
- **Docker Compose** — One-command, reproducible deployment.  

***

## ⚡ Quickstart
```
git clone https://github.com/MASTERMIND-SYNDICATE/open-ctic.git
cd open-ctic/infra
docker compose up -d
```

**Grafana:** [http://127.0.0.1:3000](http://127.0.0.1:3000)  
**PgAdmin:** [http://127.0.0.1:8080](http://127.0.0.1:8080)

**Default Database Credentials**  
```text
Host: 127.0.0.1
Port: 55432
Database: cticdb
User: ctic
Password: cticpw
```

***

## 📘 Documentation
- [Setup Guide](docs/setup.md)  
- [Architecture Overview](docs/architecture.md)  
- [Usage Notes](docs/usage.md)  
- [Security Notes](docs/security.md)  
- [Roadmap](docs/roadmap.md)  
- [Sample Queries](queries/)  
- [Data Model & Lineage](schema/)  

***

## 🧠 Data & Analytics
- **Seed Data:** `/seed/` — incidents.csv, indicators.csv, impacts.csv, ttps.csv, campaigns.csv, etc.  
- **Analytics:** `/queries/` — demo_pg.sql for ALE, KPIs, compliance/reporting lag analysis.  
- **Dashboards:** `/infra/grafana/dashboards/` — pre-provisioned Grafana JSON configs.  
- **Screenshots & Diagrams:** Include `erd/` or dashboard images for documentation or presentation.  

***

## 🔐 Security
- **Environment & Secrets:** For production, set credentials using Docker secrets (see `infra/.env.example`). Do **not** commit real secrets in `.env` files.  
- **Hardening:** Containers run as non-root; admin UIs bind to localhost by default.  
- **Future:** TLS, RBAC, CI/CD, and additional hardening steps planned (see [Security Notes](docs/security.md)).  

***

## 📄 License
MIT License — see [LICENSE](LICENSE).  

***

## 👤 Maintainer
**Raymond James**  
📧 [raymondjames@mastermindsyndicate.tech](mailto:raymondjames@mastermindsyndicate.tech)  

***

## 🏗️ Credits
- Mastermind Syndicate LLC  
- MITRE ATT&CK  
- MISP Project  
- OCSF  
- Grafana & PostgreSQL  

***

**How to Present:**  
CTIC enables rapid deployment of a standardized threat intelligence stack for both research and production.  
All code, dashboards, and data are open-source—deployable on any modern container platform.
