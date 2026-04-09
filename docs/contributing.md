# Contributing

Thank you for your interest in contributing to Open-CTIC. This document
covers the development workflow, coding standards, and PR expectations.

---

## Getting Started

1. Fork the repository on GitHub.
2. Clone your fork and create a feature branch:

   ```bash
   git clone https://github.com/<your-user>/mastermind-ctic-db.git
   cd mastermind-ctic-db
   git checkout -b feat/my-feature
   ```

3. Set up the development environment:

   ```bash
   cp infra/.env.example infra/.env
   # Edit .env with development credentials
   cd infra && docker compose up -d
   ```

---

## Code Style

### Python

- Target Python 3.12+.
- Follow PEP 8. Use `ruff` for linting:
  ```bash
  pip install ruff
  ruff check etl/
  ```
- Add type hints to all function signatures.
- Write docstrings in Google style.
- Use `logging` instead of `print` statements.

### SQL

- Use uppercase for SQL keywords (`SELECT`, `CREATE TABLE`, `INSERT`).
- Use lowercase for identifiers (table and column names).
- Add comments explaining non-obvious logic.
- Use `IF NOT EXISTS` / `IF EXISTS` for idempotent DDL.

### YAML / Docker

- 2-space indentation for YAML files.
- Pin image versions (never use `latest` in production configs).

---

## Commit Messages

Use [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <description>

[optional body]
```

Types: `feat`, `fix`, `docs`, `chore`, `refactor`, `test`, `ci`.

Examples:
- `feat(etl): add Zeek log ingestion pipeline`
- `fix(schema): correct foreign key on event_indicator`
- `docs: update setup guide for Docker 25`

---

## Pull Request Process

1. Ensure your branch is up to date with `main`.
2. Run linting and verify the Docker build:
   ```bash
   ruff check etl/
   cd infra && docker compose build
   ```
3. Open a PR against `main` with:
   - A clear title following conventional commit format.
   - A summary section explaining what changed and why.
   - A test plan describing how to verify the changes.
4. All CI checks must pass before merge.
5. At least one maintainer review is required.

---

## Adding a New ETL Feed

1. Create a new module in `etl/` (e.g. `etl/zeek_logs.py`).
2. Follow the existing pattern: fetch, normalise, upsert, audit.
3. Add configuration variables to `etl/config.py`.
4. Add a new service entry to `infra/docker-compose.yml`.
5. Document the integration in `docs/usage.md`.
6. Add the feed to the CI workflow if applicable.

---

## Adding Schema Changes

1. Create a new numbered migration file: `schema/003_<description>.sql`.
2. Use idempotent DDL (`CREATE IF NOT EXISTS`, `ALTER ... ADD COLUMN IF NOT EXISTS`).
3. Wrap changes in a transaction (`BEGIN; ... COMMIT;`).
4. Update `docs/architecture.md` with new table/view descriptions.

---

## Reporting Issues

Open an issue on GitHub with:
- A clear title and description.
- Steps to reproduce (if applicable).
- Expected vs. actual behaviour.
- Environment details (OS, Docker version).

---

## Code of Conduct

This project follows the [Contributor Covenant Code of Conduct](../CODE_OF_CONDUCT.md).
All participants are expected to uphold this standard.
