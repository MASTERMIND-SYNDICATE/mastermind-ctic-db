-- =============================================================================
-- Open-CTIC: Consolidated Database Schema
-- Version: 2.0
-- Description: Complete schema for the Cyber Threat Intelligence Center
-- =============================================================================
--
-- This file creates all tables, indexes, constraints, functions, and triggers
-- required by the Open-CTIC platform. It is idempotent and safe to re-run.
--
-- Table hierarchy:
--   Core:       organizations, incidents, indicators, sightings
--   Taxonomy:   vectors, ttps, campaigns, regimes, sources
--   Impacts:    impacts (1:1 with incidents)
--   Junction:   incident_*, indicator_campaign
--   OCSF:       dim_*, sec_event, event_indicator
--   Operations: etl_runs
--
-- =============================================================================

BEGIN;

-- ---------------------------------------------------------------------------
-- Extensions
-- ---------------------------------------------------------------------------

CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- ---------------------------------------------------------------------------
-- Core tables
-- ---------------------------------------------------------------------------

-- Organizations tracked by the CTI center.
CREATE TABLE IF NOT EXISTS public.organizations (
    org_id      SERIAL      PRIMARY KEY,
    name        TEXT        NOT NULL UNIQUE,
    sector      TEXT        NOT NULL,
    size_band   TEXT,                          -- small, medium, large
    country     TEXT,
    domain      TEXT                           -- primary internet domain
);

-- Cyber incidents tied to an organization.
CREATE TABLE IF NOT EXISTS public.incidents (
    incident_id   SERIAL        PRIMARY KEY,
    org_id        INT           NOT NULL REFERENCES public.organizations(org_id) ON DELETE CASCADE,
    start_on      DATE,
    discovered_on DATE,
    end_on        DATE,
    summary       TEXT,
    status        TEXT          CHECK (status IN ('open', 'closed')) DEFAULT 'open',
    severity      TEXT          CHECK (severity IN ('low', 'medium', 'high', 'critical')),
    CHECK (start_on IS NULL OR end_on IS NULL OR start_on <= end_on)
);

-- Indicators of Compromise (IOCs).
-- The ETL pipeline upserts rows keyed on (value).
CREATE TABLE IF NOT EXISTS public.indicators (
    indicator_id  BIGSERIAL     PRIMARY KEY,
    value         TEXT          NOT NULL UNIQUE,
    type          TEXT          NOT NULL,
    source        TEXT          NOT NULL DEFAULT 'manual',
    first_seen    TIMESTAMPTZ,
    last_seen     TIMESTAMPTZ,
    ocsf          JSONB                        -- OCSF-compliant indicator payload
);

CREATE INDEX IF NOT EXISTS idx_indicators_type
    ON public.indicators(type);
CREATE INDEX IF NOT EXISTS idx_indicators_last_seen
    ON public.indicators(last_seen);

-- Sightings: observations of an indicator in the wild.
CREATE TABLE IF NOT EXISTS public.sightings (
    sighting_id       BIGSERIAL     PRIMARY KEY,
    indicator_id      BIGINT        NOT NULL REFERENCES public.indicators(indicator_id) ON DELETE CASCADE,
    seen_on           DATE          NOT NULL DEFAULT CURRENT_DATE,
    src_system        TEXT,
    context           JSONB,
    match_fingerprint TEXT,
    ocsf              JSONB                    -- OCSF-compliant sighting payload
);

CREATE INDEX IF NOT EXISTS idx_sightings_seen_on
    ON public.sightings(seen_on);
CREATE UNIQUE INDEX IF NOT EXISTS uq_sighting
    ON public.sightings(indicator_id, seen_on, src_system, match_fingerprint);

-- ---------------------------------------------------------------------------
-- Taxonomy tables
-- ---------------------------------------------------------------------------

-- Attack vectors (phishing, ransomware, etc.).
CREATE TABLE IF NOT EXISTS public.vectors (
    vector_id   SERIAL  PRIMARY KEY,
    name        TEXT    NOT NULL UNIQUE
);

-- MITRE ATT&CK Tactics, Techniques & Procedures.
CREATE TABLE IF NOT EXISTS public.ttps (
    ttp_id      SERIAL  PRIMARY KEY,
    name        TEXT    NOT NULL,
    mitre_id    TEXT                            -- e.g. T1078, T1190
);

-- Named threat campaigns.
CREATE TABLE IF NOT EXISTS public.campaigns (
    campaign_id   BIGSERIAL PRIMARY KEY,
    name          TEXT      NOT NULL UNIQUE,
    description   TEXT,
    tags          TEXT[]
);

-- Regulatory / compliance regimes (GDPR, HIPAA, etc.).
CREATE TABLE IF NOT EXISTS public.regimes (
    regime_id   SERIAL  PRIMARY KEY,
    name        TEXT    NOT NULL UNIQUE
);

-- Information sources (reports, news articles, regulators).
CREATE TABLE IF NOT EXISTS public.sources (
    source_id     SERIAL  PRIMARY KEY,
    type          TEXT    CHECK (type IN ('report', 'news', 'regulator', 'other')) NOT NULL,
    url           TEXT    NOT NULL,
    collected_on  DATE
);

-- ---------------------------------------------------------------------------
-- Impact tracking (1:1 with incidents)
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.impacts (
    impact_id     SERIAL    PRIMARY KEY,
    incident_id   INT       UNIQUE REFERENCES public.incidents(incident_id) ON DELETE CASCADE,
    amount_usd    NUMERIC   CHECK (amount_usd >= 0),
    downtime_days NUMERIC   CHECK (downtime_days >= 0),
    notes         TEXT
);

-- ---------------------------------------------------------------------------
-- Junction / link tables
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.incident_indicators (
    incident_id   INT REFERENCES public.incidents(incident_id)   ON DELETE CASCADE,
    indicator_id  INT REFERENCES public.indicators(indicator_id) ON DELETE CASCADE,
    PRIMARY KEY (incident_id, indicator_id)
);

CREATE TABLE IF NOT EXISTS public.incident_vectors (
    incident_id INT REFERENCES public.incidents(incident_id) ON DELETE CASCADE,
    vector_id   INT REFERENCES public.vectors(vector_id)     ON DELETE CASCADE,
    PRIMARY KEY (incident_id, vector_id)
);

CREATE TABLE IF NOT EXISTS public.incident_ttps (
    incident_id INT REFERENCES public.incidents(incident_id) ON DELETE CASCADE,
    ttp_id      INT REFERENCES public.ttps(ttp_id)           ON DELETE CASCADE,
    PRIMARY KEY (incident_id, ttp_id)
);

CREATE TABLE IF NOT EXISTS public.incident_regimes (
    incident_id   INT     REFERENCES public.incidents(incident_id) ON DELETE CASCADE,
    regime_id     INT     REFERENCES public.regimes(regime_id)     ON DELETE CASCADE,
    notified_flag BOOLEAN NOT NULL,
    notify_date   DATE,
    PRIMARY KEY (incident_id, regime_id),
    CHECK (notified_flag = FALSE OR notify_date IS NOT NULL)
);

CREATE TABLE IF NOT EXISTS public.incident_sources (
    incident_id INT REFERENCES public.incidents(incident_id) ON DELETE CASCADE,
    source_id   INT REFERENCES public.sources(source_id)     ON DELETE CASCADE,
    PRIMARY KEY (incident_id, source_id)
);

CREATE TABLE IF NOT EXISTS public.indicator_campaign (
    indicator_id INT REFERENCES public.indicators(indicator_id) ON DELETE CASCADE,
    campaign_id  INT REFERENCES public.campaigns(campaign_id)   ON DELETE CASCADE,
    PRIMARY KEY (indicator_id, campaign_id)
);


-- ---------------------------------------------------------------------------
-- OCSF dimension tables
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.dim_user (
    user_id   BIGSERIAL PRIMARY KEY,
    user_name TEXT      UNIQUE,
    email     TEXT
);

CREATE TABLE IF NOT EXISTS public.dim_host (
    host_id   BIGSERIAL PRIMARY KEY,
    host_name TEXT      UNIQUE
);

CREATE TABLE IF NOT EXISTS public.dim_ip (
    ip_id   BIGSERIAL PRIMARY KEY,
    ip_addr INET      UNIQUE
);

CREATE TABLE IF NOT EXISTS public.dim_file (
    file_id BIGSERIAL PRIMARY KEY,
    sha256  TEXT      UNIQUE,
    sha1    TEXT,
    md5     TEXT,
    path    TEXT
);

CREATE TABLE IF NOT EXISTS public.dim_url (
    url_id BIGSERIAL PRIMARY KEY,
    url    TEXT      UNIQUE
);

-- ---------------------------------------------------------------------------
-- OCSF security event fact table
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.sec_event (
    event_id    BIGSERIAL     PRIMARY KEY,
    event_time  TIMESTAMPTZ   NOT NULL,
    class       TEXT          NOT NULL,
    activity_id TEXT,
    severity    SMALLINT,
    category    TEXT,
    vendor      TEXT,
    product     TEXT,
    src_ip_id   BIGINT REFERENCES public.dim_ip(ip_id),
    dst_ip_id   BIGINT REFERENCES public.dim_ip(ip_id),
    user_id     BIGINT REFERENCES public.dim_user(user_id),
    host_id     BIGINT REFERENCES public.dim_host(host_id),
    file_id     BIGINT REFERENCES public.dim_file(file_id),
    url_id      BIGINT REFERENCES public.dim_url(url_id),
    raw_source  TEXT,
    raw_id      BIGINT,
    extras      JSONB
);

CREATE INDEX IF NOT EXISTS idx_sec_event_time     ON public.sec_event(event_time);
CREATE INDEX IF NOT EXISTS idx_sec_event_class    ON public.sec_event(class);
CREATE INDEX IF NOT EXISTS idx_sec_event_severity ON public.sec_event(severity);
CREATE INDEX IF NOT EXISTS idx_sec_event_src_ip   ON public.sec_event(src_ip_id);
CREATE INDEX IF NOT EXISTS idx_sec_event_dst_ip   ON public.sec_event(dst_ip_id);
CREATE INDEX IF NOT EXISTS idx_sec_event_user     ON public.sec_event(user_id);
CREATE INDEX IF NOT EXISTS idx_sec_event_host     ON public.sec_event(host_id);
CREATE INDEX IF NOT EXISTS idx_sec_event_file     ON public.sec_event(file_id);
CREATE INDEX IF NOT EXISTS idx_sec_event_url      ON public.sec_event(url_id);

-- Event-to-indicator link table for IOC matching.
CREATE TABLE IF NOT EXISTS public.event_indicator (
    event_id          BIGINT      NOT NULL REFERENCES public.sec_event(event_id) ON DELETE CASCADE,
    indicator_id      BIGINT      NOT NULL REFERENCES public.indicators(indicator_id) ON DELETE CASCADE,
    match_fingerprint TEXT        NOT NULL,
    matched_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (event_id, indicator_id, match_fingerprint)
);

CREATE INDEX IF NOT EXISTS idx_event_indicator_event
    ON public.event_indicator(event_id);
CREATE INDEX IF NOT EXISTS idx_event_indicator_indicator
    ON public.event_indicator(indicator_id);

-- ---------------------------------------------------------------------------
-- ETL audit trail
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.etl_runs (
    etl_run_id     BIGSERIAL     PRIMARY KEY,
    job            TEXT          NOT NULL,
    started_at     TIMESTAMPTZ   NOT NULL DEFAULT now(),
    finished_at    TIMESTAMPTZ,
    status         TEXT          CHECK (status IN ('ok', 'error')),
    inserted_count INT           DEFAULT 0,
    updated_count  INT           DEFAULT 0,
    error_count    INT           DEFAULT 0,
    notes          TEXT
);

-- ---------------------------------------------------------------------------
-- Functions & triggers
-- ---------------------------------------------------------------------------

-- Stable deduplication key for sightings.
CREATE OR REPLACE FUNCTION public.compute_match_fingerprint(
    p_indicator_id BIGINT,
    p_src_system   TEXT,
    p_raw          TEXT
) RETURNS TEXT
LANGUAGE plpgsql IMMUTABLE AS $$
BEGIN
    RETURN md5(
        COALESCE(p_src_system, '') || '|' ||
        p_indicator_id::TEXT       || '|' ||
        COALESCE(p_raw, '')
    );
END;
$$;

-- Auto-populate seen_on and match_fingerprint on sighting insert.
CREATE OR REPLACE FUNCTION public.sightings_before_ins_trg()
RETURNS TRIGGER
LANGUAGE plpgsql AS $$
DECLARE
    ing_ts  TIMESTAMPTZ;
    rawtxt  TEXT;
BEGIN
    -- Default seen_on from context.ingested_at or CURRENT_DATE.
    IF NEW.seen_on IS NULL THEN
        IF NEW.context IS NOT NULL THEN
            BEGIN
                ing_ts := NULLIF(NEW.context ->> 'ingested_at', '')::TIMESTAMPTZ;
            EXCEPTION WHEN OTHERS THEN
                ing_ts := NULL;
            END;
        END IF;
        NEW.seen_on := COALESCE(ing_ts::DATE, CURRENT_DATE);
    END IF;

    -- Auto-compute deduplication fingerprint.
    IF NEW.match_fingerprint IS NULL THEN
        IF NEW.context ? 'raw' THEN
            rawtxt := NEW.context ->> 'raw';
        END IF;
        NEW.match_fingerprint := public.compute_match_fingerprint(
            NEW.indicator_id, NEW.src_system, rawtxt
        );
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_sightings_before_ins ON public.sightings;
CREATE TRIGGER trg_sightings_before_ins
    BEFORE INSERT ON public.sightings
    FOR EACH ROW
    EXECUTE FUNCTION public.sightings_before_ins_trg();

-- Extract readable text from sec_event for IOC matching.
CREATE OR REPLACE FUNCTION public.sec_event_rawtext(e public.sec_event)
RETURNS TEXT
LANGUAGE sql STABLE AS $$
    SELECT COALESCE(
        e.extras ->> 'raw',
        e.raw_source,
        COALESCE(e.vendor, '') || ' ' ||
        COALESCE(e.product, '') || ' ' ||
        COALESCE(e.category, '') || ' ' ||
        COALESCE(e.class, '')
    )
$$;

-- ---------------------------------------------------------------------------
-- Reporting views
-- ---------------------------------------------------------------------------

-- MISP-compatible attribute view.
CREATE OR REPLACE VIEW public.misp_attribute AS
SELECT
    ROW_NUMBER() OVER (ORDER BY i.indicator_id) AS attribute_id,
    i.type,
    i.value,
    i.first_seen,
    i.last_seen,
    NULL::TEXT[] AS tags
FROM public.indicators i;

-- Disclosure compliance: incidents notified after the 72-hour window.
CREATE OR REPLACE VIEW public.vw_reporting_lag_72h AS
SELECT
    i.incident_id,
    o.name            AS org_name,
    r.name            AS regime,
    i.discovered_on,
    ir.notify_date,
    (ir.notify_date - i.discovered_on) AS days_to_notify,
    (ir.notify_date - i.discovered_on) > 3 AS overdue
FROM public.incidents i
JOIN public.organizations o   USING (org_id)
JOIN public.incident_regimes ir USING (incident_id)
JOIN public.regimes r         USING (regime_id)
WHERE ir.notified_flag = TRUE;

-- Annualized Loss Expectancy by sector (rolling 24 months).
CREATE OR REPLACE VIEW public.vw_ale_by_sector_24m AS
WITH sector_stats AS (
    SELECT
        o.sector,
        COUNT(*)            AS incident_count,
        AVG(imp.amount_usd) AS avg_loss
    FROM public.incidents i
    JOIN public.organizations o USING (org_id)
    JOIN public.impacts imp     USING (incident_id)
    WHERE i.discovered_on >= CURRENT_DATE - INTERVAL '24 months'
    GROUP BY o.sector
)
SELECT
    sector,
    ROUND(incident_count * avg_loss) AS ale_usd
FROM sector_stats
ORDER BY ale_usd DESC;

-- Top MITRE ATT&CK techniques in the last 12 months.
CREATE OR REPLACE VIEW public.vw_top_ttps_12m AS
SELECT
    t.name,
    t.mitre_id,
    COUNT(*) AS incident_count
FROM public.incident_ttps it
JOIN public.ttps t      USING (ttp_id)
JOIN public.incidents i USING (incident_id)
WHERE i.discovered_on >= CURRENT_DATE - INTERVAL '12 months'
GROUP BY t.name, t.mitre_id
ORDER BY incident_count DESC;

-- Data quality: incidents with no linked source.
CREATE OR REPLACE VIEW public.vw_incidents_missing_sources AS
SELECT
    i.incident_id,
    o.name AS org_name
FROM public.incidents i
JOIN public.organizations o USING (org_id)
LEFT JOIN public.incident_sources s USING (incident_id)
WHERE s.source_id IS NULL;

-- High-level KPI summary.
CREATE OR REPLACE VIEW public.vw_kpis AS
SELECT
    (SELECT COUNT(*) FROM public.incidents)   AS incidents_total,
    (SELECT COUNT(*) FROM public.indicators)  AS indicators_total,
    (SELECT COUNT(*) FROM public.campaigns)   AS campaigns_total,
    (SELECT COUNT(*) FROM public.sightings
     WHERE seen_on >= CURRENT_DATE - INTERVAL '30 days') AS sightings_30d;

COMMIT;
