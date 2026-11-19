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
    tr_model_id: str = "fortanix/glm-5.3-flash"
    # Model used in private mode. Empty until NYTE names a confidential route.
    private_model_id: str = ""
    # Provider slug used to pin the negative test (verify in the hello-world call).
    tr_negative_test_provider: str = "fortanix"

    context_dev_api_key: str = ""
    guideline_domains: str = "acog.org,uspreventiveservicestaskforce.org,cdc.gov"

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
