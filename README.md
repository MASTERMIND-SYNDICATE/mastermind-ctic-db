MasterMind Syndicate Cyber Threat Intelligence Database (CTIC-DB)

Open-source prototype for MasterMind Syndicate LLC: a combined breach incident + cyber threat intelligence database.
Built in PostgreSQL, seeded with sample data, and designed for integration with open-source SOC tools such as MISP, TheHive, Cortex, Wazuh, Zeek, Suricata, OpenCTI, Greenbone, Shuffle, and others.

✨ Features

Unified schema for breach/incident records and live threat intelligence.

Normalized tables for organizations, incidents, impacts, vectors, regimes, sources, indicators, TTPs, campaigns, sightings.

Seed CSVs for quick demo and testing.

Five prebuilt demo queries covering compliance checks, ALE, and TTP analytics.

Entity-Relationship Diagram (ERD) for quick visualization.

Integration stubs for common open-source tools (MISP, Wazuh, TheHive, etc.).

Licensed under MIT for unrestricted reuse.

📂 Repository structure
schema/                # PostgreSQL DDL
seed/                  # CSVs with starter data
queries/               # Example SQL queries
etl/                   # Python scripts for ETL/automation
erd/                   # ERD diagrams
docs/                  # Word deliverables + screenshots
README.md
LICENSE
CITATION.cff

🏗️ Schema overview

Core entities:

organizations – companies, universities, agencies.

incidents – individual breach/incident records.

impacts – financial or downtime losses.

vectors – attack vectors (phishing, ransomware, SQLi).

regimes – compliance frameworks (HIPAA, GDPR).

sources – provenance of incident data.

indicators – IoCs (IPs, domains, hashes, emails).

ttps – MITRE ATT&CK techniques.

campaigns – attacker campaigns linking indicators.

sightings – observed indicator hits.

Bridges connect incidents to vectors, regimes, sources, indicators, and TTPs.

🚀 Setup
Requirements

PostgreSQL 14+

psql or pgAdmin/DBeaver

Docker (optional, for SOC integrations)

Steps
# Clone the repo
git clone https://github.com/MASTERMIND-SYNDICATE/mastermind-ctic-db.git
cd mastermind-ctic-db

# Create database
createdb cticdb

# Load schema
psql -d cticdb -f schema/pgsql_schema.sql

# Load seed data (example for organizations)
psql -d cticdb -c "\copy organizations FROM 'seed/organizations.csv' CSV HEADER"
# Repeat for other tables

🌱 Seed data

Located in seed/ folder.
Includes:

15 organizations across healthcare, education, finance, and public sector.

50+ incidents with vectors, impacts, regimes, and sources.

100+ indicators linked to TTPs and campaigns.

These are synthetic/public records suitable for class demos and portfolio work.

📊 Demo queries

Prebuilt queries are in queries/demo.sql. Examples:

Overdue GDPR/HIPAA notifications (>72h)

Annual Loss Expectancy (ALE) by sector

Top MITRE ATT&CK techniques last 12 months

Campaign reuse of ≥5 indicators

Data quality check: incidents missing sources

Run in psql:

\i queries/demo.sql

🔌 Integrations (roadmap)

MISP → export IoCs to indicators.

Wazuh → forward detections to sightings.

TheHive + Cortex → enrich IoCs with VirusTotal / Filescan.io.

OpenCTI → sync TTPs and campaigns.

Zeek/Suricata → feed network observables.

Greenbone → push CVE findings as vulnerabilities.

Shuffle → automate ETL workflows.

📅 Roadmap

 Build normalized Postgres schema

 Add seed CSVs and demo queries

 Generate ERD diagram

 Write ETL scripts (MISP, Wazuh, Cortex)

 Add Grafana dashboards (ALE, compliance, top TTPs)

 Publish Zenodo DOI and link to ORCID

📖 Documentation

docs/Proposal.docx – business use case + project scope.

docs/Updated_Proposal.docx – refined schema + milestones.

docs/Prototype_Report.docx – prototype build, ERD, queries, screenshots.

📜 License

MIT License. See LICENSE
.

🔗 Citation

If you use this project, please cite:

Gallant, R.J. (2025). MasterMind Syndicate Cyber Threat Intelligence Database (CTIC-DB). GitHub. https://github.com/MASTERMIND-SYNDICATE/mastermind-ctic-db


ORCID: https://orcid.org/0009-0006-2540-1304
