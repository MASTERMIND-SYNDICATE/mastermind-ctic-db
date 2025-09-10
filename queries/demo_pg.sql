-- 1) Over-72h disclosures (GDPR/HIPAA)
SELECT i.incident_id, o.name, r.name AS regime, ir.notify_date, i.discovered_on,
       (ir.notify_date - i.discovered_on) AS days_to_notify
FROM incidents i
JOIN organizations o USING (org_id)
JOIN incident_regimes ir USING (incident_id)
JOIN regimes r USING (regime_id)
WHERE ir.notified_flag = TRUE
  AND (ir.notify_date - i.discovered_on) > 3
ORDER BY days_to_notify DESC;

-- 2) ALE by sector (last 24 months)
WITH x AS (
  SELECT o.sector, COUNT(*) AS n, AVG(imp.amount_usd) AS avg_loss
  FROM incidents i
  JOIN organizations o USING (org_id)
  JOIN impacts imp USING (incident_id)
  WHERE i.discovered_on >= CURRENT_DATE - INTERVAL '24 months'
  GROUP BY o.sector
)
SELECT sector, ROUND(n * avg_loss) AS ale_usd
FROM x
ORDER BY ale_usd DESC;

-- 3) Top TTPs last 12 months
SELECT t.name, COUNT(*) AS cnt
FROM incident_ttps it
JOIN ttps t USING (ttp_id)
JOIN incidents i USING (incident_id)
WHERE i.discovered_on >= CURRENT_DATE - INTERVAL '12 months'
GROUP BY t.name
ORDER BY cnt DESC;

-- 4) Campaigns reusing >= 2 indicators
SELECT c.name, COUNT(*) AS shared_iocs
FROM indicator_campaign ic
JOIN campaigns c USING (campaign_id)
GROUP BY c.name
HAVING COUNT(*) >= 2
ORDER BY shared_iocs DESC;

-- 5) Data-quality: incidents missing sources
SELECT i.incident_id, o.name
FROM incidents i
JOIN organizations o USING (org_id)
LEFT JOIN incident_sources s USING (incident_id)
WHERE s.source_id IS NULL;
