"""Tests for etl/misp_pull.py helper functions."""

from etl.misp_pull import build_ocsf_indicator, normalise_type


class TestNormaliseType:
    def test_known_types(self):
        assert normalise_type("ip-dst") == "ip-dst"
        assert normalise_type("domain") == "domain"
        assert normalise_type("sha256") == "sha256"

    def test_alias_types(self):
        assert normalise_type("uri") == "url"
        assert normalise_type("fqdn") == "hostname"

    def test_unknown_returns_none(self):
        assert normalise_type("unknown-type") is None
        assert normalise_type("") is None

    def test_case_insensitive(self):
        assert normalise_type("IP-DST") == "ip-dst"
        assert normalise_type("Domain") == "domain"


class TestBuildOcsfIndicator:
    def test_returns_ocsf_event(self, sample_misp_attr):
        result = build_ocsf_indicator(sample_misp_attr)
        assert result["event_class_id"] == 1003
        assert result["observable"]["value"] == "192.168.1.1"
        assert result["observable"]["type"] == "ip-dst"
        assert result["source"] == "misp"
        assert result["category"] == "threat intelligence"

    def test_preserves_raw_data(self, sample_misp_attr):
        result = build_ocsf_indicator(sample_misp_attr)
        assert result["data"] == sample_misp_attr
