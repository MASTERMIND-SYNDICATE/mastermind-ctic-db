# =============================================================================
# Open-CTIC Makefile
# Common shortcuts for development and operations.
# =============================================================================

COMPOSE := docker compose -f infra/docker-compose.yml
PSQL    := $(COMPOSE) exec postgres psql -U ctic -d cticdb

.PHONY: help up down restart logs build \
        psql kpis seed reset \
        etl-run wazuh-run \
        lint fmt test

help: ## Show this help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  %-15s %s\n", $$1, $$2}'

# -- Docker -------------------------------------------------------------------

up: ## Start all services
	$(COMPOSE) up -d

down: ## Stop all services
	$(COMPOSE) down

restart: ## Restart all services
	$(COMPOSE) restart

logs: ## Tail logs for all services
	$(COMPOSE) logs -f

build: ## Rebuild container images
	$(COMPOSE) build --no-cache

# -- Database -----------------------------------------------------------------

psql: ## Open an interactive psql session
	$(PSQL)

kpis: ## Print KPI summary from the database
	$(PSQL) -c "SELECT * FROM vw_kpis;"

seed: ## Re-run seed data loader
	$(PSQL) -f /docker-entrypoint-initdb.d/002_seed.sql

reset: ## Destroy volumes and recreate from scratch
	$(COMPOSE) down -v
	$(COMPOSE) up -d

# -- ETL ----------------------------------------------------------------------

etl-run: ## Trigger a single MISP pull
	$(COMPOSE) exec etl python -u -m etl.misp_pull

wazuh-run: ## Trigger a single Wazuh sightings run
	$(COMPOSE) exec wazuh-sightings python -u -m etl.wazuh_sightings

# -- Quality ------------------------------------------------------------------

lint: ## Lint Python ETL code with ruff
	ruff check etl/

fmt: ## Check Python formatting with ruff
	ruff format --check etl/

test: ## Run unit tests with pytest
	pytest tests/ -v
