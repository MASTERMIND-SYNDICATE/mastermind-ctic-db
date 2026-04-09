-- =============================================================================
-- Threat Landscape Queries
-- TTP trends, campaign analysis, and indicator intelligence.
-- =============================================================================

-- Top MITRE ATT&CK techniques (last 12 months)
-- Shows which techniques are most prevalent in recent incidents.
SELECT
    name,
    mitre_id,
    incident_count
FROM vw_top_ttps_12m
LIMIT 20;

-- Campaign indicator overlap
-- Identifies campaigns that share multiple indicators, suggesting
-- coordinated threat activity or tool reuse.
SELECT
    c.name          AS campaign,
    COUNT(*)        AS shared_iocs
FROM indicator_campaign ic
JOIN campaigns c USING (campaign_id)
GROUP BY c.name
HAVING COUNT(*) >= 2
ORDER BY shared_iocs DESC;

-- Recently active indicators
-- IOCs observed in the last 7 days, useful for blocklist generation.
SELECT
    value,
    type,
    source,
    last_seen
FROM indicators
WHERE last_seen >= CURRENT_DATE - INTERVAL '7 days'
ORDER BY last_seen DESC;

-- KPI summary
-- Quick overview of the intelligence database.
SELECT * FROM vw_kpis;
