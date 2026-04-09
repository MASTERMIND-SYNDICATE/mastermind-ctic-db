-- =============================================================================
-- Compliance Queries
-- Regulatory disclosure tracking and audit checks.
-- =============================================================================

-- Over-72-hour disclosures (GDPR / HIPAA)
-- Identifies incidents where the regulatory notification exceeded the
-- mandatory 72-hour window, flagging potential compliance violations.
SELECT
    incident_id,
    org_name,
    regime,
    discovered_on,
    notify_date,
    days_to_notify,
    overdue
FROM vw_reporting_lag_72h
WHERE overdue = TRUE
ORDER BY days_to_notify DESC;

-- Data quality: incidents missing intelligence sources
-- Incidents without at least one linked source lack an evidence trail
-- and may not meet audit requirements.
SELECT
    incident_id,
    org_name
FROM vw_incidents_missing_sources;
