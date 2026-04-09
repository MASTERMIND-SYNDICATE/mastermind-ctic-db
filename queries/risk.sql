-- =============================================================================
-- Risk Analysis Queries
-- Sector-level risk metrics and financial impact analysis.
-- =============================================================================

-- Annualised Loss Expectancy (ALE) by sector
-- Calculates expected annual loss per sector based on incident frequency
-- and average impact over a rolling 24-month window.
SELECT
    sector,
    ale_usd
FROM vw_ale_by_sector_24m;

-- Impact summary by organisation
-- Ranks organisations by total financial impact across all incidents.
SELECT
    o.name            AS organisation,
    o.sector,
    COUNT(i.*)        AS incident_count,
    SUM(imp.amount_usd)   AS total_loss_usd,
    SUM(imp.downtime_days) AS total_downtime_days
FROM incidents i
JOIN organizations o USING (org_id)
JOIN impacts imp     USING (incident_id)
GROUP BY o.name, o.sector
ORDER BY total_loss_usd DESC NULLS LAST;
