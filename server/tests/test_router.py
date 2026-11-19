"""ModelRouter tests. No real network.

The installed OpenAI SDK sends requests through ``httpx2`` (not ``httpx``), which respx
does not patch, so each test injects an OpenAI client whose ``httpx2.Client`` uses a
``MockTransport`` that records every request.
"""

import base64
import json

import httpx2
import pytest
from openai import OpenAI

from app.config import Settings
from app.models import TrustEvent, TrustOutcome
from app.router import (
    ConfidentialRouteUnavailable,
    ModelCallError,
    ModelRouter,
    extract_json,
)

BASE = "https://tr.test/v1"
URL = f"{BASE}/chat/completions"
PLANTED = "synthetic planted phrase zebra-umbrella-42"


def _settings(**kw) -> Settings:
    base = dict(
        bloom_mode="dev",
        trustedrouter_api_key="test-key",
        trustedrouter_base_url=BASE,
        tr_model_id="fortanix/glm-5.3-flash",
        private_model_id="",
        tr_negative_test_provider="fortanix",
    )
    base.update(kw)
    return Settings(**base)


class FakeGateway:
    """Records requests and replays queued responses (or raises queued exceptions)."""

    def __init__(self, *responses):
        self._responses = list(responses)
        self.calls: list[httpx2.Request] = []

    def __call__(self, request: httpx2.Request) -> httpx2.Response:
        self.calls.append(request)
        assert str(request.url) == URL, request.url
        nxt = self._responses[0] if len(self._responses) == 1 else self._responses.pop(0)
        if isinstance(nxt, Exception):
            raise nxt
        status, kw = nxt
        return httpx2.Response(status, **kw)

    @property
    def call_count(self) -> int:
        return len(self.calls)

    def body(self, i: int = 0) -> dict:
        return json.loads(self.calls[i].content)

    def client(self) -> OpenAI:
        http = httpx2.Client(transport=httpx2.MockTransport(self))
        return OpenAI(api_key="test-key", base_url=BASE, http_client=http)


def ok(content: str, headers: dict | None = None):
    return (200, {"json": _completion(content), "headers": headers or {}})


def err(status: int, body: dict):
    return (status, {"json": body})


def _completion(content: str, model: str = "fortanix/glm-5.3-flash") -> dict:
    return {
        "id": "gen-123",
        "object": "chat.completion",
        "created": 1,
        "model": model,
        "choices": [
            {"index": 0, "message": {"role": "assistant", "content": content}, "finish_reason": "stop"}
        ],
    }


def _b64(obj) -> str:
    return base64.urlsafe_b64encode(json.dumps(obj).encode()).decode().rstrip("=")


def _receipt(claims: dict) -> str:
    return f"{_b64({'alg': 'ES256', 'typ': 'JWT'})}.{_b64(claims)}.sig"


REFUSAL_400 = {
    "error": {
        "type": "bad_request",
        "code": "confidential_privacy_required",
        "message": "No route meets min_privacy=confidential",
    }
}


def _router(gw: FakeGateway, settings: Settings, events: list):
    return ModelRouter(settings, client=gw.client(), on_event=events.append)


# ------------------------------------------------------------------- dev mode


def test_dev_mode_sends_zdr_floor_no_fallbacks_and_model():
    route = FakeGateway(ok('{"ok": true}'))
    events: list[TrustEvent] = []
    text, event = _router(route, _settings(), events).complete(
        [{"role": "user", "content": "hi"}], node="intake", session_id="s1"
    )

    assert route.call_count == 1
    body = route.body()
    assert body["model"] == "fortanix/glm-5.3-flash"
    assert body["provider"] == {"min_privacy": "zdr", "allow_fallbacks": False}
    assert body["response_format"] == {"type": "json_object"}  # TR_JSON_MODE default on
    assert body["temperature"] == 0.2  # TR_TEMPERATURE default
    assert route.calls[0].headers["x-inference-receipt"] == "true"
    assert json.loads(text) == {"ok": True}
    assert event.outcome == TrustOutcome.OK
    assert event.mode == "dev" and event.policy_required == "zdr"
    assert event.node == "intake" and event.session_id == "s1"
    assert event.latency_ms is not None and event.latency_ms >= 0
    assert events == [event]


def test_receipt_and_headers_land_in_evidence():
    receipt = _receipt({
        "rv": 1, "iss": "https://api.trustedrouter.com", "jti": "resp-9", "gen": "gen-9",
        "route": "zdr", "model": {"requested": "fortanix/glm-5.3-flash", "provider": "fortanix"},
        "req": "aa" * 32, "resp": "bb" * 32,
    })
    route = FakeGateway(ok('{"a": 1}', {"x-inference-receipt": receipt, "x-generation-id": "gen-9", "x-request-id": "req-1"}))
    _, event = _router(route, _settings(), []).complete([{"role": "user", "content": "hi"}], node="n")
    assert event.request_id == "req-1"
    assert event.route == "fortanix"
    assert event.evidence["headers"]["x-generation-id"] == "gen-9"
    assert event.evidence["receipt"]["claims"]["jti"] == "resp-9"
    assert event.evidence["receipt"]["signature_verified"] is False
    assert event.evidence["receipt"]["jws"] == receipt


def test_dev_json_parse_failure_retries_once_then_errors():
    route = FakeGateway(ok("not json"))
    events: list[TrustEvent] = []
    with pytest.raises(ModelCallError) as info:
        _router(route, _settings(), events).complete([{"role": "user", "content": "x"}], node="n")
    assert route.call_count == 2
    assert info.value.event.outcome == TrustOutcome.ERROR
    assert [e.outcome for e in events] == [TrustOutcome.ERROR, TrustOutcome.ERROR]


def test_dev_json_retry_succeeds_on_second_attempt():
    route = FakeGateway(ok("oops"), ok('```json\n{"b": 2}\n```'))
    text, event = _router(route, _settings(), []).complete([{"role": "user", "content": "x"}], node="n")
    assert route.call_count == 2
    assert json.loads(text) == {"b": 2}
    assert event.outcome == TrustOutcome.OK


def test_dev_non_json_mode_returns_text():
    route = FakeGateway(ok("plain words"))
    text, _ = _router(route, _settings(), []).complete(
        [{"role": "user", "content": "x"}], node="n", json_mode=False
    )
    assert text == "plain words"


def test_dev_route_rejection_400_is_refused_without_retry():
    route = FakeGateway(err(400, REFUSAL_400))
    events: list[TrustEvent] = []
    with pytest.raises(ConfidentialRouteUnavailable) as info:
        _router(route, _settings(), events).complete([{"role": "user", "content": "x"}], node="n")
    assert route.call_count == 1
    assert info.value.event.outcome == TrustOutcome.REFUSED
    assert len(events) == 1


def test_dev_unrelated_400_is_error():
    route = FakeGateway(err(400, {"error": {"type": "bad_request", "message": "context_length_exceeded"}}))
    with pytest.raises(ModelCallError) as info:
        _router(route, _settings(), []).complete([{"role": "user", "content": "x"}], node="n")
    assert route.call_count == 1
    assert info.value.event.outcome == TrustOutcome.ERROR


def test_server_error_is_not_retried():
    route = FakeGateway(err(500, {"error": {"message": "down"}}))
    events: list[TrustEvent] = []
    with pytest.raises(ModelCallError) as info:
        _router(route, _settings(), events).complete([{"role": "user", "content": "x"}], node="n")
    assert route.call_count == 1
    assert info.value.event.evidence["http_status"] == 500
    assert len(events) == 1


@pytest.mark.parametrize("status", [429, 503, 529])
def test_dev_overload_is_retried_once_on_same_model(status):
    route = FakeGateway(err(status, {"error": {"message": "System is overloaded"}}), ok('{"ok": true}'))
    events: list[TrustEvent] = []
    router = _router(route, _settings(), events)
    router._overload_backoff_s = 0
    text, event = router.complete([{"role": "user", "content": "x"}], node="n")
    assert text == '{"ok": true}'
    assert route.call_count == 2
    assert [json.loads(c.content)["model"] for c in route.calls] == ["fortanix/glm-5.3-flash"] * 2
    assert [e.outcome for e in events] == [TrustOutcome.ERROR, TrustOutcome.OK]


def test_dev_overload_gives_up_after_one_retry():
    route = FakeGateway(err(529, {"error": {"message": "System is overloaded"}}))
    router = _router(route, _settings(), [])
    router._overload_backoff_s = 0
    with pytest.raises(ModelCallError):
        router.complete([{"role": "user", "content": "x"}], node="n")
    assert route.call_count == 2


def test_private_overload_is_never_retried():
    route = FakeGateway(err(529, {"error": {"message": "System is overloaded"}}))
    router = _router(route, _settings(bloom_mode="private", private_model_id="conf/model"), [])
    router._overload_backoff_s = 0
    with pytest.raises((ModelCallError, ConfidentialRouteUnavailable)):
        router.complete([{"role": "user", "content": "x"}], node="n")
    assert route.call_count == 1


def test_connection_error_is_model_call_error():
    route = FakeGateway(httpx2.ConnectError("boom"))
    with pytest.raises(ModelCallError) as info:
        _router(route, _settings(), []).complete([{"role": "user", "content": "x"}], node="n")
    assert route.call_count == 1
    assert info.value.event.outcome == TrustOutcome.ERROR


# --------------------------------------------------------------- private mode


def test_private_mode_without_model_raises_with_zero_http_calls():
    route = FakeGateway(ok("{}"))
    events: list[TrustEvent] = []
    router = _router(route, _settings(bloom_mode="private", private_model_id=""), events)
    with pytest.raises(ConfidentialRouteUnavailable) as info:
        router.complete([{"role": "user", "content": "x"}], node="n")
    assert route.call_count == 0
    assert info.value.event.outcome == TrustOutcome.REFUSED
    assert info.value.event.policy_required == "confidential"
    assert len(events) == 1


def test_private_mode_400_refusal_fails_closed_with_exactly_one_call():
    """F8: a refusal in private mode never leads to a second model call."""
    route = FakeGateway(err(400, {"error": {"message": "nope"}}))
    events: list[TrustEvent] = []
    router = _router(route, _settings(bloom_mode="private", private_model_id="conf/model-x"), events)
    with pytest.raises(ConfidentialRouteUnavailable) as info:
        router.complete([{"role": "user", "content": "x"}], node="brief")
    assert route.call_count == 1
    body = route.body()
    assert body["model"] == "conf/model-x"
    assert body["provider"] == {"min_privacy": "confidential", "allow_fallbacks": False}
    assert info.value.event.outcome == TrustOutcome.REFUSED
    assert info.value.event.mode == "private"
    assert len(events) == 1 and events[0] is info.value.event


def test_private_mode_json_parse_failure_does_not_retry():
    route = FakeGateway(ok("not json"))
    router = _router(route, _settings(bloom_mode="private", private_model_id="conf/model-x"), [])
    with pytest.raises(ModelCallError):
        router.complete([{"role": "user", "content": "x"}], node="n")
    assert route.call_count == 1


# -------------------------------------------------------------- negative test


def test_negative_test_makes_one_call_and_returns_refused():
    route = FakeGateway(err(400, REFUSAL_400))
    events: list[TrustEvent] = []
    event = _router(route, _settings(), events).negative_test("s1")
    assert route.call_count == 1
    body = route.body()
    assert body["model"] == "fortanix/glm-5.3-flash"
    assert body["provider"] == {"min_privacy": "confidential", "allow_fallbacks": False, "only": ["fortanix"]}
    assert event.outcome == TrustOutcome.REFUSED
    assert event.node == "negative_test" and event.session_id == "s1"
    assert event.evidence["error_code"] == "confidential_privacy_required"
    assert events == [event]


def test_negative_test_served_is_reported_as_error():
    route = FakeGateway(ok("pong"))
    event = _router(route, _settings(), []).negative_test(None)
    assert route.call_count == 1
    assert event.outcome == TrustOutcome.ERROR
    assert event.evidence["error"] == "expected_refusal_but_served"


# ----------------------------------------------------------- no text in event


def test_trust_event_never_contains_message_or_output_text():
    receipt = _receipt({"jti": "r1", "echo": PLANTED})  # even a receipt echoing text
    route = FakeGateway(ok(json.dumps({"summary": PLANTED}), {"x-inference-receipt": receipt}))
    events: list[TrustEvent] = []
    _, event = _router(route, _settings(), events).complete(
        [{"role": "system", "content": "Return JSON."}, {"role": "user", "content": PLANTED}],
        node="n",
    )
    assert PLANTED not in event.model_dump_json()
    assert all(PLANTED not in e.model_dump_json() for e in events)


def test_error_event_drops_gateway_message_that_echoes_prompt():
    route = FakeGateway(err(400, {"error": {"message": f"bad input: {PLANTED}"}}))
    router = _router(route, _settings(bloom_mode="private", private_model_id="conf/m"), [])
    with pytest.raises(ConfidentialRouteUnavailable) as info:
        router.complete([{"role": "user", "content": PLANTED}], node="n")
    assert PLANTED not in info.value.event.model_dump_json()


# ------------------------------------------------------------------- helpers


def test_extract_json_variants():
    assert extract_json('{"a": 1}') == '{"a": 1}'
    assert json.loads(extract_json('Here: {"a": 1} done')) == {"a": 1}
    assert json.loads(extract_json('```json\n{"a": 1}\n```')) == {"a": 1}
    assert extract_json("[1, 2]") is None
    assert extract_json("nothing") is None


def test_reasoning_effort_sent_when_configured_and_omitted_when_empty():
    route = FakeGateway(ok('{"ok": true}'))
    _router(route, _settings(tr_reasoning_effort="low"), []).complete(
        [{"role": "user", "content": "hi"}], node="intake", session_id="s1"
    )
    assert route.body()["reasoning"] == {"effort": "low"}

    route = FakeGateway(ok('{"ok": true}'))
    _router(route, _settings(tr_reasoning_effort=""), []).complete(
        [{"role": "user", "content": "hi"}], node="intake", session_id="s1"
    )
    assert "reasoning" not in route.body()


def test_extract_json_prefers_the_last_complete_object():
    from app.router import extract_json
    assert extract_json('Draft: {"reply": "a"} Final: {"reply": "b", "done": false}') == '{"reply": "b", "done": false}'
    assert extract_json('{bad} then {"ok": 1}') == '{"ok": 1}'
    assert extract_json("```json\n{\"a\": 3}\n```") == '{"a": 3}'
    assert extract_json("no json here") is None


# ------------------------------------------- json_object mode and repair (2026-11-19)

JSON_MODE_400 = {"error": {"type": "bad_request", "code": "unsupported_parameter",
                           "message": "No endpoint supports response_format json_object"}}


def test_json_mode_400_retries_once_without_it_and_remembers():
    route = FakeGateway(err(400, JSON_MODE_400), ok('{"a": 1}'), ok('{"b": 2}'))
    events: list[TrustEvent] = []
    router = _router(route, _settings(), events)
    text, event = router.complete([{"role": "user", "content": "x"}], node="intake")
    assert json.loads(text) == {"a": 1}
    assert route.call_count == 2
    assert route.body(0)["response_format"] == {"type": "json_object"}
    assert "response_format" not in route.body(1)
    assert router.json_mode_rejected is True
    assert event.evidence["json_mode"] == "dropped_after_400" and event.evidence["parse_path"] == "first_pass"
    assert events[0].outcome == TrustOutcome.ERROR and events[0].evidence["json_mode"] == "rejected"
    router.complete([{"role": "user", "content": "x"}], node="intake")
    assert route.call_count == 3 and "response_format" not in route.body(2)  # remembered


def test_json_mode_documented_privacy_refusal_is_not_retried():
    route = FakeGateway(err(400, REFUSAL_400))
    router = _router(route, _settings(), [])
    with pytest.raises(ConfidentialRouteUnavailable):
        router.complete([{"role": "user", "content": "x"}], node="n")
    assert route.call_count == 1 and router.json_mode_rejected is False


def test_json_mode_400_then_another_400_is_not_remembered():
    route = FakeGateway(err(400, JSON_MODE_400), err(400, {"error": {"message": "no route for this provider"}}))
    router = _router(route, _settings(), [])
    with pytest.raises(ConfidentialRouteUnavailable):
        router.complete([{"role": "user", "content": "x"}], node="n")
    assert route.call_count == 2 and router.json_mode_rejected is False


def test_json_mode_flag_off_and_private_mode_never_send_response_format():
    route = FakeGateway(ok('{"a": 1}'))
    _router(route, _settings(tr_json_mode=False), []).complete([{"role": "user", "content": "x"}], node="n")
    assert "response_format" not in route.body(0)
    route = FakeGateway(ok('{"a": 1}'))
    _router(route, _settings(bloom_mode="private", private_model_id="conf/m"), []).complete(
        [{"role": "user", "content": "x"}], node="n")
    assert "response_format" not in route.body(0)


def test_repair_call_sends_the_bad_output_back_and_reports_the_path():
    from app.router import REPAIR_INSTRUCTION
    route = FakeGateway(ok("Sure! How old are you?"), ok('{"a": 1}'))
    events: list[TrustEvent] = []
    text, event = _router(route, _settings(), events).complete([{"role": "user", "content": "x"}], node="n")
    assert json.loads(text) == {"a": 1}
    msgs = route.body(1)["messages"]
    assert msgs[-2] == {"role": "assistant", "content": "Sure! How old are you?"}
    assert msgs[-1] == {"role": "user", "content": REPAIR_INSTRUCTION}
    assert event.evidence["parse_path"] == "repair"
    assert events[0].evidence["error"] == "json_parse_failed" and events[0].evidence["attempt"] == 1


def test_repair_is_skipped_when_the_turn_budget_is_low():
    route = FakeGateway(ok("prose"))
    router = _router(route, _settings(), [])
    with router.deadline(5.0):
        with pytest.raises(ModelCallError) as info:
            router.complete([{"role": "user", "content": "x"}], node="n")
    assert route.call_count == 1
    assert info.value.event.evidence["repair_skipped"] == "turn_budget_low"


def test_validate_picks_the_last_object_that_matches_the_shape():
    route = FakeGateway(ok('{"reply": "draft", "extracted": {}} then {"note": 1}'))

    def validate(t):
        if "reply" not in json.loads(t):
            raise ValueError("shape")

    text, event = _router(route, _settings(), []).complete(
        [{"role": "user", "content": "x"}], node="n", validate=validate)
    assert json.loads(text)["reply"] == "draft" and route.call_count == 1


def test_schema_failure_after_repair_reports_schema_validation_failed():
    route = FakeGateway(ok('{"nope": 1}'))

    def validate(t):
        raise ValueError("shape")

    with pytest.raises(ModelCallError) as info:
        _router(route, _settings(), []).complete([{"role": "user", "content": "x"}], node="n", validate=validate)
    assert route.call_count == 2 and info.value.event.evidence["error"] == "schema_validation_failed"
