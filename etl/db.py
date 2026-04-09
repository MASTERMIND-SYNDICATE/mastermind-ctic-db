"""Database helpers shared across ETL jobs.

Provides a connection factory and table-bootstrap logic so that ETL
scripts can run before the full schema migration has been applied.
"""

from __future__ import annotations

import logging
from typing import Any

import psycopg2
import psycopg2.extras

from etl import config

log = logging.getLogger(__name__)


def get_connection() -> Any:
    """Return a new psycopg2 connection using environment config."""
    return psycopg2.connect(
        host=config.PG_HOST,
        port=config.PG_PORT,
        dbname=config.PG_DATABASE,
        user=config.PG_USER,
        password=config.PG_PASSWORD,
    )


def ensure_tables(conn: Any) -> None:
    """Create the minimum tables the ETL pipeline requires.

    These CREATE IF NOT EXISTS statements are a safety net for first-run
    scenarios where the full schema migration has not yet been applied.
    """
    with conn, conn.cursor() as cur:
        cur.execute("""
            CREATE TABLE IF NOT EXISTS public.indicators (
                indicator_id BIGSERIAL PRIMARY KEY,
                value        TEXT UNIQUE NOT NULL,
                type         TEXT NOT NULL,
                source       TEXT NOT NULL DEFAULT 'manual',
                first_seen   TIMESTAMPTZ,
                last_seen    TIMESTAMPTZ,
                ocsf         JSONB
            );
        """)
        cur.execute("""
            CREATE TABLE IF NOT EXISTS public.sightings (
                sighting_id       BIGSERIAL PRIMARY KEY,
                indicator_id      BIGINT NOT NULL
                    REFERENCES public.indicators(indicator_id) ON DELETE CASCADE,
                seen_on           DATE NOT NULL DEFAULT CURRENT_DATE,
                src_system        TEXT,
                context           JSONB,
                match_fingerprint TEXT,
                ocsf              JSONB
            );
        """)
        cur.execute("""
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
        """)
    log.debug("ETL tables verified.")
