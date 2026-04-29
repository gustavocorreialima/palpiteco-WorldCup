"""
Football API Collector — integrates with API-Football (RapidAPI).
Responsible for fetching raw data and pushing to the processing queue.
Idempotent: safe to re-run; uses external_id as upsert key.
"""
from __future__ import annotations

import asyncio
import logging
from dataclasses import dataclass
from datetime import date, timedelta
from typing import Any

import httpx
from tenacity import retry, stop_after_attempt, wait_exponential

from ..models.raw import RawMatch, RawTeam, RawCompetition
from ..utils.circuit_breaker import CircuitBreaker

logger = logging.getLogger(__name__)

RATE_LIMIT_DELAY = 0.34   # API-Football free: 3 req/s → ~0.34 s between calls


@dataclass
class CollectorConfig:
    api_key: str
    base_url: str = "https://v3.football.api-sports.io"
    timeout_s: float = 10.0
    max_retries: int = 3


class FootballApiCollector:
    """
    Fetches matches, teams, and competition data from API-Football.
    All methods return domain models, not raw dicts — callers never
    touch the external schema directly.
    """

    def __init__(self, config: CollectorConfig) -> None:
        self._cfg = config
        self._breaker = CircuitBreaker(failure_threshold=5, recovery_timeout_s=60)
        self._client = httpx.AsyncClient(
            base_url=config.base_url,
            headers={"x-rapidapi-key": config.api_key},
            timeout=config.timeout_s,
        )

    # ------------------------------------------------------------------
    # PUBLIC API
    # ------------------------------------------------------------------

    async def collect_fixtures(
        self,
        league_id: int,
        season: int,
        from_date: date | None = None,
        to_date: date | None = None,
    ) -> list[RawMatch]:
        params: dict[str, Any] = {"league": league_id, "season": season}
        if from_date:
            params["from"] = from_date.isoformat()
        if to_date:
            params["to"] = to_date.isoformat()

        data = await self._get("/fixtures", params)
        return [self._parse_fixture(f) for f in data.get("response", [])]

    async def collect_live_fixtures(self, league_id: int) -> list[RawMatch]:
        data = await self._get("/fixtures", {"live": "all", "league": league_id})
        return [self._parse_fixture(f) for f in data.get("response", [])]

    async def collect_head_to_head(
        self, team_a: int, team_b: int, last_n: int = 10
    ) -> list[RawMatch]:
        data = await self._get(
            "/fixtures/headtohead",
            {"h2h": f"{team_a}-{team_b}", "last": last_n},
        )
        return [self._parse_fixture(f) for f in data.get("response", [])]

    async def collect_teams(self, league_id: int, season: int) -> list[RawTeam]:
        data = await self._get("/teams", {"league": league_id, "season": season})
        return [self._parse_team(t) for t in data.get("response", [])]

    # ------------------------------------------------------------------
    # PRIVATE — HTTP + Retry
    # ------------------------------------------------------------------

    @retry(
        stop=stop_after_attempt(3),
        wait=wait_exponential(multiplier=1, min=2, max=10),
        reraise=True,
    )
    async def _get(self, endpoint: str, params: dict[str, Any]) -> dict[str, Any]:
        if self._breaker.is_open:
            raise RuntimeError(f"Circuit breaker open for {endpoint}")

        try:
            await asyncio.sleep(RATE_LIMIT_DELAY)
            response = await self._client.get(endpoint, params=params)
            response.raise_for_status()
            self._breaker.record_success()
            return response.json()
        except httpx.HTTPStatusError as exc:
            self._breaker.record_failure()
            logger.error("HTTP %s on %s: %s", exc.response.status_code, endpoint, exc)
            raise
        except httpx.RequestError as exc:
            self._breaker.record_failure()
            logger.error("Network error on %s: %s", endpoint, exc)
            raise

    # ------------------------------------------------------------------
    # PRIVATE — Parsers (isolates external schema)
    # ------------------------------------------------------------------

    @staticmethod
    def _parse_fixture(raw: dict[str, Any]) -> RawMatch:
        fixture = raw["fixture"]
        teams   = raw["teams"]
        goals   = raw.get("goals") or {}
        score   = raw.get("score") or {}
        ht      = (score.get("halftime") or {})

        return RawMatch(
            external_id   = fixture["id"],
            competition_id= raw["league"]["id"],
            home_team_id  = teams["home"]["id"],
            away_team_id  = teams["away"]["id"],
            kickoff_at    = fixture["date"],
            status        = fixture["status"]["short"],
            venue_name    = (fixture.get("venue") or {}).get("name"),
            referee       = fixture.get("referee"),
            home_score_ft = goals.get("home"),
            away_score_ft = goals.get("away"),
            home_score_ht = ht.get("home"),
            away_score_ht = ht.get("away"),
        )

    @staticmethod
    def _parse_team(raw: dict[str, Any]) -> RawTeam:
        t = raw["team"]
        return RawTeam(
            external_id = t["id"],
            name        = t["name"],
            short_name  = t.get("code"),
            logo_url    = t.get("logo"),
            country     = t.get("country"),
        )

    async def close(self) -> None:
        await self._client.aclose()
