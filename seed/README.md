# Seed Data

This directory contains CSV files used to populate the Open-CTIC database
with a representative demo dataset. The data is loaded automatically by
`schema/002_seed.sql` when the PostgreSQL container starts for the first time.

## Dataset Summary

| File                     | Table               | Rows | Description                              |
|--------------------------|---------------------|------|------------------------------------------|
| `organizations.csv`      | organizations       | 4    | Healthcare, education, finance, gov orgs |
| `incidents.csv`          | incidents           | 4    | Ransomware, phishing, SQLi, vendor breach|
| `indicators.csv`         | indicators          | 4    | IPs, hashes, domains                     |
| `sightings.csv`          | sightings           | 4    | IOC observations from various sensors    |
| `impacts.csv`            | impacts             | 4    | Financial loss and downtime per incident |
| `ttps.csv`               | ttps                | 3    | MITRE ATT&CK techniques                 |
| `vectors.csv`            | vectors             | 4    | Attack vectors                           |
| `campaigns.csv`          | campaigns           | 2    | Named threat campaigns                   |
| `regimes.csv`            | regimes             | 2    | GDPR, HIPAA                              |
| `sources.csv`            | sources             | 4    | Intelligence sources                     |
| `incident_indicators.csv`| incident_indicators | 4    | Incident-to-IOC links                    |
| `incident_vectors.csv`   | incident_vectors    | 4    | Incident-to-vector links                 |
| `incident_ttps.csv`      | incident_ttps       | 3    | Incident-to-TTP links                    |
| `incident_regimes.csv`   | incident_regimes    | 4    | Incident-to-regime links with notify date|
| `incident_sources.csv`   | incident_sources    | 4    | Incident-to-source links                 |
| `indicator_campaign.csv` | indicator_campaign  | 3    | Indicator-to-campaign links              |

## Scenarios

The seed data models four realistic incident scenarios:

1. **Ransomware (Healthcare)** -- Acme Health, $850K loss, 3-day downtime,
   HIPAA-notified, linked to CloudRansom-2024 campaign.
2. **Phishing (Education)** -- Metro Uni, $120K loss, credential theft,
   GDPR-notified, linked to PhishEdu-2023 campaign.
3. **SQL Injection (Finance)** -- Finix Bank, open/critical, no financial
   impact yet recorded, GDPR-applicable.
4. **Vendor Breach (Government)** -- CityGov, $300K loss, 1-day downtime,
   HIPAA-notified, third-party vector.

## Modifying Seed Data

Edit the CSV files directly and rebuild the database:

```bash
make reset
```

Ensure foreign key references remain consistent across files.
