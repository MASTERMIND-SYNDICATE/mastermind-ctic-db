"""Shared fixtures for Open-CTIC tests."""

import pytest


@pytest.fixture()
def sample_misp_attr():
    """Return a minimal MISP attribute dict."""
    return {
        "type": "ip-dst",
        "value": "192.168.1.1",
        "timestamp": "1700000000",
    }


@pytest.fixture()
def sample_wazuh_event():
    """Return a minimal Wazuh alert JSON string."""
    return '{"timestamp":"2025-01-01T00:00:00Z","rule":{"id":"100001"}}'
