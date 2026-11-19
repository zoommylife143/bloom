"""DEV-ONLY offline stand-in for TrustedRouter (``BLOOM_FAKE_MODEL=1``).

Purpose: run the real server (real graph, store, router, red-flag rules, trust events)
with no API keys, so the Flutter apps and the API contract check can be exercised
locally. It is OFF by default, refused in private mode (``build_services`` raises), and
reported by ``GET /api/healthz`` as ``fake_model: true``. Never use it for a demo.

The fake answers at the HTTP level, so ``ModelRouter`` runs its normal code path:

* intake  -> a fixed question list; fixed synthetic fields (never patient text);
  ``done`` after the third patient turn.
* brief   -> a fixed synthetic draft that cites the first guideline URL in the prompt.
* a request with ``min_privacy="confidential"`` (the D05 negative test) -> HTTP 400
  ``confidential_privacy_required``, the documented refusal.

Bad-model simulation (tests, and local runs of ``scripts/live_check.py`` against a fake
server): ``FakeGateway(garbage_rate=..., reject_json_mode=...)``, or the dev-only env
vars ``BLOOM_FAKE_GARBAGE_RATE`` (0..1) and ``BLOOM_FAKE_REJECT_JSON_MODE=1``.

* ``garbage_rate``: share of JSON calls (intake, brief and repair calls) answered with
  unusable output, cycling through ``GARBAGE_KINDS``: prose that imitates a chat reply,
  truncated JSON, and JSON of the wrong shape. Decided by a seeded RNG, so a run is
  reproducible.
* ``reject_json_mode``: a request carrying ``response_format`` gets HTTP 400 (as a
  gateway with no route supporting it would answer).
"""

from __future__ import annotations

import json
import random
import re

import httpx2
from openai import OpenAI

from app.prompts import BRIEF_SYSTEM_PROMPT, INTAKE_SYSTEM_PROMPT
from app.router import REPAIR_INSTRUCTION

FAKE_MODEL_ID = "bloom-fake/offline"
FAKE_BASE_URL = "https://fake-gateway.invalid/v1"

_QUESTIONS = (
    "Thank you. Which age group are you in: 18-24, 25-29, 30-39, 40-49, 50-64 or 65+?",
    "Thanks. Is there any chance you could be pregnant right now? You can say yes, no or not sure.",
)
# Synthetic fields, added one turn at a time. Nothing is copied from patient text.
_FIELDS = (
    {"reason_for_visit": "routine gynecology visit (offline fake model)"},
    {"age_band": "30-39", "last_pap_hpv": "2019"},
    {"pregnancy_possible": "no", "pregnant_or_postpartum": "neither", "bleeding_pattern": "irregular"},
)
_JSON_MODE_400 = {"error": {"type": "bad_request", "code": "unsupported_parameter",
                            "message": "No endpoint supports response_format json_object (offline fake gateway)"}}
GARBAGE_KINDS = ("prose", "partial_json", "wrong_shape")
_GARBAGE = {
    "prose": "Thank you for telling me that. Could you tell me a little more about how you have been feeling?",
    "partial_json": '{"reply": "Thanks. Which age group are you in", "extracted": {"age_band": "30-',
    "wrong_shape": '{"answer": "Thanks for sharing.", "fields": []}',
}
_REFUSAL = {"error": {"type": "bad_request", "code": "confidential_privacy_required",
                      "message": "No route meets min_privacy=confidential (offline fake gateway)"}}


def _completion(model: str, content: str) -> dict:
    return {
        "id": "gen-fake-offline", "object": "chat.completion", "created": 1, "model": model,
        "choices": [{"index": 0, "message": {"role": "assistant", "content": content}, "finish_reason": "stop"}],
    }


class FakeGateway:
    """The offline gateway. Callable as an httpx2 ``MockTransport`` handler."""

    def __init__(self, *, garbage_rate: float = 0.0, reject_json_mode: bool = False, seed: int = 7):
        self.garbage_rate = max(0.0, min(1.0, garbage_rate))
        self.reject_json_mode = reject_json_mode
        self._rng = random.Random(seed)
        self._kind = 0
        # One entry per HTTP call: (node, outcome) with outcome "ok", a garbage kind,
        # "json_mode_400" or "refused". No message text is kept.
        self.calls: list[tuple[str, str]] = []

    def _garbage(self) -> str | None:
        if self.garbage_rate <= 0 or self._rng.random() >= self.garbage_rate:
            return None
        kind = GARBAGE_KINDS[self._kind % len(GARBAGE_KINDS)]
        self._kind += 1
        return kind

    def __call__(self, request: httpx2.Request) -> httpx2.Response:
        body = json.loads(request.content)
        model = body.get("model") or FAKE_MODEL_ID
        msgs = body.get("messages") or []
        system = msgs[0]["content"] if msgs else ""
        node = "intake" if system == INTAKE_SYSTEM_PROMPT else "brief" if system == BRIEF_SYSTEM_PROMPT else "other"
        if (body.get("provider") or {}).get("min_privacy") == "confidential" or node == "other":
            self.calls.append((node, "refused"))
            return httpx2.Response(400, json=_REFUSAL)
        if self.reject_json_mode and "response_format" in body:
            self.calls.append((node, "json_mode_400"))
            return httpx2.Response(400, json=_JSON_MODE_400)
        kind = self._garbage()
        if kind is not None:
            self.calls.append((node, kind))
            return httpx2.Response(200, json=_completion(model, _GARBAGE[kind]))
        self.calls.append((node, "ok"))
        if node == "intake":
            # Patient turns only: a repair call adds one more "user" message.
            turn = sum(1 for m in msgs if m["role"] == "user" and m["content"] != REPAIR_INSTRUCTION)
            extracted: dict = {}
            for fields in _FIELDS[: min(turn, len(_FIELDS))]:
                extracted.update(fields)
            done = turn >= len(_FIELDS)
            reply = "Thank you." if done else _QUESTIONS[min(turn, len(_QUESTIONS)) - 1]
            out = {"reply": reply, "extracted": extracted, "done": done}
            return httpx2.Response(200, json=_completion(model, json.dumps(out)))
        user = next((m["content"] for m in msgs[1:] if m["role"] == "user"), "")
        urls = re.findall(r"URL: (\S+)", user)
        brief = {
            "subjective": "Synthetic offline draft: patient requests a routine gynecology visit.",
            "objective": "Patient-reported data only; no exam yet.",
            "assessment_considerations": "Physician to consider routine screening intervals.",
            "plan_considerations": "Consider screening per guideline.",
            "flags": [],
            "screenings_possibly_due": (
                [{"text": "Cervical screening may be due", "source_url": urls[0]}] if urls
                else [{"text": "No guideline retrieved", "source_url": None}]
            ),
            "suggested_questions": ["When was your last screening?"],
        }
        return httpx2.Response(200, json=_completion(model, json.dumps(brief)))

    def count(self, node: str | None = None, outcome: str | None = None) -> int:
        return sum(1 for n, o in self.calls if (node is None or n == node) and (outcome is None or o == outcome))


def handle(request: httpx2.Request) -> httpx2.Response:
    """The default, well-behaved gateway (clean JSON on every call)."""
    return FakeGateway()(request)


def fake_client(gateway: FakeGateway | None = None) -> OpenAI:
    """An OpenAI client whose transport is the offline fake gateway."""
    return OpenAI(api_key="fake-offline", base_url=FAKE_BASE_URL,
                  http_client=httpx2.Client(transport=httpx2.MockTransport(gateway or FakeGateway())))


def fake_attestation() -> dict:
    return {"status": "unavailable", "issuer": None, "audience": None, "verified_claims": False,
            "fetched_at": None, "error": "offline fake model (BLOOM_FAKE_MODEL=1)"}
