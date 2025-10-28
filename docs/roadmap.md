# CTIC Roadmap

***

## ✅ Completed

- Database schema, normalization, and audit/reporting views.  
- Seed/demo data loading for instant KPIs and dashboard testing.  
- ETL containers: MISP indicator ingestion, Wazuh sightings pipeline (production + mock feeds).  
- Grafana dashboards fully wired to DB KPIs, sector risk, and regulatory/compliance metrics.  
- Setup, architecture, usage, and security documentation prepared for public release.  

***

## 🔄 In Progress

- Synthetic sightings for dashboard validation and demo environments.  
- Full documentation polish and content synchronization across modules.  

***

## ⏭️ Next

- Integrate **live MISP feed** for production indicator ingestion.  
- Add **Wazuh live alert** support to sightings pipeline.  
- Harden all container images (e.g., switch to **Chainguard** or **Bitnami** bases).  
- Implement **automated integration tests** (psql + ETL health checks).  
- Expand Grafana dashboards with **time-series**, **threat trends**, and **campaign topology maps**.  

***

## 🚀 Future

- Implement **TLS** for database and dashboards (encryption in transit and at rest).  
- Enable **multi-user Grafana** with full **Role-Based Access Control (RBAC)**.  
- Develop **Kubernetes deployment manifests** for cloud and hybrid environments.  
- Build **CI/CD automation** with vulnerability and compliance checks (GitHub Actions).  
- Add **formalized audit logging** and a regulatory evidence trail.  
- Extend ETL with **OpenCTI**, **Zeek**, and **Suricata** data sources.  

***

## 💬 How to Present the Roadmap

> “We’ve delivered a robust CTI pipeline ready for production and research, with a clear path to multi-source ingestion, compliance, cloud scaling, and automated security—each step documented and demo-ready for collaborators and stakeholders.”

***

Documentation complete and aligned for SRCC presentation and open release.
