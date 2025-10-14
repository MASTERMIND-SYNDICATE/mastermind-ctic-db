BEGIN;

CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- Link table: events ↔ indicators
CREATE TABLE IF NOT EXISTS public.event_indicator (
  event_id          BIGINT NOT NULL REFERENCES public.sec_event(event_id) ON DELETE CASCADE,
  indicator_id      BIGINT NOT NULL REFERENCES public.indicators(indicator_id) ON DELETE CASCADE,
  match_fingerprint TEXT  NOT NULL,
  matched_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (event_id, indicator_id, match_fingerprint)
);
CREATE INDEX IF NOT EXISTS idx_event_indicator_event     ON public.event_indicator(event_id);
CREATE INDEX IF NOT EXISTS idx_event_indicator_indicator ON public.event_indicator(indicator_id);

-- Helper: readable raw text from sec_event
CREATE OR REPLACE FUNCTION public.sec_event_rawtext(e public.sec_event)
RETURNS text
LANGUAGE sql STABLE AS $$
  SELECT coalesce(
    e.extras ->> 'raw',
    e.raw_source,
    e.vendor || ' ' || e.product || ' ' || e.category || ' ' || e.class
  )
$$;

-- Build materialized view (start empty)
DROP MATERIALIZED VIEW IF EXISTS public.mv_sec_event_indicator;
CREATE MATERIALIZED VIEW public.mv_sec_event_indicator AS
SELECT
  e.event_id,
  i.indicator_id,
  public.compute_match_fingerprint(
    i.indicator_id,
    'sec_event',
    public.sec_event_rawtext(e)
  ) AS match_fingerprint
FROM public.sec_event e
JOIN public.indicators i
  ON POSITION(i.value IN public.sec_event_rawtext(e)) > 0
WITH NO DATA;

-- First populate MUST be non-concurrent
REFRESH MATERIALIZED VIEW public.mv_sec_event_indicator;

-- Unique index to allow concurrent refreshes later
CREATE UNIQUE INDEX IF NOT EXISTS uq_mv_sec_event_indicator
  ON public.mv_sec_event_indicator(event_id, indicator_id, match_fingerprint);

-- Seed the link table from the MV
INSERT INTO public.event_indicator(event_id, indicator_id, match_fingerprint)
SELECT event_id, indicator_id, match_fingerprint
FROM public.mv_sec_event_indicator
ON CONFLICT DO NOTHING;

COMMIT;
