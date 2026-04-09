-- =============================================================================
-- Open-CTIC: Seed Data
-- Description: Load demo data from CSV files in /docker-entrypoint-initdb.d/seed/
-- =============================================================================
--
-- This script is executed automatically by the Postgres entrypoint after
-- 001_init.sql.  It uses COPY to bulk-load the CSV seed files that are
-- mounted into the container at /docker-entrypoint-initdb.d/seed/.
--
-- Load order respects foreign key dependencies.
-- =============================================================================

BEGIN;

-- 1. Organizations (no FK dependencies)
COPY public.organizations (org_id, name, sector, size_band, country, domain)
    FROM '/docker-entrypoint-initdb.d/seed/organizations.csv'
    WITH (FORMAT csv, HEADER true);

-- 2. Regimes (no FK dependencies)
COPY public.regimes (regime_id, name)
    FROM '/docker-entrypoint-initdb.d/seed/regimes.csv'
    WITH (FORMAT csv, HEADER true);

-- 3. Vectors (no FK dependencies)
COPY public.vectors (vector_id, name)
    FROM '/docker-entrypoint-initdb.d/seed/vectors.csv'
    WITH (FORMAT csv, HEADER true);

-- 4. TTPs (no FK dependencies)
COPY public.ttps (ttp_id, name, mitre_id)
    FROM '/docker-entrypoint-initdb.d/seed/ttps.csv'
    WITH (FORMAT csv, HEADER true);

-- 5. Sources (no FK dependencies)
COPY public.sources (source_id, type, url, collected_on)
    FROM '/docker-entrypoint-initdb.d/seed/sources.csv'
    WITH (FORMAT csv, HEADER true);

-- 6. Campaigns (no FK dependencies)
COPY public.campaigns (campaign_id, name)
    FROM '/docker-entrypoint-initdb.d/seed/campaigns.csv'
    WITH (FORMAT csv, HEADER true);

-- 7. Incidents (depends on organizations)
COPY public.incidents (incident_id, org_id, start_on, discovered_on, end_on, summary, status, severity)
    FROM '/docker-entrypoint-initdb.d/seed/incidents.csv'
    WITH (FORMAT csv, HEADER true);

-- 8. Indicators (no FK dependencies)
COPY public.indicators (indicator_id, value, type, first_seen, last_seen, source)
    FROM '/docker-entrypoint-initdb.d/seed/indicators.csv'
    WITH (FORMAT csv, HEADER true);

-- 9. Impacts (depends on incidents)
COPY public.impacts (impact_id, incident_id, amount_usd, downtime_days, notes)
    FROM '/docker-entrypoint-initdb.d/seed/impacts.csv'
    WITH (FORMAT csv, HEADER true);

-- 10. Sightings (depends on indicators)
COPY public.sightings (sighting_id, indicator_id, seen_on, src_system, context)
    FROM '/docker-entrypoint-initdb.d/seed/sightings.csv'
    WITH (FORMAT csv, HEADER true);

-- 11. Junction tables (depend on core tables above)
COPY public.incident_indicators (incident_id, indicator_id)
    FROM '/docker-entrypoint-initdb.d/seed/incident_indicators.csv'
    WITH (FORMAT csv, HEADER true);

COPY public.incident_vectors (incident_id, vector_id)
    FROM '/docker-entrypoint-initdb.d/seed/incident_vectors.csv'
    WITH (FORMAT csv, HEADER true);

COPY public.incident_ttps (incident_id, ttp_id)
    FROM '/docker-entrypoint-initdb.d/seed/incident_ttps.csv'
    WITH (FORMAT csv, HEADER true);

COPY public.incident_regimes (incident_id, regime_id, notified_flag, notify_date)
    FROM '/docker-entrypoint-initdb.d/seed/incident_regimes.csv'
    WITH (FORMAT csv, HEADER true);

COPY public.incident_sources (incident_id, source_id)
    FROM '/docker-entrypoint-initdb.d/seed/incident_sources.csv'
    WITH (FORMAT csv, HEADER true);

COPY public.indicator_campaign (indicator_id, campaign_id)
    FROM '/docker-entrypoint-initdb.d/seed/indicator_campaign.csv'
    WITH (FORMAT csv, HEADER true);

-- Reset sequences to the max value so new inserts get correct IDs.
SELECT setval('organizations_org_id_seq',       (SELECT COALESCE(MAX(org_id), 0)       FROM public.organizations));
SELECT setval('incidents_incident_id_seq',      (SELECT COALESCE(MAX(incident_id), 0)  FROM public.incidents));
SELECT setval('indicators_indicator_id_seq',    (SELECT COALESCE(MAX(indicator_id), 0) FROM public.indicators));
SELECT setval('sightings_sighting_id_seq',      (SELECT COALESCE(MAX(sighting_id), 0)  FROM public.sightings));
SELECT setval('vectors_vector_id_seq',          (SELECT COALESCE(MAX(vector_id), 0)    FROM public.vectors));
SELECT setval('ttps_ttp_id_seq',                (SELECT COALESCE(MAX(ttp_id), 0)       FROM public.ttps));
SELECT setval('campaigns_campaign_id_seq',      (SELECT COALESCE(MAX(campaign_id), 0)  FROM public.campaigns));
SELECT setval('regimes_regime_id_seq',          (SELECT COALESCE(MAX(regime_id), 0)    FROM public.regimes));
SELECT setval('sources_source_id_seq',          (SELECT COALESCE(MAX(source_id), 0)    FROM public.sources));
SELECT setval('impacts_impact_id_seq',          (SELECT COALESCE(MAX(impact_id), 0)    FROM public.impacts));

COMMIT;
