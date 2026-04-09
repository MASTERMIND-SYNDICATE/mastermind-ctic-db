# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [2.0.0] - 2026-04-09

### Changed

- **Schema:** Consolidated 7 fragmented migration files into a single
  `001_init.sql` with thorough documentation for every table, column,
  constraint, function, and view.
- **ETL:** Rewrote `misp_pull.py` and `wazuh_sightings.py` to professional
  Python standards with type hints, structured logging, docstrings, and a
  centralised configuration module (`config.py`).
- **Docker:** Upgraded to PostgreSQL 16 Alpine. Replaced the previous
  Dockerfile with a multi-stage `Dockerfile.etl` running as non-root.
  Added a custom bridge network and externalised all credentials.
- **Documentation:** Complete rewrite of README, architecture, setup, usage,
  security, and contributing guides to professional technical writing standards.
- **Queries:** Reorganised demo queries into categorised files (compliance,
  risk, threat landscape) with thorough comments.

### Added

- `002_seed.sql` for automated CSV seed data loading via COPY.
- `etl/config.py` for centralised environment configuration.
- `etl/db.py` for shared database connection and table helpers.
- `etl/__init__.py` for proper Python package structure.
- `Makefile` with common development and operations shortcuts.
- `.github/workflows/ci.yml` GitHub Actions CI pipeline.
- `.editorconfig` for consistent editor formatting.
- `CODE_OF_CONDUCT.md` (Contributor Covenant).
- `docs/contributing.md` with code style, PR process, and testing guidance.
- `seed/README.md` documenting the seed dataset.
- `CHANGELOG.md` (this file).

### Removed

- Fragmented migration files (`003_alter_indicators.sql` through
  `006_event_indicator.sql`).
- `.bak` files, `.gitkeep` placeholders, orphaned scan outputs.
- `end_on` marker file, `docs/backups/`, `docs/reports/`, `docs/scans/`.
- `docs/demo_query_outputs.txt`, `docs/psql_tables.txt`,
  `docs/incidents-sample.txt`.
- Duplicate Dockerfiles and requirements files.
- `docs/roadmap.md` (replaced by this changelog and GitHub issues).

## [1.0.0] - 2025-09-17

### Added

- Initial release with PostgreSQL schema, MISP/Wazuh ETL pipelines,
  Grafana dashboards, pgAdmin, Docker Compose orchestration, and seed data.
