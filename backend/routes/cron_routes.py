"""Unauthenticated-by-JWT cron endpoints secured with ``CRON_SECRET``.

Cloud Scheduler wakes the scale-to-zero Cloud Run service and runs scheduled
background work (case clustering). Without this, nothing runs while the
backend is asleep.
"""
from __future__ import annotations

import hmac
import os

from fastapi import APIRouter, Header, HTTPException

from backend.services import scam_case_classifier
from backend.services import moderator_queue

router = APIRouter(prefix="/api/cron", tags=["cron"])


def _require_cron_secret(x_cron_secret: str | None) -> None:
    expected = (os.getenv("CRON_SECRET") or "").strip()
    if not expected:
        raise HTTPException(status_code=503, detail="CRON_SECRET not configured on this service")
    provided = (x_cron_secret or "").strip()
    if not provided or not hmac.compare_digest(provided, expected):
        raise HTTPException(status_code=401, detail="Invalid cron secret")


@router.post("/scam-classifier/tick")
async def cron_scam_classifier_tick(x_cron_secret: str | None = Header(default=None)):
    """Enqueue classifier if due, then process inside this request (wakes Cloud Run)."""
    _require_cron_secret(x_cron_secret)
    try:
        run = scam_case_classifier.tick_schedule_and_process(sync=True)
        return {
            "success": True,
            "run": run,
            "config": scam_case_classifier.get_config(),
        }
    except Exception as exc:  # noqa: BLE001
        raise HTTPException(status_code=500, detail=str(exc)) from exc


@router.get("/health")
async def cron_health(x_cron_secret: str | None = Header(default=None)):
    _require_cron_secret(x_cron_secret)
    return {"ok": True, "service": "cron"}


@router.post("/moderator-sla/tick")
async def cron_moderator_sla_tick(x_cron_secret: str | None = Header(default=None)):
    """Apply delay/respect ticks for overdue exclusive moderator assignments."""
    _require_cron_secret(x_cron_secret)
    try:
        result = moderator_queue.run_sla_delay_ticks()
        return {"success": True, **result, "config": moderator_queue.get_queue_config()}
    except Exception as exc:  # noqa: BLE001
        raise HTTPException(status_code=500, detail=str(exc)) from exc
