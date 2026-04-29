"""
Sync Scheduler — orchestrates collection cadence.

Cadence strategy:
  - SCHEDULED matches (>2h from now):  every 6 hours
  - SCHEDULED matches (<2h from now):  every 15 minutes
  - LIVE matches:                      every 60 seconds
  - H2H / historical stats:            every 24 hours (low churn)
  - Post-match settlement:             triggered immediately after 'finished'
"""
from __future__ import annotations

import asyncio
import logging
from datetime import datetime, timedelta, timezone

from apscheduler.schedulers.asyncio import AsyncIOScheduler
from apscheduler.triggers.cron import CronTrigger
from apscheduler.triggers.interval import IntervalTrigger

from ..collectors.football_api_collector import FootballApiCollector, CollectorConfig
from ..processors.match_processor import MatchProcessor

logger = logging.getLogger(__name__)


class SyncScheduler:
    def __init__(self, config: CollectorConfig, leagues: list[int], season: int) -> None:
        self._collector = FootballApiCollector(config)
        self._processor = MatchProcessor()
        self._leagues   = leagues
        self._season    = season
        self._scheduler = AsyncIOScheduler(timezone="UTC")

    def start(self) -> None:
        # Live matches: every 60 s
        self._scheduler.add_job(
            self._sync_live,
            IntervalTrigger(seconds=60),
            id="sync_live",
            max_instances=1,
            coalesce=True,
        )
        # Upcoming matches (within 2 h): every 15 min
        self._scheduler.add_job(
            self._sync_upcoming_soon,
            IntervalTrigger(minutes=15),
            id="sync_upcoming_soon",
            max_instances=1,
            coalesce=True,
        )
        # All scheduled matches: every 6 h (metadata updates)
        self._scheduler.add_job(
            self._sync_all_scheduled,
            CronTrigger(hour="*/6"),
            id="sync_all_scheduled",
            max_instances=1,
        )
        # H2H stats: once daily at 03:00 UTC
        self._scheduler.add_job(
            self._refresh_h2h,
            CronTrigger(hour=3, minute=0),
            id="refresh_h2h",
        )

        self._scheduler.start()
        logger.info("SyncScheduler started — leagues=%s season=%s", self._leagues, self._season)

    async def _sync_live(self) -> None:
        logger.debug("Syncing live fixtures")
        for league_id in self._leagues:
            try:
                raw_matches = await self._collector.collect_live_fixtures(league_id)
                await self._upsert_matches(raw_matches)
            except Exception:
                logger.exception("Live sync failed for league %s", league_id)

    async def _sync_upcoming_soon(self) -> None:
        now       = datetime.now(timezone.utc)
        from_date = now.date()
        to_date   = (now + timedelta(hours=2)).date()
        for league_id in self._leagues:
            try:
                raw_matches = await self._collector.collect_fixtures(
                    league_id, self._season, from_date, to_date
                )
                await self._upsert_matches(raw_matches)
            except Exception:
                logger.exception("Upcoming-soon sync failed for league %s", league_id)

    async def _sync_all_scheduled(self) -> None:
        now       = datetime.now(timezone.utc)
        from_date = now.date()
        to_date   = (now + timedelta(days=7)).date()
        for league_id in self._leagues:
            try:
                raw_matches = await self._collector.collect_fixtures(
                    league_id, self._season, from_date, to_date
                )
                await self._upsert_matches(raw_matches)
            except Exception:
                logger.exception("Scheduled sync failed for league %s", league_id)

    async def _refresh_h2h(self) -> None:
        # Placeholder: fetch all upcoming match pairs and refresh H2H stats
        logger.info("Refreshing H2H stats (stub — implement with DB query for upcoming pairs)")

    async def _upsert_matches(self, raw_matches: list) -> None:
        # TODO: inject repository; stub shows processing contract
        for raw in raw_matches:
            result = self._processor.process(raw, existing=None)
            if result.status_changed or result.score_changed:
                logger.info(
                    "Match %s: status_changed=%s score_changed=%s",
                    result.match.external_id,
                    result.status_changed,
                    result.score_changed,
                )
            # emit to event bus → triggers bet settlement + ranking update

    async def shutdown(self) -> None:
        self._scheduler.shutdown()
        await self._collector.close()
