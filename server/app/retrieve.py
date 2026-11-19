"""Guideline retrieval through Context.dev, restricted to the guideline domain allowlist.

Context.dev API used (confirmed from https://docs.context.dev/api-reference/web-scraping/search.md
and https://docs.context.dev/search/filters.md, 2026-11-19):

- Endpoint: ``POST https://api.context.dev/v1/web/search``
- Auth: ``Authorization: Bearer <CONTEXT_DEV_API_KEY>``, ``Content-Type: application/json``
- Body: ``{"query": str (1-500 chars), "numResults": int (1-100),
  "includeDomains": [str, ...] (allowlist, up to 100), "descriptionMaxCharacters": int}``
- Response 200: ``{"results": [{"url", "title", "description", "relevance", ...}],
  "query", "cache_metadata": {"status", "age_ms"}, "request_id", "partial", "key_metadata"}``.
  The request ID is also in the ``X-Request-Id`` header. Errors carry
  ``{"message", "error_code", "request_id"}`` with 400/401/402/403/408/429/500.

The docs do not say whether ``includeDomains`` matches subdomains, so every result is
also filtered here by URL host (exact host or a subdomain of an allowlisted host), on
fresh responses and on cache reads alike.

The sponsor runbook mentions the Context.dev Python SDK; this module uses plain httpx
(already a dependency) so tests can mock it with respx.

Only de-identified queries are sent: ``search`` runs ``assert_deidentified`` first and
sends nothing if it fails. The metadata event never contains passage text.
"""

from __future__ import annotations

import hashlib
import json
import logging
import time
from datetime import datetime
from pathlib import Path
from typing import Any
from urllib.parse import urlparse

import httpx

from app.config import Settings
from app.deidentify import NotDeidentifiedError, assert_deidentified
from app.models import EvidenceItem, TrustOutcome, utcnow

log = logging.getLogger(__name__)

SEARCH_URL = "https://api.context.dev/v1/web/search"
TIMEOUT_S = 10.0
PASSAGE_MAX_CHARS = 600
# Shared with the scenario fixtures so demos spend no credits.
DEFAULT_CACHE_DIR = Path(__file__).resolve().parents[2] / "scenarios" / "evidence-cache"
NO_GUIDELINE = "No guideline retrieved"


def cache_key(query: str) -> str:
    """Stable cache file stem for a query (sha256 of the whitespace-normalized query)."""
    norm = " ".join(query.split())
    return hashlib.sha256(norm.encode("utf-8")).hexdigest()


def host_allowed(url: str, domains: list[str]) -> bool:
    """True if `url` is http(s) and its host is an allowlisted domain or a subdomain of one."""
    try:
        parsed = urlparse(url)
    except ValueError:
        return False
    if parsed.scheme not in ("http", "https"):
        return False
    host = (parsed.hostname or "").lower().rstrip(".")
    if not host:
        return False
    for d in domains:
        d = d.lower().strip().rstrip(".")
        if d and (host == d or host.endswith("." + d)):
            return True
    return False


class GuidelineRetriever:
    """Search Context.dev for guideline passages. Never raises into the graph."""

    def __init__(
        self,
        settings: Settings,
        http: httpx.Client | None = None,
        cache_dir: Path | None = None,
    ) -> None:
        self.settings = settings
        self.http = http
        self.cache_dir = cache_dir if cache_dir is not None else DEFAULT_CACHE_DIR
        self.last_event: dict[str, Any] | None = None

    # --- public ------------------------------------------------------------------

    def search(self, query: str, *, max_results: int = 3) -> list[EvidenceItem]:
        """Return up to `max_results` allowlisted passages; `[]` on any failure.

        The TrustEvent-style metadata for this call is left in `self.last_event`.
        """
        items, event = self.search_with_event(query, max_results=max_results)
        return items

    def search_with_event(
        self, query: str, *, max_results: int = 3
    ) -> tuple[list[EvidenceItem], dict[str, Any]]:
        """Like `search`, and also return the metadata event (no passage text).

        Event keys: node, route, policy_required, model_id, request_id, latency_ms,
        outcome (TrustOutcome value), evidence {cache, status_code, result_count,
        dropped_off_allowlist, error}. The graph adds session_id and mode.
        """
        start = time.perf_counter()
        event: dict[str, Any] = {
            "node": "retrieve",
            "route": "context.dev",
            "policy_required": "deidentified_query",
            "model_id": None,
            "request_id": None,
            "latency_ms": None,
            "outcome": TrustOutcome.OK.value,
            "evidence": {"cache": "miss"},
        }
        items: list[EvidenceItem] = []
        try:
            items = self._search(query, max_results, event)
        except NotDeidentifiedError as exc:
            event["outcome"] = TrustOutcome.REFUSED.value
            event["evidence"]["error"] = str(exc)  # names the identifier type only
        except Exception as exc:  # never raise into the graph
            event["outcome"] = TrustOutcome.ERROR.value
            event["evidence"]["error"] = type(exc).__name__
            log.warning("guideline retrieval failed: %s", type(exc).__name__)
            items = []
        event["latency_ms"] = int((time.perf_counter() - start) * 1000)
        event["evidence"]["result_count"] = len(items)
        self.last_event = event
        return items, event

    # --- internals ---------------------------------------------------------------

    def _search(self, query: str, max_results: int, event: dict[str, Any]) -> list[EvidenceItem]:
        assert_deidentified(query)
        domains = self.settings.guideline_domain_list

        cached = self._read_cache(query)
        if cached is not None:
            event["evidence"]["cache"] = "fixture" if cached.get("fixture") else "hit"
            event["request_id"] = cached.get("request_id")
            return self._to_items(query, cached.get("results", []), domains, max_results, event)

        if not self.settings.context_dev_api_key:
            event["outcome"] = TrustOutcome.ERROR.value
            event["evidence"]["error"] = "no_api_key"
            return []

        body = {
            "query": query,
            "numResults": min(10, max(3, max_results * 3)),
            "includeDomains": domains,
            "descriptionMaxCharacters": PASSAGE_MAX_CHARS,
        }
        headers = {
            "Authorization": f"Bearer {self.settings.context_dev_api_key}",
            "Content-Type": "application/json",
        }
        if self.http is not None:
            res = self.http.post(SEARCH_URL, json=body, headers=headers, timeout=TIMEOUT_S)
        else:
            with httpx.Client(timeout=TIMEOUT_S) as client:
                res = client.post(SEARCH_URL, json=body, headers=headers)

        event["evidence"]["status_code"] = res.status_code
        event["request_id"] = res.headers.get("x-request-id")
        try:
            data = res.json()
        except ValueError:
            data = {}
        if isinstance(data, dict) and data.get("request_id"):
            event["request_id"] = str(data["request_id"])
        if res.status_code != 200 or not isinstance(data, dict):
            event["outcome"] = TrustOutcome.ERROR.value
            code = data.get("error_code") if isinstance(data, dict) else None
            event["evidence"]["error"] = str(code or f"http_{res.status_code}")
            return []

        results = [
            {
                "url": r.get("url", ""),
                "title": r.get("title") or None,
                "passage": (r.get("description") or "")[:PASSAGE_MAX_CHARS],
            }
            for r in data.get("results") or []
            if isinstance(r, dict)
        ]
        kept = [r for r in results if r["passage"] and host_allowed(r["url"], domains)]
        self._write_cache(query, kept, event["request_id"])
        return self._to_items(query, results, domains, max_results, event)

    def _to_items(
        self,
        query: str,
        results: list[dict[str, Any]],
        domains: list[str],
        max_results: int,
        event: dict[str, Any],
    ) -> list[EvidenceItem]:
        items: list[EvidenceItem] = []
        dropped = 0
        for r in results:
            url = str(r.get("url") or "")
            passage = str(r.get("passage") or "").strip()
            if not host_allowed(url, domains):
                dropped += 1
                continue
            if not passage:
                continue
            retrieved = r.get("retrieved_at")
            items.append(
                EvidenceItem(
                    query=query,
                    url=url,
                    title=r.get("title"),
                    passage=passage[:PASSAGE_MAX_CHARS],
                    retrieved_at=datetime.fromisoformat(retrieved) if retrieved else utcnow(),
                )
            )
        event["evidence"]["dropped_off_allowlist"] = dropped
        return items[:max_results]

    def _cache_path(self, query: str) -> Path:
        return self.cache_dir / f"{cache_key(query)}.json"

    def _read_cache(self, query: str) -> dict[str, Any] | None:
        path = self._cache_path(query)
        try:
            data = json.loads(path.read_text(encoding="utf-8"))
        except (OSError, ValueError):
            return None
        if not isinstance(data, dict) or " ".join(str(data.get("query", "")).split()) != " ".join(
            query.split()
        ):
            return None
        return data

    def _write_cache(self, query: str, results: list[dict[str, Any]], request_id: str | None) -> None:
        now = utcnow().isoformat()
        payload = {
            "query": query,
            "fixture": False,
            "request_id": request_id,
            "cached_at": now,
            "results": [{**r, "retrieved_at": now} for r in results],
        }
        try:
            self.cache_dir.mkdir(parents=True, exist_ok=True)
            self._cache_path(query).write_text(json.dumps(payload, indent=2), encoding="utf-8")
        except OSError:
            log.warning("could not write evidence cache")
