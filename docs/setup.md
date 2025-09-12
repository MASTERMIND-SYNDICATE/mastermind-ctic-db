# CTIC Setup Guide

## Prerequisites
- Docker + Docker Compose
- Git

## Quickstart
```bash
git clone https://github.com/MASTERMIND-SYNDICATE/mastermind-ctic-db.git
cd mastermind-ctic-db/infra
docker compose up -d
```

## Verify
```bash
export PGPASSWORD=cticpw
psql -h 127.0.0.1 -p 55432 -U ctic -d cticdb -c "SELECT * FROM vw_kpis;"
```
