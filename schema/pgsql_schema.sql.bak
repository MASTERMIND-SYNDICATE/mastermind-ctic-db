PRAGMA foreign_keys = ON;

CREATE TABLE organizations(
  org_id SERIAL PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  sector TEXT NOT NULL,
  size_band TEXT,
  country TEXT,
  domain TEXT
);

CREATE TABLE incidents(
  incident_id SERIAL PRIMARY KEY,
  org_id INT NOT NULL REFERENCES organizations(org_id) ON DELETE CASCADE,
  start_on DATE,
  discovered_on DATE,
  end_on DATE,
  summary TEXT,
  status TEXT CHECK (status IN ('open','closed')) DEFAULT 'open',
  severity TEXT CHECK (severity IN ('low','medium','high','critical')),
  CHECK (start_on IS NULL OR end_on IS NULL OR start_on <= end_on),
  CHECK (end_on IS NULL OR discovered_on IS NULL OR end_on <= discovered_on)
);

CREATE TABLE vectors(
  vector_id SERIAL PRIMARY KEY,
  name TEXT NOT NULL UNIQUE
);

CREATE TABLE incident_vectors(
  incident_id INT REFERENCES incidents(incident_id) ON DELETE CASCADE,
  vector_id   INT REFERENCES vectors(vector_id)   ON DELETE CASCADE,
  PRIMARY KEY(incident_id, vector_id)
);

CREATE TABLE regimes(
  regime_id SERIAL PRIMARY KEY,
  name TEXT NOT NULL UNIQUE
);

CREATE TABLE incident_regimes(
  incident_id INT REFERENCES incidents(incident_id) ON DELETE CASCADE,
  regime_id   INT REFERENCES regimes(regime_id)     ON DELETE CASCADE,
  notified_flag BOOLEAN NOT NULL,
  notify_date DATE,
  PRIMARY KEY(incident_id, regime_id),
  CHECK (notified_flag = FALSE OR notify_date IS NOT NULL)
);

CREATE TABLE sources(
  source_id SERIAL PRIMARY KEY,
  type TEXT CHECK (type IN ('report','news','regulator','other')) NOT NULL,
  url TEXT NOT NULL,
  collected_on DATE
);

CREATE TABLE incident_sources(
  incident_id INT REFERENCES incidents(incident_id) ON DELETE CASCADE,
  source_id   INT REFERENCES sources(source_id)     ON DELETE CASCADE,
  PRIMARY KEY(incident_id, source_id)
);

CREATE TABLE impacts(
  impact_id SERIAL PRIMARY KEY,
  incident_id INT UNIQUE REFERENCES incidents(incident_id) ON DELETE CASCADE,
  amount_usd NUMERIC CHECK (amount_usd >= 0),
  downtime_days NUMERIC CHECK (downtime_days >= 0),
  notes TEXT
);

CREATE TABLE indicators(
  indicator_id SERIAL PRIMARY KEY,
  value TEXT NOT NULL,
  type TEXT CHECK (type IN ('ip','domain','hash','email','url')) NOT NULL,
  first_seen DATE,
  last_seen DATE,
  source TEXT
);

CREATE TABLE incident_indicators(
  incident_id INT REFERENCES incidents(incident_id) ON DELETE CASCADE,
  indicator_id INT REFERENCES indicators(indicator_id) ON DELETE CASCADE,
  PRIMARY KEY(incident_id, indicator_id)
);

CREATE TABLE ttps(
  ttp_id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  mitre_id TEXT
);

CREATE TABLE incident_ttps(
  incident_id INT REFERENCES incidents(incident_id) ON DELETE CASCADE,
  ttp_id INT REFERENCES ttps(ttp_id) ON DELETE CASCADE,
  PRIMARY KEY(incident_id, ttp_id)
);

CREATE TABLE campaigns(
  campaign_id SERIAL PRIMARY KEY,
  name TEXT NOT NULL
);

CREATE TABLE indicator_campaign(
  indicator_id INT REFERENCES indicators(indicator_id) ON DELETE CASCADE,
  campaign_id INT REFERENCES campaigns(campaign_id) ON DELETE CASCADE,
  PRIMARY KEY(indicator_id, campaign_id)
);

CREATE TABLE sightings(
  sighting_id SERIAL PRIMARY KEY,
  indicator_id INT NOT NULL REFERENCES indicators(indicator_id) ON DELETE CASCADE,
  seen_on DATE NOT NULL,
  src_system TEXT,
  context TEXT
);
