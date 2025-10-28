# CTIC Setup Guide

***

## Prerequisites

- **Docker & Docker Compose**  
- **Git** (for cloning)  
- *Optional:* PostgreSQL client (`psql`) for direct DB queries  

***

## Quickstart

```bash
git clone https://github.com/MASTERMIND-SYNDICATE/open-ctic.git
cd open-ctic/infra
docker compose up -d
```

***

## Services Launched

- **Postgres:** Database (`cticdb`)  
- **Grafana:** Dashboards → [http://127.0.0.1:3000](http://127.0.0.1:3000)  
- **PgAdmin:** DB admin GUI → [http://127.0.0.1:8080](http://127.0.0.1:8080)  
- **ETL Containers:** Automated feeds (MISP + Wazuh sightings pipeline)  

***

## Configuration

- **Environment Variables:**  
  Copy `infra/.env.example` → `infra/.env` and fill in your secret keys for production.

- **Default DB Credentials:**  
  ```text
  Host: 127.0.0.1
  Port: 55432
  Database: cticdb
  User: ctic
  Password: cticpw
  ```  
  *(Change these in production.)*  

- **Data & Dashboards:**  
  Sample data lives in `/seed/`; Grafana dashboards are pre-provisioned in `/infra/grafana/dashboards/`.  

***

## Smoke Test & Verification

- **Check DB Health:**  
  ```bash
  export PGPASSWORD=cticpw
  psql -h 127.0.0.1 -p 55432 -U ctic -d cticdb -c "SELECT * FROM vw_kpis;"
  ```  

- **Access Grafana:**  
  Login → [http://127.0.0.1:3000](http://127.0.0.1:3000)  
  *(Default: admin / admin — change immediately.)*  

- **Access PgAdmin:**  
  Login → [http://127.0.0.1:8080](http://127.0.0.1:8080)  

***

## Troubleshooting

- **Common Issues:**  
  - *Containers not starting:* Run `docker compose ps`, check logs, ensure ports are free.  
  - *Grafana or PgAdmin inaccessible:* Confirm Docker network and mapped ports in `docker-compose.yml`.  
  - *ETL not running:* Check Python dependencies and Docker build logs.  

- **Rebuild Docker Images:**  
  ```bash
  docker compose build
  docker compose up -d --force-recreate
  ```  

***

## Next Steps

- Populate with real data feeds (MISP, Wazuh).  
- Review and harden secrets/environment for production deployment.  
- Explore dashboards in Grafana.  
- See [Architecture](docs/architecture.md) and [Security](docs/security.md) for deeper configuration.  

***
