import json

import httpx
import pytest
import respx

from app.config import Settings
from app.models import TrustOutcome
from app.retrieve import SEARCH_URL, GuidelineRetriever, cache_key, host_allowed

QUERY = "cervical cancer screening interval age 30-39"
DOMAINS = ["acog.org", "uspreventiveservicestaskforce.org", "cdc.gov"]


def settings(key: str = "test-key") -> Settings:
    return Settings(context_dev_api_key=key, guideline_domains=",".join(DOMAINS))


def api_response(results, request_id="req-123"):
    return httpx.Response(
        200,
        json={
            "results": results,
            "query": QUERY,
            "cache_metadata": {"status": "miss", "age_ms": 0},
            "request_id": request_id,
            "partial": False,
        },
        headers={"X-Request-Id": request_id},
    )


def result(url, desc="Screen every 3 years with cytology.", title="Guideline"):
    return {"url": url, "title": title, "description": desc, "relevance": "high"}


@pytest.mark.parametrize(
    ("url", "ok"),
    [
        ("https://www.cdc.gov/cervical-cancer/screening/index.html", True),
        ("https://cdc.gov/x", True),
        ("https://www.acog.org/clinical", True),
        ("https://www.uspreventiveservicestaskforce.org/uspstf/x", True),
        ("https://evilcdc.gov/x", False),
        ("https://cdc.gov.example.test/x", False),
        ("https://example.test/?u=cdc.gov", False),
        ("ftp://cdc.gov/x", False),
        ("not a url", False),
    ],
)
def test_host_allowed(url, ok):
    assert host_allowed(url, DOMAINS) is ok


@respx.mock
def test_search_filters_domains_and_sends_filter(tmp_path):
    route = respx.post(SEARCH_URL).mock(
        return_value=api_response(
            [
                result("https://blog.example.test/cervical"),
                result("https://www.cdc.gov/cervical-cancer/screening/index.html"),
                result("https://www.uspreventiveservicestaskforce.org/uspstf/recommendation/cervical"),
            ]
        )
    )
    r = GuidelineRetriever(settings(), cache_dir=tmp_path)
    items, event = r.search_with_event(QUERY)
    urls = [i.url for i in items]
    assert urls == [
        "https://www.cdc.gov/cervical-cancer/screening/index.html",
        "https://www.uspreventiveservicestaskforce.org/uspstf/recommendation/cervical",
    ]
    assert all(i.query == QUERY and i.passage for i in items)
    sent = json.loads(route.calls[0].request.content)
    assert sent["query"] == QUERY and sent["includeDomains"] == DOMAINS
    assert route.calls[0].request.headers["authorization"] == "Bearer test-key"
    assert event["node"] == "retrieve"
    assert event["outcome"] == TrustOutcome.OK.value
    assert event["request_id"] == "req-123"
    assert event["evidence"]["dropped_off_allowlist"] == 1
    assert isinstance(event["latency_ms"], int)
    assert "Screen every 3 years" not in json.dumps(event)  # no passage text in metadata
    assert r.last_event == event


@respx.mock
def test_max_results(tmp_path):
    respx.post(SEARCH_URL).mock(
        return_value=api_response([result(f"https://www.cdc.gov/p{i}") for i in range(5)])
    )
    assert len(GuidelineRetriever(settings(), cache_dir=tmp_path).search(QUERY, max_results=2)) == 2


@respx.mock
def test_cache_hit_makes_no_http_call(tmp_path):
    route = respx.post(SEARCH_URL).mock(
        return_value=api_response([result("https://www.cdc.gov/cervical")])
    )
    r = GuidelineRetriever(settings(), cache_dir=tmp_path)
    first = r.search(QUERY)
    assert route.call_count == 1
    assert (tmp_path / f"{cache_key(QUERY)}.json").exists()
    second, event = r.search_with_event(QUERY)
    assert route.call_count == 1
    assert event["evidence"]["cache"] == "hit"
    assert [i.url for i in second] == [i.url for i in first]


@respx.mock
def test_cache_read_still_filters_domains(tmp_path):
    route = respx.post(SEARCH_URL)
    (tmp_path / f"{cache_key(QUERY)}.json").write_text(
        json.dumps(
            {
                "query": QUERY,
                "fixture": True,
                "results": [
                    {"url": "https://example.test/x", "title": "t", "passage": "p"},
                    {"url": "https://www.acog.org/y", "title": "t", "passage": "p"},
                ],
            }
        )
    )
    items = GuidelineRetriever(settings(), cache_dir=tmp_path).search(QUERY)
    assert [i.url for i in items] == ["https://www.acog.org/y"]
    assert route.call_count == 0


@respx.mock
@pytest.mark.parametrize("status", [401, 402, 429, 500])
def test_api_error_returns_empty(tmp_path, status):
    respx.post(SEARCH_URL).mock(
        return_value=httpx.Response(status, json={"message": "x", "error_code": "E", "request_id": "r9"})
    )
    r = GuidelineRetriever(settings(), cache_dir=tmp_path)
    items, event = r.search_with_event(QUERY)
    assert items == []
    assert event["outcome"] == TrustOutcome.ERROR.value
    assert event["request_id"] == "r9"
    assert not (tmp_path / f"{cache_key(QUERY)}.json").exists()


@respx.mock
def test_network_error_returns_empty(tmp_path):
    respx.post(SEARCH_URL).mock(side_effect=httpx.ConnectTimeout("boom"))
    items, event = GuidelineRetriever(settings(), cache_dir=tmp_path).search_with_event(QUERY)
    assert items == [] and event["outcome"] == TrustOutcome.ERROR.value


@respx.mock
def test_no_key_returns_empty_without_call(tmp_path):
    route = respx.post(SEARCH_URL)
    items, event = GuidelineRetriever(settings(key=""), cache_dir=tmp_path).search_with_event(QUERY)
    assert items == [] and route.call_count == 0
    assert event["evidence"]["error"] == "no_api_key"


@respx.mock
def test_identifying_query_is_never_sent(tmp_path):
    route = respx.post(SEARCH_URL)
    items, event = GuidelineRetriever(settings(), cache_dir=tmp_path).search_with_event(
        "screening for zq@example.test"
    )
    assert items == [] and route.call_count == 0
    assert event["outcome"] == TrustOutcome.REFUSED.value
    assert "example.test" not in json.dumps(event)


@respx.mock
def test_injected_client_is_used(tmp_path):
    respx.post(SEARCH_URL).mock(return_value=api_response([result("https://www.cdc.gov/a")]))
    with httpx.Client() as client:
        items = GuidelineRetriever(settings(), http=client, cache_dir=tmp_path).search(QUERY)
    assert len(items) == 1


@respx.mock
def test_repo_fixtures_serve_without_network():
    route = respx.post(SEARCH_URL)
    r = GuidelineRetriever(settings(key=""))  # default cache dir: scenarios/evidence-cache
    s1 = r.search("cervical cancer screening interval age 30-39 last test over 3 years")
    s4 = r.search("heavy menstrual bleeding evaluation age 40-49")
    assert s1 and s1[0].url.startswith("https://www.uspreventiveservicestaskforce.org/")
    assert s4 and s4[0].url.startswith("https://www.cdc.gov/")
    assert r.last_event["evidence"]["cache"] == "fixture"
    assert route.call_count == 0
