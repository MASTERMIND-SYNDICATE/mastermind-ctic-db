# Open-CTIC

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Docker Compose](https://img.shields.io/badge/Docker-Compose-2496ED.svg)](infra/docker-compose.yml)
[![Python 3.12](https://img.shields.io/badge/Python-3.12-3776AB.svg)](etl/)
[![PostgreSQL 16](https://img.shields.io/badge/PostgreSQL-16-336791.svg)](schema/)

An open-source **Cyber Threat Intelligence Center** built with Docker. Open-CTIC
collects, normalises, and analyses cyber incidents, indicators of compromise (IOCs),
and sightings for SMBs, universities, and security researchers -- aligned with
**MITRE ATT&CK** and **OCSF** frameworks.

Developed and maintained by [Mastermind Syndicate LLC](https://github.com/MASTERMIND-SYNDICATE).

---

## Architecture

```
                          +----------------+
                          |   MISP Server  |
                          +-------+--------+
                                  |
                                  v
+----------------+       +--------+--------+       +-----------------+
| Wazuh Manager  | ----> |  ETL Pipeline   | ----> |   PostgreSQL    |
+----------------+       |  (Python 3.12)  |       |   (port 55432)  |
                          +--------+--------+       +--------+--------+
                                                             |
                          +----------------------------------+--------+
                          |                                           |
                   +------+------+                          +---------+-------+
                   |   Grafana   |                          |    pgAdmin      |
                   | (port 3000) |                          |   (port 8080)   |
                   +-------------+                          +-----------------+
```

**Data flow:** External threat feeds (MISP, Wazuh) are ingested by the Python ETL
pipeline, normalised to OCSF, and stored in PostgreSQL. Grafana dashboards visualise
KPIs, sector risk, TTP trends, and compliance metrics in real time.

---

## Features

- **Relational threat intel schema** -- incidents, IOCs, TTPs, campaigns, sightings,
  impacts, and compliance regimes with full referential integrity.
- **Automated ETL** -- MISP indicator pull and Wazuh sighting matching with OCSF-compliant
  event payloads and deduplication.
- **Pre-built dashboards** -- Grafana panels for KPIs, IOC distribution, sighting trends,
  sector ALE, and disclosure lag compliance.
- **Seed data** -- ready-to-query demo dataset for evaluation and development.
- **One-command deployment** -- Docker Compose brings up the entire stack.

---

## Quickstart

```bash
# Clone the repository
git clone https://github.com/MASTERMIND-SYNDICATE/mastermind-ctic-db.git
cd mastermind-ctic-db

# Configure environment
cp infra/.env.example infra/.env
# Edit infra/.env — at minimum, set PGPASSWORD

# Start the stack
cd infra
docker compose up -d

# Verify the database
docker compose exec postgres psql -U ctic -d cticdb -c "SELECT * FROM vw_kpis;"
```

| Service  | URL                          | Default credentials         |
|----------|------------------------------|-----------------------------|
| Grafana  | http://localhost:3000        | admin / (set in .env)       |
| pgAdmin  | http://localhost:8080        | admin@localhost / (set in .env) |
| Postgres | localhost:55432              | ctic / (set in .env)        |

---

## Project Structure

```
mastermind-ctic-db/
├── schema/                 # SQL schema and seed loader
│   ├── 001_init.sql        # Complete DDL: tables, indexes, views, functions
│   └── 002_seed.sql        # COPY-based seed data loader
├── etl/                    # Python ETL pipeline
│   ├── config.py           # Centralised environment configuration
│   ├── db.py               # Shared database helpers
│   ├── misp_pull.py        # MISP indicator ingestion
│   └── wazuh_sightings.py  # Wazuh sighting matching
├── infra/                  # Docker Compose and container configs
│   ├── docker-compose.yml  # Service orchestration
│   ├── Dockerfile.etl      # Multi-stage ETL container image
│   ├── .env.example        # Environment variable template
│   └── grafana/            # Dashboard and datasource provisioning
├── seed/                   # Demo CSV data files
├── queries/                # Example SQL queries
├── docs/                   # Technical documentation
├── Makefile                # Common task shortcuts
└── .github/workflows/      # CI pipeline
```

---

## Configuration

All configuration is driven by environment variables. Copy `infra/.env.example`
to `infra/.env` and set values appropriate for your environment. See
[docs/setup.md](docs/setup.md) for the full configuration reference.

| Variable           | Required | Description                              |
|--------------------|----------|------------------------------------------|
| `PGPASSWORD`       | Yes      | PostgreSQL password                      |
| `MISP_URL`         | No       | MISP server URL                          |
| `MISP_KEY`         | No       | MISP API authentication key              |
| `WAZUH_URL`        | No       | Wazuh manager API endpoint               |
| `ETL_INTERVAL_SEC` | No       | MISP pull interval (default: 300s)       |

---

## Documentation

- [Setup Guide](docs/setup.md) -- prerequisites, configuration, deployment
- [Architecture](docs/architecture.md) -- system design, data flow, schema
- [Usage Guide](docs/usage.md) -- dashboards, ETL operations, SQL examples
- [Security](docs/security.md) -- hardening, secrets management, compliance
- [Contributing](docs/contributing.md) -- code style, PR process, testing

---

## Contributing

Contributions are welcome. Please read [docs/contributing.md](docs/contributing.md)
before submitting a pull request.

---

## License

This project is licensed under the [MIT License](LICENSE).

---

## Maintainer

**Raymond James** -- [raymondjames@mastermindsyndicate.tech](mailto:raymondjames@mastermindsyndicate.tech)

## Acknowledgements

- [MITRE ATT&CK](https://attack.mitre.org/)
- [MISP Project](https://www.misp-project.org/)
- [OCSF](https://ocsf.io/)
- [PostgreSQL](https://www.postgresql.org/)
- [Grafana](https://grafana.com/)
