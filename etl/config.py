"""Centralised configuration loaded from environment variables.

All ETL modules import their settings from this module rather than
reading ``os.environ`` directly.  Defaults are suitable for the
Docker Compose development stack.
"""

from __future__ import annotations

import os

# ---------------------------------------------------------------------------
# PostgreSQL
# ---------------------------------------------------------------------------

PG_HOST: str = os.getenv("PGHOST", "postgres")
PG_PORT: int = int(os.getenv("PGPORT", "5432"))
PG_DATABASE: str = os.getenv("PGDATABASE", "cticdb")
PG_USER: str = os.getenv("PGUSER", "ctic")
PG_PASSWORD: str = os.getenv("PGPASSWORD", "")

# ---------------------------------------------------------------------------
# MISP
# ---------------------------------------------------------------------------

MISP_URL: str = os.getenv("MISP_URL", "")
MISP_KEY: str = os.getenv("MISP_KEY", "")
MISP_VERIFY_SSL: bool = os.getenv("MISP_VERIFY_SSL", "false").lower() == "true"
MISP_TAGS: str = os.getenv("MISP_TAGS", "")
MISP_SINCE_DAYS: int = int(os.getenv("MISP_SINCE_DAYS", "7"))
MISP_LIMIT: int = int(os.getenv("MISP_LIMIT", "100"))

# ---------------------------------------------------------------------------
# Wazuh
# ---------------------------------------------------------------------------

WAZUH_URL: str = os.getenv("WAZUH_URL", "")
WAZUH_USER: str = os.getenv("WAZUH_USER", "")
WAZUH_PASS: str = os.getenv("WAZUH_PASS", "")
WAZUH_INSECURE: bool = os.getenv("WAZUH_INSECURE", "false").lower() == "true"
WAZUH_QUERY_MINUTES: int = int(os.getenv("WAZUH_QUERY_MINUTES", "60"))
WAZUH_LIMIT: int = int(os.getenv("WAZUH_LIMIT", "500"))
WAZUH_SRC: str = os.getenv("WAZUH_SRC", "wazuh")

# ---------------------------------------------------------------------------
# ETL runtime
# ---------------------------------------------------------------------------

ETL_INTERVAL_SEC: int = int(os.getenv("ETL_INTERVAL_SEC", "300"))
WZ_MOCK_PATH: str = os.getenv("WZ_MOCK_PATH", "etl/mock/wz.json")
