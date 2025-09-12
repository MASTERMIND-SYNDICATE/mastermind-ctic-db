# Security Notes

## Container Hardening
- Use hardened base images (Chainguard, Bitnami) where possible.
- Run services as non-root users.
- Mount schema and views read-only.
- Drop Linux capabilities (`cap_drop: ["ALL"]`).
- Set `no-new-privileges` security option.
- Use `tmpfs` for ephemeral directories.

## Secrets
- Store sensitive values (MISP_KEY, WAZUH_PASS) in Docker secrets, not plain environment variables.
- Rotate secrets regularly.
- Avoid committing secrets into Git.

## Networking
- Bind admin UIs (Grafana, PgAdmin) to `127.0.0.1` so they’re not exposed publicly.
- Use Docker internal networks for service-to-service communication.
- Future: add TLS for Postgres and Grafana.

## Next Steps
- Run Trivy scans on images.
- Add CI job to fail builds with high vulnerabilities.
- Configure Grafana role-based access control.
