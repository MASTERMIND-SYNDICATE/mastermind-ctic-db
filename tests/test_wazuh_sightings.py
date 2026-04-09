"""Tests for etl/wazuh_sightings.py helper functions."""

from etl.wazuh_sightings import build_ocsf_sighting


class TestBuildOcsfSighting:
    def test_returns_ocsf_event(self, sample_wazuh_event):
        result = build_ocsf_sighting(sample_wazuh_event, "192.168.1.1", "ip-dst", 42)
        assert result["event_class_id"] == 1002
        assert result["category"] == "threat detection"
        assert result["observable"]["value"] == "192.168.1.1"
        assert result["observable"]["type"] == "ip-dst"
        assert result["indicator_id"] == 42

    def test_includes_raw_event(self, sample_wazuh_event):
        result = build_ocsf_sighting(sample_wazuh_event, "evil.com", "domain", 7)
        assert result["data"]["timestamp"] == "2025-01-01T00:00:00Z"

    def test_handles_invalid_json(self):
        result = build_ocsf_sighting("not-json", "1.2.3.4", "ip-dst", 1)
        assert result["data"] == {}
        assert result["observable"]["value"] == "1.2.3.4"
