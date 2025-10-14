-- A) CTIC v3 — schema/003_schema_expansion.sql
-- Idempotent DDL + safe backfills. All in public schema.

BEGIN;

-- 1) indicators: first_seen, last_seen
ALTER TABLE public.indicators
  ADD COLUMN IF NOT EXISTS first_seen TIMESTAMPTZ;

ALTER TABLE public.indicators
  ADD COLUMN IF NOT EXISTS last_seen  TIMESTAMPTZ;

-- Minimal, safe backfill: set any NULLs to now()
UPDATE public.indicators
  SET first_seen = COALESCE(first_seen, now()),
      last_seen  = COALESCE(last_seen,  now());

-- Helpful indexes
CREATE INDEX IF NOT EXISTS idx_indicators_type      ON public.indicators(type);
CREATE INDEX IF NOT EXISTS idx_indicators_last_seen ON public.indicators(last_seen);

-- 2) campaigns + link table
CREATE TABLE IF NOT EXISTS public.campaigns (
  campaign_id BIGSERIAL PRIMARY KEY,
  name        TEXT UNIQUE NOT NULL,
  description TEXT,
  tags        TEXT[]
);

CREATE TABLE IF NOT EXISTS public.campaign_indicator (
  campaign_id  BIGINT REFERENCES public.campaigns(campaign_id) ON DELETE CASCADE,
  indicator_id BIGINT REFERENCES public.indicators(indicator_id) ON DELETE CASCADE,
  PRIMARY KEY(campaign_id, indicator_id)
);

-- Helpful indexes on link table
CREATE INDEX IF NOT EXISTS idx_campaign_indicator_campaign  ON public.campaign_indicator(campaign_id);
CREATE INDEX IF NOT EXISTS idx_campaign_indicator_indicator ON public.campaign_indicator(indicator_id);

-- 3) sightings: match_fingerprint + de-dupe unique index
ALTER TABLE public.sightings
  ADD COLUMN IF NOT EXISTS match_fingerprint TEXT;

-- De-dupe across core keys. seen_on must be NOT NULL already.
CREATE UNIQUE INDEX IF NOT EXISTS uq_sighting
  ON public.sightings(indicator_id, seen_on, src_system, match_fingerprint);

-- Helpful index
CREATE INDEX IF NOT EXISTS idx_sightings_seen_on ON public.sightings(seen_on);

COMMIT;
