"""Server configuration. Values come only from the environment (.env via Docker Compose).

The mode is decided here, on the server, and never by the client (CLAUDE.md).
"""

from functools import lru_cache
from typing import Literal

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=None, extra="ignore")

    # dev   -> TrustedRouter GLM route with min_privacy="zdr"
    # private -> only a route tagged "confidential"; fails closed, never falls back
    bloom_mode: Literal["dev", "private"] = "dev"

    trustedrouter_api_key: str = ""
    trustedrouter_base_url: str = "https://api.trustedrouter.com/v1"
    # z-ai route: the fortanix route returned provider errors on 2026-11-19.
    tr_model_id: str = "z-ai/glm-5.3-flash"
    # Seconds per model HTTP call, and wall-clock budget for all model calls in one patient
    # turn (intake + brief, including retries). The budget keeps one POST .../messages under
    # the nginx /api/ read timeout (180 s): worst case is about turn_budget_s plus guideline
    # retrieval (Context.dev, 10 s per query) plus a few seconds of overhead.
    tr_timeout_s: float = 60.0
    # Sampling temperature for model calls. Default 0.2: a low value cuts the intake's JSON
    # format failures (seen live on 2026-11-19 with no temperature sent).
    tr_temperature: float | None = 0.2
    # Dev mode: send response_format={"type": "json_object"} on JSON calls. If the gateway
    # answers 400 to it, the call is retried once without it and, when that works, the
    # process stops sending it (ModelRouter remembers). Never sent in private mode.
    tr_json_mode: bool = True
    # Deterministic, non-AI fallbacks when the model answered but its output was unusable
    # (intake: next fixed question + rule extraction; brief: a labelled DRAFT built from
    # the IntakeRecord). They send nothing anywhere, so they apply in both modes; they never
    # run after a refusal or an HTTP error. Set BLOOM_DETERMINISTIC_FALLBACK=0 to turn off.
    bloom_deterministic_fallback: bool = True
    turn_budget_s: float = 110.0
    # Reasoning effort sent to reasoning models ("" sends none). "low" keeps latency down.
    tr_reasoning_effort: str = "low"
    # Model used in private mode. Empty until NYTE names a confidential route.
    private_model_id: str = ""
    # Provider slug used to pin the negative test (verify in the hello-world call).
    tr_negative_test_provider: str = "fortanix"

    context_dev_api_key: str = ""
    guideline_domains: str = "acog.org,uspreventiveservicestaskforce.org,cdc.gov"
    # Monitor webhook signing secret(s) (webhook.secret from POST /v1/monitors), comma-separated.
    # Empty -> the webhook answers 503 (fails closed).
    context_dev_webhook_secret: str = ""

    # DEV-ONLY: answer model calls with the offline fake gateway (app/fake_gateway.py) so the
    # server runs without keys for local contract checks. Off by default; refused in private mode.
    bloom_fake_model: bool = False
    # DEV-ONLY, with BLOOM_FAKE_MODEL=1: simulate a badly behaved model (fake_gateway.py).
    bloom_fake_garbage_rate: float = 0.0
    bloom_fake_reject_json_mode: bool = False

    database_url: str = "sqlite:///./bloom.db"
    demo_login_secret: str = ""

    @property
    def guideline_domain_list(self) -> list[str]:
        return [d.strip() for d in self.guideline_domains.split(",") if d.strip()]

    @property
    def sqlite_path(self) -> str:
        return self.database_url.removeprefix("sqlite:///")


@lru_cache
def get_settings() -> Settings:
    return Settings()
