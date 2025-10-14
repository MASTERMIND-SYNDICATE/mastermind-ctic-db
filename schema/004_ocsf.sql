-- B) CTIC v3 — schema/004_ocsf.sql
BEGIN;

-- Dimension tables
CREATE TABLE IF NOT EXISTS public.dim_user(
  user_id   BIGSERIAL PRIMARY KEY,
  user_name TEXT UNIQUE,
  email     TEXT
);

CREATE TABLE IF NOT EXISTS public.dim_host(
  host_id   BIGSERIAL PRIMARY KEY,
  host_name TEXT UNIQUE
);

CREATE TABLE IF NOT EXISTS public.dim_ip(
  ip_id   BIGSERIAL PRIMARY KEY,
  ip_addr INET UNIQUE
);

CREATE TABLE IF NOT EXISTS public.dim_file(
  file_id BIGSERIAL PRIMARY KEY,
  sha256  TEXT UNIQUE,
  sha1    TEXT,
  md5     TEXT,
  path    TEXT
);

CREATE TABLE IF NOT EXISTS public.dim_url(
  url_id BIGSERIAL PRIMARY KEY,
  url    TEXT UNIQUE
);

-- OCSF-like security event fact
CREATE TABLE IF NOT EXISTS public.sec_event(
  event_id    BIGSERIAL PRIMARY KEY,
  event_time  TIMESTAMPTZ NOT NULL,
  class       TEXT NOT NULL,
  activity_id TEXT,
  severity    SMALLINT,
  category    TEXT,
  vendor      TEXT,
  product     TEXT,
  src_ip_id BIGINT REFERENCES public.dim_ip(ip_id),
  dst_ip_id BIGINT REFERENCES public.dim_ip(ip_id),
  user_id   BIGINT REFERENCES public.dim_user(user_id),
  host_id   BIGINT REFERENCES public.dim_host(host_id),
  file_id   BIGINT REFERENCES public.dim_file(file_id),
  url_id    BIGINT REFERENCES public.dim_url(url_id),
  raw_source TEXT,
  raw_id     BIGINT,
  extras     JSONB
);

-- Indexes for sec_event
CREATE INDEX IF NOT EXISTS idx_sec_event_time      ON public.sec_event(event_time);
CREATE INDEX IF NOT EXISTS idx_sec_event_class     ON public.sec_event(class);
CREATE INDEX IF NOT EXISTS idx_sec_event_severity  ON public.sec_event(severity);
CREATE INDEX IF NOT EXISTS idx_sec_event_src_ip    ON public.sec_event(src_ip_id);
CREATE INDEX IF NOT EXISTS idx_sec_event_dst_ip    ON public.sec_event(dst_ip_id);
CREATE INDEX IF NOT EXISTS idx_sec_event_user      ON public.sec_event(user_id);
CREATE INDEX IF NOT EXISTS idx_sec_event_host      ON public.sec_event(host_id);
CREATE INDEX IF NOT EXISTS idx_sec_event_file      ON public.sec_event(file_id);
CREATE INDEX IF NOT EXISTS idx_sec_event_url       ON public.sec_event(url_id);

-- Emulate MISP attributes from indicators
CREATE OR REPLACE VIEW public.misp_attribute AS
SELECT
  ROW_NUMBER() OVER (ORDER BY i.indicator_id) AS attribute_id,
  i.type       AS type,
  i.value      AS value,
  i.first_seen AS first_seen,
  i.last_seen  AS last_seen,
  NULL::TEXT[] AS tags
FROM public.indicators i;

COMMIT;
