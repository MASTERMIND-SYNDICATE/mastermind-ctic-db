--
-- PostgreSQL database dump
--

\restrict CuBItorx3ihaE2OxN69haqQKga0HD90QLbLaL2VFZgknkbbs7ReOcHGJqm0jvcx

-- Dumped from database version 15.14 (Debian 15.14-1.pgdg13+1)
-- Dumped by pg_dump version 15.14 (Homebrew)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: campaigns; Type: TABLE; Schema: public; Owner: ctic
--

CREATE TABLE public.campaigns (
    campaign_id integer NOT NULL,
    name text NOT NULL
);


ALTER TABLE public.campaigns OWNER TO ctic;

--
-- Name: campaigns_campaign_id_seq; Type: SEQUENCE; Schema: public; Owner: ctic
--

CREATE SEQUENCE public.campaigns_campaign_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.campaigns_campaign_id_seq OWNER TO ctic;

--
-- Name: campaigns_campaign_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ctic
--

ALTER SEQUENCE public.campaigns_campaign_id_seq OWNED BY public.campaigns.campaign_id;


--
-- Name: impacts; Type: TABLE; Schema: public; Owner: ctic
--

CREATE TABLE public.impacts (
    impact_id integer NOT NULL,
    incident_id integer,
    amount_usd numeric,
    downtime_days numeric,
    notes text,
    CONSTRAINT impacts_amount_usd_check CHECK ((amount_usd >= (0)::numeric)),
    CONSTRAINT impacts_downtime_days_check CHECK ((downtime_days >= (0)::numeric))
);


ALTER TABLE public.impacts OWNER TO ctic;

--
-- Name: impacts_impact_id_seq; Type: SEQUENCE; Schema: public; Owner: ctic
--

CREATE SEQUENCE public.impacts_impact_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.impacts_impact_id_seq OWNER TO ctic;

--
-- Name: impacts_impact_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ctic
--

ALTER SEQUENCE public.impacts_impact_id_seq OWNED BY public.impacts.impact_id;


--
-- Name: incident_indicators; Type: TABLE; Schema: public; Owner: ctic
--

CREATE TABLE public.incident_indicators (
    incident_id integer NOT NULL,
    indicator_id integer NOT NULL
);


ALTER TABLE public.incident_indicators OWNER TO ctic;

--
-- Name: incident_regimes; Type: TABLE; Schema: public; Owner: ctic
--

CREATE TABLE public.incident_regimes (
    incident_id integer NOT NULL,
    regime_id integer NOT NULL,
    notified_flag boolean NOT NULL,
    notify_date date,
    CONSTRAINT incident_regimes_check CHECK (((notified_flag = false) OR (notify_date IS NOT NULL)))
);


ALTER TABLE public.incident_regimes OWNER TO ctic;

--
-- Name: incident_sources; Type: TABLE; Schema: public; Owner: ctic
--

CREATE TABLE public.incident_sources (
    incident_id integer NOT NULL,
    source_id integer NOT NULL
);


ALTER TABLE public.incident_sources OWNER TO ctic;

--
-- Name: incident_ttps; Type: TABLE; Schema: public; Owner: ctic
--

CREATE TABLE public.incident_ttps (
    incident_id integer NOT NULL,
    ttp_id integer NOT NULL
);


ALTER TABLE public.incident_ttps OWNER TO ctic;

--
-- Name: incident_vectors; Type: TABLE; Schema: public; Owner: ctic
--

CREATE TABLE public.incident_vectors (
    incident_id integer NOT NULL,
    vector_id integer NOT NULL
);


ALTER TABLE public.incident_vectors OWNER TO ctic;

--
-- Name: incidents; Type: TABLE; Schema: public; Owner: ctic
--

CREATE TABLE public.incidents (
    incident_id integer NOT NULL,
    org_id integer NOT NULL,
    start_on date,
    discovered_on date,
    end_on date,
    summary text,
    status text DEFAULT 'open'::text,
    severity text,
    CONSTRAINT incidents_check CHECK (((start_on IS NULL) OR (end_on IS NULL) OR (start_on <= end_on))),
    CONSTRAINT incidents_check1 CHECK (((discovered_on IS NULL) OR (end_on IS NULL) OR (discovered_on <= end_on))),
    CONSTRAINT incidents_severity_check CHECK ((severity = ANY (ARRAY['low'::text, 'medium'::text, 'high'::text, 'critical'::text]))),
    CONSTRAINT incidents_status_check CHECK ((status = ANY (ARRAY['open'::text, 'closed'::text])))
);


ALTER TABLE public.incidents OWNER TO ctic;

--
-- Name: incidents_incident_id_seq; Type: SEQUENCE; Schema: public; Owner: ctic
--

CREATE SEQUENCE public.incidents_incident_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.incidents_incident_id_seq OWNER TO ctic;

--
-- Name: incidents_incident_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ctic
--

ALTER SEQUENCE public.incidents_incident_id_seq OWNED BY public.incidents.incident_id;


--
-- Name: indicator_campaign; Type: TABLE; Schema: public; Owner: ctic
--

CREATE TABLE public.indicator_campaign (
    indicator_id integer NOT NULL,
    campaign_id integer NOT NULL
);


ALTER TABLE public.indicator_campaign OWNER TO ctic;

--
-- Name: indicators; Type: TABLE; Schema: public; Owner: ctic
--

CREATE TABLE public.indicators (
    indicator_id integer NOT NULL,
    value text NOT NULL,
    type text NOT NULL,
    first_seen date,
    last_seen date,
    source text,
    CONSTRAINT indicators_type_check CHECK ((type = ANY (ARRAY['ip'::text, 'domain'::text, 'hash'::text, 'email'::text, 'url'::text])))
);


ALTER TABLE public.indicators OWNER TO ctic;

--
-- Name: indicators_indicator_id_seq; Type: SEQUENCE; Schema: public; Owner: ctic
--

CREATE SEQUENCE public.indicators_indicator_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.indicators_indicator_id_seq OWNER TO ctic;

--
-- Name: indicators_indicator_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ctic
--

ALTER SEQUENCE public.indicators_indicator_id_seq OWNED BY public.indicators.indicator_id;


--
-- Name: organizations; Type: TABLE; Schema: public; Owner: ctic
--

CREATE TABLE public.organizations (
    org_id integer NOT NULL,
    name text NOT NULL,
    sector text NOT NULL,
    size_band text,
    country text,
    domain text
);


ALTER TABLE public.organizations OWNER TO ctic;

--
-- Name: organizations_org_id_seq; Type: SEQUENCE; Schema: public; Owner: ctic
--

CREATE SEQUENCE public.organizations_org_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.organizations_org_id_seq OWNER TO ctic;

--
-- Name: organizations_org_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ctic
--

ALTER SEQUENCE public.organizations_org_id_seq OWNED BY public.organizations.org_id;


--
-- Name: regimes; Type: TABLE; Schema: public; Owner: ctic
--

CREATE TABLE public.regimes (
    regime_id integer NOT NULL,
    name text NOT NULL
);


ALTER TABLE public.regimes OWNER TO ctic;

--
-- Name: regimes_regime_id_seq; Type: SEQUENCE; Schema: public; Owner: ctic
--

CREATE SEQUENCE public.regimes_regime_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.regimes_regime_id_seq OWNER TO ctic;

--
-- Name: regimes_regime_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ctic
--

ALTER SEQUENCE public.regimes_regime_id_seq OWNED BY public.regimes.regime_id;


--
-- Name: sightings; Type: TABLE; Schema: public; Owner: ctic
--

CREATE TABLE public.sightings (
    sighting_id integer NOT NULL,
    indicator_id integer NOT NULL,
    seen_on date NOT NULL,
    src_system text,
    context text
);


ALTER TABLE public.sightings OWNER TO ctic;

--
-- Name: sightings_sighting_id_seq; Type: SEQUENCE; Schema: public; Owner: ctic
--

CREATE SEQUENCE public.sightings_sighting_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.sightings_sighting_id_seq OWNER TO ctic;

--
-- Name: sightings_sighting_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ctic
--

ALTER SEQUENCE public.sightings_sighting_id_seq OWNED BY public.sightings.sighting_id;


--
-- Name: sources; Type: TABLE; Schema: public; Owner: ctic
--

CREATE TABLE public.sources (
    source_id integer NOT NULL,
    type text NOT NULL,
    url text NOT NULL,
    collected_on date,
    CONSTRAINT sources_type_check CHECK ((type = ANY (ARRAY['report'::text, 'news'::text, 'regulator'::text, 'other'::text])))
);


ALTER TABLE public.sources OWNER TO ctic;

--
-- Name: sources_source_id_seq; Type: SEQUENCE; Schema: public; Owner: ctic
--

CREATE SEQUENCE public.sources_source_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.sources_source_id_seq OWNER TO ctic;

--
-- Name: sources_source_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ctic
--

ALTER SEQUENCE public.sources_source_id_seq OWNED BY public.sources.source_id;


--
-- Name: ttps; Type: TABLE; Schema: public; Owner: ctic
--

CREATE TABLE public.ttps (
    ttp_id integer NOT NULL,
    name text NOT NULL,
    mitre_id text
);


ALTER TABLE public.ttps OWNER TO ctic;

--
-- Name: ttps_ttp_id_seq; Type: SEQUENCE; Schema: public; Owner: ctic
--

CREATE SEQUENCE public.ttps_ttp_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.ttps_ttp_id_seq OWNER TO ctic;

--
-- Name: ttps_ttp_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ctic
--

ALTER SEQUENCE public.ttps_ttp_id_seq OWNED BY public.ttps.ttp_id;


--
-- Name: vectors; Type: TABLE; Schema: public; Owner: ctic
--

CREATE TABLE public.vectors (
    vector_id integer NOT NULL,
    name text NOT NULL
);


ALTER TABLE public.vectors OWNER TO ctic;

--
-- Name: vectors_vector_id_seq; Type: SEQUENCE; Schema: public; Owner: ctic
--

CREATE SEQUENCE public.vectors_vector_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.vectors_vector_id_seq OWNER TO ctic;

--
-- Name: vectors_vector_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ctic
--

ALTER SEQUENCE public.vectors_vector_id_seq OWNED BY public.vectors.vector_id;


--
-- Name: vw_ale_by_sector_24m; Type: VIEW; Schema: public; Owner: ctic
--

CREATE VIEW public.vw_ale_by_sector_24m AS
 WITH x AS (
         SELECT o.sector,
            count(*) AS n,
            avg(imp.amount_usd) AS avg_loss
           FROM ((public.incidents i
             JOIN public.organizations o USING (org_id))
             JOIN public.impacts imp USING (incident_id))
          WHERE (i.discovered_on >= (CURRENT_DATE - '2 years'::interval))
          GROUP BY o.sector
        )
 SELECT x.sector,
    round(((x.n)::numeric * x.avg_loss)) AS ale_usd
   FROM x
  ORDER BY (round(((x.n)::numeric * x.avg_loss))) DESC;


ALTER TABLE public.vw_ale_by_sector_24m OWNER TO ctic;

--
-- Name: vw_incidents_missing_sources; Type: VIEW; Schema: public; Owner: ctic
--

CREATE VIEW public.vw_incidents_missing_sources AS
 SELECT i.incident_id,
    o.name
   FROM ((public.incidents i
     JOIN public.organizations o USING (org_id))
     LEFT JOIN public.incident_sources s USING (incident_id))
  WHERE (s.source_id IS NULL);


ALTER TABLE public.vw_incidents_missing_sources OWNER TO ctic;

--
-- Name: vw_kpis; Type: VIEW; Schema: public; Owner: ctic
--

CREATE VIEW public.vw_kpis AS
 SELECT ( SELECT count(*) AS count
           FROM public.incidents) AS incidents_total,
    ( SELECT count(*) AS count
           FROM public.indicators) AS indicators_total,
    ( SELECT count(*) AS count
           FROM public.campaigns) AS campaigns_total,
    ( SELECT count(*) AS count
           FROM public.sightings
          WHERE (sightings.seen_on >= (CURRENT_DATE - '30 days'::interval))) AS sightings_30d;


ALTER TABLE public.vw_kpis OWNER TO ctic;

--
-- Name: vw_reporting_lag_72h; Type: VIEW; Schema: public; Owner: ctic
--

CREATE VIEW public.vw_reporting_lag_72h AS
 SELECT i.incident_id,
    o.name,
    r.name AS regime,
    i.discovered_on,
    ir.notify_date,
    (ir.notify_date - i.discovered_on) AS days_to_notify,
    ((ir.notify_date - i.discovered_on) > 3) AS overdue
   FROM (((public.incidents i
     JOIN public.organizations o USING (org_id))
     JOIN public.incident_regimes ir USING (incident_id))
     JOIN public.regimes r USING (regime_id))
  WHERE (ir.notified_flag = true);


ALTER TABLE public.vw_reporting_lag_72h OWNER TO ctic;

--
-- Name: vw_top_ttps_12m; Type: VIEW; Schema: public; Owner: ctic
--

CREATE VIEW public.vw_top_ttps_12m AS
 SELECT t.name,
    count(*) AS cnt
   FROM ((public.incident_ttps it
     JOIN public.ttps t USING (ttp_id))
     JOIN public.incidents i USING (incident_id))
  WHERE (i.discovered_on >= (CURRENT_DATE - '1 year'::interval))
  GROUP BY t.name
  ORDER BY (count(*)) DESC;


ALTER TABLE public.vw_top_ttps_12m OWNER TO ctic;

--
-- Name: campaigns campaign_id; Type: DEFAULT; Schema: public; Owner: ctic
--

ALTER TABLE ONLY public.campaigns ALTER COLUMN campaign_id SET DEFAULT nextval('public.campaigns_campaign_id_seq'::regclass);


--
-- Name: impacts impact_id; Type: DEFAULT; Schema: public; Owner: ctic
--

ALTER TABLE ONLY public.impacts ALTER COLUMN impact_id SET DEFAULT nextval('public.impacts_impact_id_seq'::regclass);


--
-- Name: incidents incident_id; Type: DEFAULT; Schema: public; Owner: ctic
--

ALTER TABLE ONLY public.incidents ALTER COLUMN incident_id SET DEFAULT nextval('public.incidents_incident_id_seq'::regclass);


--
-- Name: indicators indicator_id; Type: DEFAULT; Schema: public; Owner: ctic
--

ALTER TABLE ONLY public.indicators ALTER COLUMN indicator_id SET DEFAULT nextval('public.indicators_indicator_id_seq'::regclass);


--
-- Name: organizations org_id; Type: DEFAULT; Schema: public; Owner: ctic
--

ALTER TABLE ONLY public.organizations ALTER COLUMN org_id SET DEFAULT nextval('public.organizations_org_id_seq'::regclass);


--
-- Name: regimes regime_id; Type: DEFAULT; Schema: public; Owner: ctic
--

ALTER TABLE ONLY public.regimes ALTER COLUMN regime_id SET DEFAULT nextval('public.regimes_regime_id_seq'::regclass);


--
-- Name: sightings sighting_id; Type: DEFAULT; Schema: public; Owner: ctic
--

ALTER TABLE ONLY public.sightings ALTER COLUMN sighting_id SET DEFAULT nextval('public.sightings_sighting_id_seq'::regclass);


--
-- Name: sources source_id; Type: DEFAULT; Schema: public; Owner: ctic
--

ALTER TABLE ONLY public.sources ALTER COLUMN source_id SET DEFAULT nextval('public.sources_source_id_seq'::regclass);


--
-- Name: ttps ttp_id; Type: DEFAULT; Schema: public; Owner: ctic
--

ALTER TABLE ONLY public.ttps ALTER COLUMN ttp_id SET DEFAULT nextval('public.ttps_ttp_id_seq'::regclass);


--
-- Name: vectors vector_id; Type: DEFAULT; Schema: public; Owner: ctic
--

ALTER TABLE ONLY public.vectors ALTER COLUMN vector_id SET DEFAULT nextval('public.vectors_vector_id_seq'::regclass);


--
-- Data for Name: campaigns; Type: TABLE DATA; Schema: public; Owner: ctic
--

COPY public.campaigns (campaign_id, name) FROM stdin;
1	CloudRansom-2024
2	PhishEdu-2023
\.


--
-- Data for Name: impacts; Type: TABLE DATA; Schema: public; Owner: ctic
--

COPY public.impacts (impact_id, incident_id, amount_usd, downtime_days, notes) FROM stdin;
1	1	850000	3	IR + restore
2	2	120000	0.5	Account resets
3	3	0	\N	Open case
4	4	300000	1	Vendor remediation
\.


--
-- Data for Name: incident_indicators; Type: TABLE DATA; Schema: public; Owner: ctic
--

COPY public.incident_indicators (incident_id, indicator_id) FROM stdin;
1	2
2	3
3	1
4	4
\.


--
-- Data for Name: incident_regimes; Type: TABLE DATA; Schema: public; Owner: ctic
--

COPY public.incident_regimes (incident_id, regime_id, notified_flag, notify_date) FROM stdin;
1	2	t	2024-02-02
2	1	t	2023-11-25
3	1	f	\N
4	2	t	2024-09-10
\.


--
-- Data for Name: incident_sources; Type: TABLE DATA; Schema: public; Owner: ctic
--

COPY public.incident_sources (incident_id, source_id) FROM stdin;
1	1
2	2
3	3
4	4
\.


--
-- Data for Name: incident_ttps; Type: TABLE DATA; Schema: public; Owner: ctic
--

COPY public.incident_ttps (incident_id, ttp_id) FROM stdin;
1	1
2	1
3	3
\.


--
-- Data for Name: incident_vectors; Type: TABLE DATA; Schema: public; Owner: ctic
--

COPY public.incident_vectors (incident_id, vector_id) FROM stdin;
1	2
2	1
3	3
4	4
\.


--
-- Data for Name: incidents; Type: TABLE DATA; Schema: public; Owner: ctic
--

COPY public.incidents (incident_id, org_id, start_on, discovered_on, end_on, summary, status, severity) FROM stdin;
1	1	2024-01-10	2024-02-01	2024-02-05	Ransomware encrypted EHR	closed	high
2	2	2023-11-15	2023-11-20	2023-11-22	Phishing credential theft	closed	medium
3	3	2025-03-01	2025-03-03	\N	SQL injection customer portal	open	critical
4	4	2024-09-05	2024-09-06	2024-09-07	Vendor breach exposure	closed	medium
\.


--
-- Data for Name: indicator_campaign; Type: TABLE DATA; Schema: public; Owner: ctic
--

COPY public.indicator_campaign (indicator_id, campaign_id) FROM stdin;
2	1
3	2
1	1
\.


--
-- Data for Name: indicators; Type: TABLE DATA; Schema: public; Owner: ctic
--

COPY public.indicators (indicator_id, value, type, first_seen, last_seen, source) FROM stdin;
1	192.0.2.44	ip	2025-03-01	2025-03-02	MISP
2	deadbeefdeadbeefdeadbeefdeadbeef	hash	2025-02-11	2025-02-13	VirusTotal
3	malicious-login.net	domain	2025-01-05	2025-01-20	OpenCTI
4	203.0.113.77	ip	2024-09-06	2024-09-07	Zeek
5	198.51.100.13	ip	\N	\N	MISP
6	malicious.example	domain	\N	\N	MISP
\.


--
-- Data for Name: organizations; Type: TABLE DATA; Schema: public; Owner: ctic
--

COPY public.organizations (org_id, name, sector, size_band, country, domain) FROM stdin;
1	Acme Health	Healthcare	Large	USA	acmehealth.org
2	Metro Uni	Education	Medium	USA	metro.edu
3	Finix Bank	Finance	Large	USA	finixbank.com
4	CityGov	Public	Medium	USA	city.gov
\.


--
-- Data for Name: regimes; Type: TABLE DATA; Schema: public; Owner: ctic
--

COPY public.regimes (regime_id, name) FROM stdin;
1	GDPR
2	HIPAA
\.


--
-- Data for Name: sightings; Type: TABLE DATA; Schema: public; Owner: ctic
--

COPY public.sightings (sighting_id, indicator_id, seen_on, src_system, context) FROM stdin;
1	1	2025-03-02	Wazuh	Blocked outbound
2	2	2025-02-12	Cortex	Hash flagged
3	3	2025-01-10	Zeek	Host lookup
4	4	2024-09-07	Suricata	Alert signature match
5	5	2025-09-12	ETL-Demo	demo sighting
\.


--
-- Data for Name: sources; Type: TABLE DATA; Schema: public; Owner: ctic
--

COPY public.sources (source_id, type, url, collected_on) FROM stdin;
1	regulator	https://ocrportal.hhs.gov	2024-02-10
2	news	https://news.example/phish	2023-11-26
3	report	https://dbir.example/case-sqli	2025-03-10
4	other	https://vendor.example/notice	2024-09-12
\.


--
-- Data for Name: ttps; Type: TABLE DATA; Schema: public; Owner: ctic
--

COPY public.ttps (ttp_id, name, mitre_id) FROM stdin;
1	Valid Accounts	T1078
2	Exfiltration Over Web Service	T1567.002
3	SQL Injection	T1190
\.


--
-- Data for Name: vectors; Type: TABLE DATA; Schema: public; Owner: ctic
--

COPY public.vectors (vector_id, name) FROM stdin;
1	Phishing
2	Ransomware
3	SQL Injection
4	Third-Party
\.


--
-- Name: campaigns_campaign_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ctic
--

SELECT pg_catalog.setval('public.campaigns_campaign_id_seq', 2, true);


--
-- Name: impacts_impact_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ctic
--

SELECT pg_catalog.setval('public.impacts_impact_id_seq', 1, false);


--
-- Name: incidents_incident_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ctic
--

SELECT pg_catalog.setval('public.incidents_incident_id_seq', 4, true);


--
-- Name: indicators_indicator_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ctic
--

SELECT pg_catalog.setval('public.indicators_indicator_id_seq', 8, true);


--
-- Name: organizations_org_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ctic
--

SELECT pg_catalog.setval('public.organizations_org_id_seq', 1, false);


--
-- Name: regimes_regime_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ctic
--

SELECT pg_catalog.setval('public.regimes_regime_id_seq', 1, false);


--
-- Name: sightings_sighting_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ctic
--

SELECT pg_catalog.setval('public.sightings_sighting_id_seq', 5, true);


--
-- Name: sources_source_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ctic
--

SELECT pg_catalog.setval('public.sources_source_id_seq', 1, false);


--
-- Name: ttps_ttp_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ctic
--

SELECT pg_catalog.setval('public.ttps_ttp_id_seq', 1, false);


--
-- Name: vectors_vector_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ctic
--

SELECT pg_catalog.setval('public.vectors_vector_id_seq', 1, false);


--
-- Name: campaigns campaigns_pkey; Type: CONSTRAINT; Schema: public; Owner: ctic
--

ALTER TABLE ONLY public.campaigns
    ADD CONSTRAINT campaigns_pkey PRIMARY KEY (campaign_id);


--
-- Name: impacts impacts_incident_id_key; Type: CONSTRAINT; Schema: public; Owner: ctic
--

ALTER TABLE ONLY public.impacts
    ADD CONSTRAINT impacts_incident_id_key UNIQUE (incident_id);


--
-- Name: impacts impacts_pkey; Type: CONSTRAINT; Schema: public; Owner: ctic
--

ALTER TABLE ONLY public.impacts
    ADD CONSTRAINT impacts_pkey PRIMARY KEY (impact_id);


--
-- Name: incident_indicators incident_indicators_pkey; Type: CONSTRAINT; Schema: public; Owner: ctic
--

ALTER TABLE ONLY public.incident_indicators
    ADD CONSTRAINT incident_indicators_pkey PRIMARY KEY (incident_id, indicator_id);


--
-- Name: incident_regimes incident_regimes_pkey; Type: CONSTRAINT; Schema: public; Owner: ctic
--

ALTER TABLE ONLY public.incident_regimes
    ADD CONSTRAINT incident_regimes_pkey PRIMARY KEY (incident_id, regime_id);


--
-- Name: incident_sources incident_sources_pkey; Type: CONSTRAINT; Schema: public; Owner: ctic
--

ALTER TABLE ONLY public.incident_sources
    ADD CONSTRAINT incident_sources_pkey PRIMARY KEY (incident_id, source_id);


--
-- Name: incident_ttps incident_ttps_pkey; Type: CONSTRAINT; Schema: public; Owner: ctic
--

ALTER TABLE ONLY public.incident_ttps
    ADD CONSTRAINT incident_ttps_pkey PRIMARY KEY (incident_id, ttp_id);


--
-- Name: incident_vectors incident_vectors_pkey; Type: CONSTRAINT; Schema: public; Owner: ctic
--

ALTER TABLE ONLY public.incident_vectors
    ADD CONSTRAINT incident_vectors_pkey PRIMARY KEY (incident_id, vector_id);


--
-- Name: incidents incidents_pkey; Type: CONSTRAINT; Schema: public; Owner: ctic
--

ALTER TABLE ONLY public.incidents
    ADD CONSTRAINT incidents_pkey PRIMARY KEY (incident_id);


--
-- Name: indicator_campaign indicator_campaign_pkey; Type: CONSTRAINT; Schema: public; Owner: ctic
--

ALTER TABLE ONLY public.indicator_campaign
    ADD CONSTRAINT indicator_campaign_pkey PRIMARY KEY (indicator_id, campaign_id);


--
-- Name: indicators indicators_pkey; Type: CONSTRAINT; Schema: public; Owner: ctic
--

ALTER TABLE ONLY public.indicators
    ADD CONSTRAINT indicators_pkey PRIMARY KEY (indicator_id);


--
-- Name: indicators indicators_value_unique; Type: CONSTRAINT; Schema: public; Owner: ctic
--

ALTER TABLE ONLY public.indicators
    ADD CONSTRAINT indicators_value_unique UNIQUE (value);


--
-- Name: organizations organizations_name_key; Type: CONSTRAINT; Schema: public; Owner: ctic
--

ALTER TABLE ONLY public.organizations
    ADD CONSTRAINT organizations_name_key UNIQUE (name);


--
-- Name: organizations organizations_pkey; Type: CONSTRAINT; Schema: public; Owner: ctic
--

ALTER TABLE ONLY public.organizations
    ADD CONSTRAINT organizations_pkey PRIMARY KEY (org_id);


--
-- Name: regimes regimes_name_key; Type: CONSTRAINT; Schema: public; Owner: ctic
--

ALTER TABLE ONLY public.regimes
    ADD CONSTRAINT regimes_name_key UNIQUE (name);


--
-- Name: regimes regimes_pkey; Type: CONSTRAINT; Schema: public; Owner: ctic
--

ALTER TABLE ONLY public.regimes
    ADD CONSTRAINT regimes_pkey PRIMARY KEY (regime_id);


--
-- Name: sightings sightings_pkey; Type: CONSTRAINT; Schema: public; Owner: ctic
--

ALTER TABLE ONLY public.sightings
    ADD CONSTRAINT sightings_pkey PRIMARY KEY (sighting_id);


--
-- Name: sources sources_pkey; Type: CONSTRAINT; Schema: public; Owner: ctic
--

ALTER TABLE ONLY public.sources
    ADD CONSTRAINT sources_pkey PRIMARY KEY (source_id);


--
-- Name: ttps ttps_pkey; Type: CONSTRAINT; Schema: public; Owner: ctic
--

ALTER TABLE ONLY public.ttps
    ADD CONSTRAINT ttps_pkey PRIMARY KEY (ttp_id);


--
-- Name: vectors vectors_name_key; Type: CONSTRAINT; Schema: public; Owner: ctic
--

ALTER TABLE ONLY public.vectors
    ADD CONSTRAINT vectors_name_key UNIQUE (name);


--
-- Name: vectors vectors_pkey; Type: CONSTRAINT; Schema: public; Owner: ctic
--

ALTER TABLE ONLY public.vectors
    ADD CONSTRAINT vectors_pkey PRIMARY KEY (vector_id);


--
-- Name: impacts impacts_incident_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ctic
--

ALTER TABLE ONLY public.impacts
    ADD CONSTRAINT impacts_incident_id_fkey FOREIGN KEY (incident_id) REFERENCES public.incidents(incident_id) ON DELETE CASCADE;


--
-- Name: incident_indicators incident_indicators_incident_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ctic
--

ALTER TABLE ONLY public.incident_indicators
    ADD CONSTRAINT incident_indicators_incident_id_fkey FOREIGN KEY (incident_id) REFERENCES public.incidents(incident_id) ON DELETE CASCADE;


--
-- Name: incident_indicators incident_indicators_indicator_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ctic
--

ALTER TABLE ONLY public.incident_indicators
    ADD CONSTRAINT incident_indicators_indicator_id_fkey FOREIGN KEY (indicator_id) REFERENCES public.indicators(indicator_id) ON DELETE CASCADE;


--
-- Name: incident_regimes incident_regimes_incident_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ctic
--

ALTER TABLE ONLY public.incident_regimes
    ADD CONSTRAINT incident_regimes_incident_id_fkey FOREIGN KEY (incident_id) REFERENCES public.incidents(incident_id) ON DELETE CASCADE;


--
-- Name: incident_regimes incident_regimes_regime_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ctic
--

ALTER TABLE ONLY public.incident_regimes
    ADD CONSTRAINT incident_regimes_regime_id_fkey FOREIGN KEY (regime_id) REFERENCES public.regimes(regime_id) ON DELETE CASCADE;


--
-- Name: incident_sources incident_sources_incident_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ctic
--

ALTER TABLE ONLY public.incident_sources
    ADD CONSTRAINT incident_sources_incident_id_fkey FOREIGN KEY (incident_id) REFERENCES public.incidents(incident_id) ON DELETE CASCADE;


--
-- Name: incident_sources incident_sources_source_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ctic
--

ALTER TABLE ONLY public.incident_sources
    ADD CONSTRAINT incident_sources_source_id_fkey FOREIGN KEY (source_id) REFERENCES public.sources(source_id) ON DELETE CASCADE;


--
-- Name: incident_ttps incident_ttps_incident_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ctic
--

ALTER TABLE ONLY public.incident_ttps
    ADD CONSTRAINT incident_ttps_incident_id_fkey FOREIGN KEY (incident_id) REFERENCES public.incidents(incident_id) ON DELETE CASCADE;


--
-- Name: incident_ttps incident_ttps_ttp_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ctic
--

ALTER TABLE ONLY public.incident_ttps
    ADD CONSTRAINT incident_ttps_ttp_id_fkey FOREIGN KEY (ttp_id) REFERENCES public.ttps(ttp_id) ON DELETE CASCADE;


--
-- Name: incident_vectors incident_vectors_incident_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ctic
--

ALTER TABLE ONLY public.incident_vectors
    ADD CONSTRAINT incident_vectors_incident_id_fkey FOREIGN KEY (incident_id) REFERENCES public.incidents(incident_id) ON DELETE CASCADE;


--
-- Name: incident_vectors incident_vectors_vector_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ctic
--

ALTER TABLE ONLY public.incident_vectors
    ADD CONSTRAINT incident_vectors_vector_id_fkey FOREIGN KEY (vector_id) REFERENCES public.vectors(vector_id) ON DELETE CASCADE;


--
-- Name: incidents incidents_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ctic
--

ALTER TABLE ONLY public.incidents
    ADD CONSTRAINT incidents_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organizations(org_id) ON DELETE CASCADE;


--
-- Name: indicator_campaign indicator_campaign_campaign_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ctic
--

ALTER TABLE ONLY public.indicator_campaign
    ADD CONSTRAINT indicator_campaign_campaign_id_fkey FOREIGN KEY (campaign_id) REFERENCES public.campaigns(campaign_id) ON DELETE CASCADE;


--
-- Name: indicator_campaign indicator_campaign_indicator_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ctic
--

ALTER TABLE ONLY public.indicator_campaign
    ADD CONSTRAINT indicator_campaign_indicator_id_fkey FOREIGN KEY (indicator_id) REFERENCES public.indicators(indicator_id) ON DELETE CASCADE;


--
-- Name: sightings sightings_indicator_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ctic
--

ALTER TABLE ONLY public.sightings
    ADD CONSTRAINT sightings_indicator_id_fkey FOREIGN KEY (indicator_id) REFERENCES public.indicators(indicator_id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

\unrestrict CuBItorx3ihaE2OxN69haqQKga0HD90QLbLaL2VFZgknkbbs7ReOcHGJqm0jvcx

