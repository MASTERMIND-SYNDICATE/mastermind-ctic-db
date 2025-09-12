# Mastermind Syndicate CTIC

An open-source Cyber Threat Intelligence Center (CTIC) stack built with Docker.  
It provides a reference architecture for SMBs, universities, and researchers to collect, store, and visualize cyber incident data.  

## Features
- **Postgres**: Relational database with schema + reporting views
- **ETL**: Ingest pipeline for indicators and sightings (demo + real feeds)
- **Grafana**: Dashboards for KPIs, TTPs, ALE by sector, disclosure lags
- **PgAdmin**: Developer GUI for Postgres

## Documentation
- [Setup Guide](docs/setup.md)
- [Architecture](docs/architecture.md)
- [Usage](docs/usage.md)
- [Security Notes](docs/security.md)
- [Roadmap](docs/roadmap.md)

## Quickstart
```bash
git clone https://github.com/MASTERMIND-SYNDICATE/mastermind-ctic-db.git
cd mastermind-ctic-db/infra
docker compose up -d
```

- Grafana → [http://127.0.0.1:3000](http://127.0.0.1:3000)  
- PgAdmin → [http://127.0.0.1:8080](http://127.0.0.1:8080)  

Default database connection:
- Host: `127.0.0.1`
- Port: `55432`
- Database: `cticdb`
- User: `ctic`
- Password: `cticpw`

## License
MIT — see [LICENSE](LICENSE).
