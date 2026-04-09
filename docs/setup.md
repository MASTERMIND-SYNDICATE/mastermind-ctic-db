# Setup Guide

This guide covers prerequisites, configuration, deployment, and verification
of the Open-CTIC stack.

---

## Prerequisites

| Requirement              | Minimum version |
|--------------------------|-----------------|
| Docker Engine            | 24.0+           |
| Docker Compose           | v2.20+          |
| Git                      | 2.30+           |
| `psql` (optional)        | 14+             |

---

## 1. Clone the Repository

```bash
git clone https://github.com/MASTERMIND-SYNDICATE/mastermind-ctic-db.git
cd mastermind-ctic-db
```

---

## 2. Configure Environment

```bash
cp infra/.env.example infra/.env
```

Open `infra/.env` in your editor and set at minimum:

- `PGPASSWORD` -- a strong password for the PostgreSQL database.
- `GF_ADMIN_PASSWORD` -- the Grafana admin password.
- `PGADMIN_PASSWORD` -- the pgAdmin admin password.

For MISP integration, also set `MISP_URL` and `MISP_KEY`.

### Full Configuration Reference

| Variable              | Default          | Description                                       |
|-----------------------|------------------|---------------------------------------------------|
| `PGUSER`              | `ctic`           | PostgreSQL username                               |
| `PGPASSWORD`          | *(required)*     | PostgreSQL password                               |
| `PGDATABASE`          | `cticdb`         | PostgreSQL database name                          |
| `PG_HOST_PORT`        | `55432`          | Host port for PostgreSQL                          |
| `GF_ADMIN_USER`       | `admin`          | Grafana admin username                            |
| `GF_ADMIN_PASSWORD`   | `changeme`       | Grafana admin password                            |
| `GRAFANA_PORT`        | `3000`           | Host port for Grafana                             |
| `PGADMIN_EMAIL`       | `admin@localhost`| pgAdmin login email                               |
| `PGADMIN_PASSWORD`    | `changeme`       | pgAdmin login password                            |
| `PGADMIN_PORT`        | `8080`           | Host port for pgAdmin                             |
| `MISP_URL`            | *(empty)*        | MISP instance URL                                 |
| `MISP_KEY`            | *(empty)*        | MISP API key                                      |
| `MISP_VERIFY_SSL`     | `false`          | Verify MISP TLS certificate                       |
| `MISP_TAGS`           | *(empty)*        | Comma-separated tag filter                        |
| `MISP_SINCE_DAYS`     | `7`              | Look-back window for MISP queries                 |
| `MISP_LIMIT`          | `100`            | Max attributes per MISP pull                      |
| `WAZUH_URL`           | *(empty)*        | Wazuh API endpoint                                |
| `WAZUH_USER`          | *(empty)*        | Wazuh API username                                |
| `WAZUH_PASS`          | *(empty)*        | Wazuh API password                                |
| `WAZUH_INSECURE`      | `false`          | Skip TLS verification for Wazuh (dev only)        |
| `WAZUH_QUERY_MINUTES` | `60`             | Look-back window for Wazuh events                 |
| `WAZUH_LIMIT`         | `500`            | Max events per Wazuh fetch                        |
| `WAZUH_SRC`           | `wazuh`          | Source system label for sightings                 |
| `ETL_INTERVAL_SEC`    | `300`            | MISP pull loop interval in seconds                |

---

## 3. Start the Stack

```bash
cd infra
docker compose up -d
```

This will:
1. Start PostgreSQL and run the schema migration (`001_init.sql`) and
   seed data loader (`002_seed.sql`) on first boot.
2. Start Grafana with pre-provisioned dashboards and the PostgreSQL datasource.
3. Start pgAdmin for database administration.
4. Start the MISP ETL loop and Wazuh sightings container.

---

## 4. Verify Deployment

### Check service health

```bash
docker compose ps
```

All services should show `healthy` or `running` status.

### Query the database

```bash
docker compose exec postgres psql -U ctic -d cticdb -c "SELECT * FROM vw_kpis;"
```

Expected output (with seed data):

```
 incidents_total | indicators_total | campaigns_total | sightings_30d
-----------------+------------------+-----------------+---------------
               4 |                4 |               2 |             0
```

### Access web interfaces

- **Grafana:** http://localhost:3000
- **pgAdmin:** http://localhost:8080

---

## 5. Seed Data Reset

To reset the database to a clean state with seed data:

```bash
docker compose down -v   # removes volumes
docker compose up -d     # recreates from scratch
```

---

## Troubleshooting

### Containers fail to start

```bash
docker compose logs postgres   # check for schema errors
docker compose logs etl        # check ETL connectivity
```

### Port conflicts

If ports 55432, 3000, or 8080 are in use, change them in `.env`:

```ini
PG_HOST_PORT=55433
GRAFANA_PORT=3001
PGADMIN_PORT=8081
```

### ETL shows "MISP_URL or MISP_KEY not configured"

This is expected if you have not configured a MISP instance. The ETL
container will log the warning and retry on the next interval. Set
`MISP_URL` and `MISP_KEY` in `.env` to enable live ingestion.

### Grafana shows "no data"

1. Verify the datasource is connected: Grafana > Connections > Data sources.
2. Check that seed data loaded: run `SELECT COUNT(*) FROM incidents;`.
3. Adjust the dashboard time range to include the seed data dates.
