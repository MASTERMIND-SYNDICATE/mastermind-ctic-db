# Security

This document describes the security model, hardening measures, and
operational security practices for the Open-CTIC platform.

---

## Threat Model

Open-CTIC processes sensitive threat intelligence data. The primary threats
to consider are:

1. **Credential exposure** -- database passwords, API keys, and admin
   credentials leaking through environment files or container logs.
2. **Unauthorised access** -- external actors reaching admin interfaces
   (Grafana, pgAdmin) or the database port.
3. **Container escape** -- a compromised container gaining access to the
   host or other containers.
4. **Data integrity** -- malicious or corrupted threat feed data poisoning
   the intelligence database.
5. **Supply chain** -- vulnerable base images or Python packages.

---

## Secrets Management

### Development

- Copy `infra/.env.example` to `infra/.env` and set strong, unique passwords.
- The `.env` file is excluded from version control via `.gitignore`.
- Never commit real credentials, API keys, or tokens.

### Production

- Use Docker secrets or a secrets manager (Vault, AWS Secrets Manager) instead
  of environment files.
- Rotate credentials regularly.
- Restrict `.env` file permissions: `chmod 600 infra/.env`.

---

## Container Hardening

### Non-Root Execution

The ETL container runs as a dedicated non-root user (`etl`, UID 65532).
PostgreSQL and Grafana containers use their upstream non-root defaults.

### Recommended docker-compose Overrides for Production

```yaml
services:
  postgres:
    security_opt:
      - no-new-privileges:true
    cap_drop:
      - ALL
    read_only: true
    tmpfs:
      - /tmp
      - /run/postgresql

  grafana:
    security_opt:
      - no-new-privileges:true
    cap_drop:
      - ALL
    read_only: true
    tmpfs:
      - /tmp
```

### Network Isolation

All services communicate over a private Docker bridge network (`ctic`).
Only explicitly published ports are accessible from the host.

For production, bind admin interfaces to localhost only:

```yaml
ports:
  - "127.0.0.1:3000:3000"
  - "127.0.0.1:8080:80"
```

---

## TLS

### Current State

The default deployment does not enable TLS between services. This is
acceptable for local development but not for production.

### Production Recommendations

- **Grafana:** Enable TLS via `GF_SERVER_PROTOCOL=https` and provide
  certificate and key files.
- **PostgreSQL:** Enable `ssl = on` in `postgresql.conf` with a signed
  certificate.
- **Reverse proxy:** Place Nginx or Traefik in front of all web services
  with automatic certificate management (Let's Encrypt).

---

## Access Control

- **Grafana:** Change the admin password on first login. Create
  organisation-scoped users with appropriate roles (Viewer, Editor, Admin).
- **pgAdmin:** Restrict access to trusted operators. Consider removing
  pgAdmin from production deployments entirely.
- **PostgreSQL:** The `ctic` user has full access to the `cticdb` database.
  For multi-tenant deployments, create read-only roles for analysts.

---

## Vulnerability Management

- Run container image scans (Trivy, Grype) as part of CI/CD.
- Pin base image versions to avoid unexpected changes.
- Monitor Python dependency advisories and update `requirements.txt`.
- Subscribe to security advisories for PostgreSQL, Grafana, and pgAdmin.

---

## Compliance

Open-CTIC includes built-in reporting views for compliance monitoring:

| View                       | Regulation | Purpose                              |
|----------------------------|------------|--------------------------------------|
| `vw_reporting_lag_72h`     | GDPR/HIPAA | Identify late breach notifications   |
| `vw_incidents_missing_sources` | Audit  | Flag incidents without evidence      |
| `etl_runs`                 | Audit      | Full ETL execution audit trail       |

### Audit Trail

Every ETL run is recorded in `public.etl_runs` with timestamps, row counts,
and error details. This provides an auditable record of all data ingestion
activity.

---

## Reporting Vulnerabilities

If you discover a security vulnerability in Open-CTIC, please report it
responsibly by emailing [raymondjames@mastermindsyndicate.tech](mailto:raymondjames@mastermindsyndicate.tech).
Do not open a public issue for security vulnerabilities.
