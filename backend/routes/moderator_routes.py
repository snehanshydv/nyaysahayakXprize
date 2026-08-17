"""Moderator ops APIs: mine queue, stats, history."""
from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, Query
from starlette.concurrency import run_in_threadpool

import backend.database.supabase_db as supabase_db
from backend.database.auth_middleware import require_roles
from backend.services import moderator_queue

router = APIRouter(prefix="/api", tags=["moderator"])


def _uid(user: dict) -> str:
    return str(user.get("id") or user.get("uid") or user.get("firebase_uid") or "")


@router.get("/moderator/stats")
async def moderator_stats(user=Depends(require_roles("moderator", "admin", "super_admin"))):
    uid = _uid(user)
    if not uid:
        raise HTTPException(status_code=401, detail="Missing user id")
    stats = await run_in_threadpool(moderator_queue.moderator_stats_for, uid)
    return {"status": "success", **stats}


@router.get("/interventions/moderator/mine")
async def my_interventions(user=Depends(require_roles("moderator", "admin", "super_admin"))):
    uid = _uid(user)
    if not uid:
        raise HTTPException(status_code=401, detail="Missing user id")
    await run_in_threadpool(moderator_queue.try_claim_unassigned_for, uid)
    cases = await run_in_threadpool(
        supabase_db.get_assigned_interventions_for_moderator, uid, False
    )
    stats = await run_in_threadpool(moderator_queue.moderator_stats_for, uid)
    return {"status": "success", "cases": cases, "stats": stats}


@router.get("/interventions/moderator/history")
async def my_intervention_history(
    limit: int = Query(50, ge=1, le=100),
    user=Depends(require_roles("moderator", "admin", "super_admin")),
):
    uid = _uid(user)
    cases = await run_in_threadpool(
        supabase_db.get_assigned_interventions_for_moderator, uid, True
    )
    return {"status": "success", "cases": (cases or [])[:limit]}
