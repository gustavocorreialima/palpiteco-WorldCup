"""
Match Processor — transforms raw API data into DB-ready records.

Pipeline flow:
  Collector → Processor → Repository (upsert) → Event Bus (if state changed)

Idempotency guarantee: every write uses ON CONFLICT (external_id) DO UPDATE
so replaying the same payload is safe.
"""
from __future__ import annotations

import logging
from dataclasses import dataclass
from datetime import datetime, timezone
from typing import Literal

from ..models.raw import RawMatch
from ..models.domain import DomainMatch, MatchStatus
from ..utils.status_mapper import map_api_status

logger = logging.getLogger(__name__)

StatusTransition = tuple[MatchStatus, MatchStatus]

# Allowed forward transitions — prevents stale data from rolling back a result
VALID_TRANSITIONS: set[StatusTransition] = {
    ("scheduled", "live"),
    ("scheduled", "finished"),
    ("scheduled", "postponed"),
    ("scheduled", "cancelled"),
    ("live",      "finished"),
    ("live",      "postponed"),
    ("postponed", "scheduled"),
    ("postponed", "cancelled"),
}


@dataclass
class ProcessResult:
    match: DomainMatch
    is_new: bool
    status_changed: bool
    score_changed: bool


class MatchProcessor:
    """
    Converts RawMatch → DomainMatch, enforcing:
    - Forward-only status transitions (no 'finished' → 'live' rollback)
    - Score only updates when status is 'live' or 'finished'
    - data_version bump on every meaningful change
    """

    def process(
        self,
        raw: RawMatch,
        existing: DomainMatch | None,
    ) -> ProcessResult:
        new_status = map_api_status(raw.status)

        if existing is None:
            return ProcessResult(
                match=self._build_new(raw, new_status),
                is_new=True,
                status_changed=False,
                score_changed=False,
            )

        status_changed = self._apply_status(existing, new_status)
        score_changed  = self._apply_score(existing, raw, new_status)

        if status_changed or score_changed:
            existing.data_version += 1
            existing.synced_at = datetime.now(timezone.utc)

        return ProcessResult(
            match=existing,
            is_new=False,
            status_changed=status_changed,
            score_changed=score_changed,
        )

    # ------------------------------------------------------------------

    def _build_new(self, raw: RawMatch, status: MatchStatus) -> DomainMatch:
        return DomainMatch(
            external_id    = raw.external_id,
            competition_id = raw.competition_id,
            home_team_id   = raw.home_team_id,
            away_team_id   = raw.away_team_id,
            kickoff_at     = datetime.fromisoformat(raw.kickoff_at),
            status         = status,
            venue_name     = raw.venue_name,
            referee_name   = raw.referee,
            home_score_ft  = raw.home_score_ft if status in ("live", "finished") else None,
            away_score_ft  = raw.away_score_ft if status in ("live", "finished") else None,
            home_score_ht  = raw.home_score_ht,
            away_score_ht  = raw.away_score_ht,
            data_version   = 1,
            synced_at      = datetime.now(timezone.utc),
        )

    def _apply_status(self, match: DomainMatch, new: MatchStatus) -> bool:
        if match.status == new:
            return False
        if (match.status, new) not in VALID_TRANSITIONS:
            logger.warning(
                "Blocked invalid transition %s → %s for external_id=%s",
                match.status, new, match.external_id,
            )
            return False
        match.status = new
        return True

    def _apply_score(
        self, match: DomainMatch, raw: RawMatch, status: MatchStatus
    ) -> bool:
        if status not in ("live", "finished"):
            return False

        changed = False
        for field, value in [
            ("home_score_ft", raw.home_score_ft),
            ("away_score_ft", raw.away_score_ft),
            ("home_score_ht", raw.home_score_ht),
            ("away_score_ht", raw.away_score_ht),
        ]:
            if value is not None and getattr(match, field) != value:
                setattr(match, field, value)
                changed = True
        return changed
