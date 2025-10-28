# CTIC Security Notes

***

## 🧱 Container Hardening

- Use hardened base images (**Chainguard**, **Bitnami**) wherever possible.  
- Run all services as **non-root users** for defense-in-depth.  
- Mount schema and SQL view directories as **read-only**.  
- Drop all unnecessary Linux capabilities:  
  ```yaml
  cap_drop: ["ALL"]
  ```  
- Use `no-new-privileges: true` in all containers.  
- Mount **tmpfs** for ephemeral or writeable directories to prevent sensitive data persistence.  

***

## 🔐 Secrets & Credentials

- Store all secrets using **Docker secrets** in production.  
- Never commit credentials or API keys in `.env` or code repositories.  
- Rotate credentials and API keys regularly.  
- Replace all **demo credentials** (MISP, Wazuh, Postgres) before any production deployment.  

***

## 🌐 Networking & Access Controls

- Bind admin GUIs (**Grafana**, **PgAdmin**) to `127.0.0.1` by default (not public).  
- Use **Docker internal networks** for all inter-container communication.  
- Planned improvements:  
  - Add **TLS** for Postgres and Grafana.  
  - Implement **Role-Based Access Control (RBAC)** in Grafana.  
  - Introduce **audit logging** for sensitive data and compliance tracking.  

***

## 🛡️ Vulnerability Management

- Run **container image scans** (e.g., Trivy) in CI/CD.  
- Configure CI/CD pipelines to **fail builds** on critical vulnerabilities.  
- Keep dependencies current: `pip`, `apt`, and base Docker images.  

***

## ⚖️ Compliance Best Practices

- Built-in SQL views for **GDPR/HIPAA** disclosure lag, **ALE**, and incidents missing source data.  
- **Auditable ETL runs** stored in database with timestamps and context.  
- All compliance logic and dashboards derived from standardized schema views.  

***

## 🚀 Next Steps & Future Hardening

- Add **TLS** for all sensitive endpoints.  
- Enable **multi-user** support and **RBAC** for Grafana and Postgres.  
- Prepare **Kubernetes manifests** for production-grade cloud deployment.  
- Integrate **GitHub Actions** for vulnerability and compliance scanning in CI/CD.  

***

See [Setup Guide](setup.md) for secrets/environment configuration and [Roadmap](roadmap.md) for upcoming security milestones.  
