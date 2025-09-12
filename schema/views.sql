CREATE OR REPLACE VIEW vw_reporting_lag_72h AS
SELECT i.incident_id, o.name, r.name AS regime,
       i.discovered_on, ir.notify_date,
       (ir.notify_date - i.discovered_on) AS days_to_notify,
       (ir.notify_date - i.discovered_on) > 3 AS overdue
FROM incidents i
JOIN organizations o USING (org_id)
JOIN incident_regimes ir USING (incident_id)
JOIN regimes r USING (regime_id)
WHERE ir.notified_flag = true;

CREATE OR REPLACE VIEW vw_ale_by_sector_24m AS
WITH x AS (
  SELECT o.sector, COUNT(*) n, AVG(imp.amount_usd) avg_loss
  FROM incidents i
  JOIN organizations o USING (org_id)
  JOIN impacts imp USING (incident_id)
  WHERE i.discovered_on >= CURRENT_DATE - INTERVAL '24 months'
  GROUP BY o.sector
)
SELECT sector, ROUND(n*avg_loss) ale_usd
FROM x ORDER BY ale_usd DESC;

CREATE OR REPLACE VIEW vw_top_ttps_12m AS
SELECT t.name, COUNT(*) cnt
FROM incident_ttps it
JOIN ttps t USING (ttp_id)
JOIN incidents i USING (incident_id)
WHERE i.discovered_on >= CURRENT_DATE - INTERVAL '12 months'
GROUP BY t.name ORDER BY cnt DESC;

CREATE OR REPLACE VIEW vw_incidents_missing_sources AS
SELECT i.incident_id, o.name
FROM incidents i
JOIN organizations o USING (org_id)
LEFT JOIN incident_sources s USING (incident_id)
WHERE s.source_id IS NULL;

CREATE OR REPLACE VIEW vw_kpis AS
SELECT
  (SELECT COUNT(*) FROM incidents) incidents_total,
  (SELECT COUNT(*) FROM indicators) indicators_total,
  (SELECT COUNT(*) FROM campaigns) campaigns_total,
  (SELECT COUNT(*) FROM sightings WHERE seen_on >= CURRENT_DATE - INTERVAL '30 days') sightings_30d;
