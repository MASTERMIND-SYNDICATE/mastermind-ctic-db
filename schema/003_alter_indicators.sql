BEGIN;

ALTER TABLE public.indicators
  ADD COLUMN IF NOT EXISTS first_seen TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS last_seen  TIMESTAMPTZ;

CREATE INDEX IF NOT EXISTS idx_indicators_type ON public.indicators(type);
CREATE INDEX IF NOT EXISTS idx_indicators_last_seen ON public.indicators(last_seen);

UPDATE public.indicators
SET first_seen = COALESCE(first_seen, now()),
    last_seen  = COALESCE(last_seen,  now());

CREATE TABLE IF NOT EXISTS public.etl_runs (
  etl_run_id      BIGSERIAL PRIMARY KEY,
  job             TEXT NOT NULL,
  started_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  finished_at     TIMESTAMPTZ,
  status          TEXT CHECK (status IN ('ok','error')),
  inserted_count  INTEGER DEFAULT 0,
  updated_count   INTEGER DEFAULT 0,
  error_count     INTEGER DEFAULT 0,
  details         JSONB
);

COMMIT;
