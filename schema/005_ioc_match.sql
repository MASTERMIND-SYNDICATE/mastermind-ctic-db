BEGIN;

-- 1) Guarantee seen_on even if ETL omits it
ALTER TABLE public.sightings
  ALTER COLUMN seen_on SET DEFAULT (now()::date);

-- 2) Helper to build a stable de-dupe key
CREATE OR REPLACE FUNCTION public.compute_match_fingerprint(
  p_indicator_id bigint, p_src_system text, p_raw text
) RETURNS text LANGUAGE plpgsql AS $$
BEGIN
  RETURN md5(coalesce(p_src_system,'') || '|' || p_indicator_id::text || '|' || coalesce(p_raw,''));
END$$;

-- 3) BEFORE INSERT trigger: fill seen_on + match_fingerprint
CREATE OR REPLACE FUNCTION public.sightings_before_ins_trg()
RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE
  ing_ts timestamptz;
  rawtxt text;
BEGIN
  IF NEW.seen_on IS NULL THEN
    IF NEW.context IS NOT NULL THEN
      BEGIN
        ing_ts := NULLIF(NEW.context->>'ingested_at','')::timestamptz;
      EXCEPTION WHEN others THEN
        ing_ts := NULL;
      END;
    END IF;
    NEW.seen_on := COALESCE(ing_ts::date, CURRENT_DATE);
  END IF;

  IF NEW.match_fingerprint IS NULL THEN
    IF NEW.context ? 'raw' THEN rawtxt := NEW.context->>'raw'; END IF;
    NEW.match_fingerprint := public.compute_match_fingerprint(
      NEW.indicator_id, NEW.src_system, rawtxt
    );
  END IF;

  RETURN NEW;
END$$;

DROP TRIGGER IF EXISTS trg_sightings_before_ins ON public.sightings;
CREATE TRIGGER trg_sightings_before_ins
BEFORE INSERT ON public.sightings
FOR EACH ROW EXECUTE FUNCTION public.sightings_before_ins_trg();

COMMIT;
