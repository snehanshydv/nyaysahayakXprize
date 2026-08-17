"""
Enhanced case management — Postgres-first with Supabase fallback.
"""
from __future__ import annotations

import json
import os
from datetime import datetime
from typing import Any, Dict, Optional

from dotenv import load_dotenv

load_dotenv()

from backend.database.postgres_pool import execute, execute_one, execute_void, is_postgres_configured

_supabase = None
if not is_postgres_configured():
    try:
        from supabase import create_client

        url = os.getenv("SUPABASE_URL")
        key = os.getenv("SUPABASE_ANON_KEY")
        if url and key:
            _supabase = create_client(url, key)
    except Exception as e:
        print(f"Warning: case enhance Supabase init failed: {e}")


def _json(value: Any) -> str:
    return json.dumps(value if value is not None else {}, default=str)


def _json_list(value: Any) -> str:
    return json.dumps(value if value is not None else [], default=str)


def save_case_with_situation_summary(
    uid: str,
    case_id: str,
    session_id: str,
    structured_report: dict,
    situation_summary: dict,
    collected_answers: dict,
    session_data: list,
    pdf_url: Optional[str] = None,
    user_language: str = "english",
) -> bool:
    enriched_report = dict(structured_report or {})
    enriched_report["completion_context"] = {
        "session_id": session_id,
        "situation_summary": situation_summary or {},
        "collected_answers": collected_answers or {},
        "user_language": user_language,
        "has_answers": len(collected_answers or {}) > 0,
        "completed_at": datetime.now().isoformat(),
    }
    user_id = str(uid).strip() if uid and str(uid).strip() else None

    if is_postgres_configured():
        try:
            execute_void(
                """
                INSERT INTO cases (
                  id, user_id, session_id, structured_report, situation_summary, collected_answers,
                  session_data, pdf_url, pdf_updated_at, pdf_generated_at, user_language, status, has_answers, timestamp
                ) VALUES (
                  %s, %s, %s, %s::jsonb, %s::jsonb, %s::jsonb, %s::jsonb, %s,
                  CASE WHEN %s IS NOT NULL THEN now() ELSE NULL END,
                  CASE WHEN %s IS NOT NULL THEN now() ELSE NULL END,
                  %s, 'completed', %s, now()
                )
                ON CONFLICT (id) DO UPDATE SET
                  user_id = EXCLUDED.user_id,
                  session_id = EXCLUDED.session_id,
                  structured_report = EXCLUDED.structured_report,
                  situation_summary = EXCLUDED.situation_summary,
                  collected_answers = EXCLUDED.collected_answers,
                  session_data = EXCLUDED.session_data,
                  pdf_url = COALESCE(EXCLUDED.pdf_url, cases.pdf_url),
                  pdf_updated_at = COALESCE(EXCLUDED.pdf_updated_at, cases.pdf_updated_at),
                  pdf_generated_at = COALESCE(EXCLUDED.pdf_generated_at, cases.pdf_generated_at),
                  user_language = EXCLUDED.user_language,
                  status = 'completed',
                  has_answers = EXCLUDED.has_answers,
                  updated_at = now()
                """,
                (
                    case_id,
                    user_id,
                    session_id,
                    _json(enriched_report),
                    _json(situation_summary or {}),
                    _json(collected_answers or {}),
                    _json_list(session_data),
                    pdf_url,
                    pdf_url,
                    pdf_url,
                    user_language,
                    len(collected_answers or {}) > 0,
                ),
            )
            return True
        except Exception as e:
            print(f"❌ Error saving case with situation summary (postgres): {e}")
            return False

    if not _supabase:
        return False
    try:
        case_data = {
            "id": case_id,
            "session_id": session_id,
            "structured_report": enriched_report,
            "situation_summary": situation_summary or {},
            "collected_answers": collected_answers or {},
            "session_data": session_data,
            "pdf_url": pdf_url,
            "pdf_updated_at": datetime.now().isoformat() if pdf_url else None,
            "pdf_generated_at": datetime.now().isoformat() if pdf_url else None,
            "user_language": user_language,
            "status": "completed",
            "has_answers": len(collected_answers or {}) > 0,
            "user_id": user_id,
        }
        response = _supabase.table("cases").upsert(case_data, on_conflict="id").execute()
        return bool(response.data)
    except Exception as e:
        print(f"❌ Error saving case with situation summary: {e}")
        return False


def update_case_with_pdf(
    case_id: str,
    pdf_url: str,
    cloudinary_folder: Optional[str] = None,
    *,
    user_id: Optional[str] = None,
    structured_report: Optional[Dict[str, Any]] = None,
) -> bool:
    """Persist pdf_url on cases. Upserts a minimal row when the case does not exist yet."""
    if is_postgres_configured():
        try:
            rows = execute(
                """
                UPDATE cases
                SET pdf_url = %s, pdf_updated_at = now(), pdf_generated_at = now(),
                    cloudinary_path = %s, updated_at = now()
                WHERE id = %s
                RETURNING id
                """,
                (pdf_url, cloudinary_folder, case_id),
            )
            if rows:
                return True
            # Case row may not exist yet (report_agent only mints a UUID) — upsert minimal row.
            if user_id:
                execute_void(
                    """
                    INSERT INTO cases (
                      id, user_id, structured_report, session_data, pending,
                      pdf_url, pdf_updated_at, pdf_generated_at, cloudinary_path, timestamp
                    ) VALUES (
                      %s, %s, %s::jsonb, '[]'::jsonb, false,
                      %s, now(), now(), %s, now()
                    )
                    ON CONFLICT (id) DO UPDATE SET
                      pdf_url = EXCLUDED.pdf_url,
                      pdf_updated_at = now(),
                      pdf_generated_at = now(),
                      cloudinary_path = EXCLUDED.cloudinary_path,
                      updated_at = now()
                    """,
                    (
                        case_id,
                        user_id,
                        json.dumps(structured_report or {}, default=str),
                        pdf_url,
                        cloudinary_folder,
                    ),
                )
                return True
            print(f"⚠️ update_case_with_pdf: no row for {case_id} and no user_id to upsert")
            return False
        except Exception as e:
            print(f"❌ Error updating case PDF (postgres): {e}")
            return False
    if not _supabase:
        return False
    try:
        response = (
            _supabase.table("cases")
            .update(
                {
                    "pdf_url": pdf_url,
                    "pdf_updated_at": datetime.now().isoformat(),
                    "pdf_generated_at": datetime.now().isoformat(),
                    "cloudinary_path": cloudinary_folder,
                }
            )
            .eq("id", case_id)
            .execute()
        )
        if response.data:
            return True
        if user_id:
            _supabase.table("cases").upsert(
                {
                    "id": case_id,
                    "user_id": user_id,
                    "structured_report": structured_report or {},
                    "session_data": [],
                    "pending": False,
                    "pdf_url": pdf_url,
                    "pdf_updated_at": datetime.now().isoformat(),
                    "pdf_generated_at": datetime.now().isoformat(),
                    "cloudinary_path": cloudinary_folder,
                }
            ).execute()
            return True
        return False
    except Exception as e:
        print(f"❌ Error updating case PDF: {e}")
        return False


def get_case_complete(case_id: str) -> Optional[Dict[str, Any]]:
    if is_postgres_configured():
        try:
            return execute_one("SELECT * FROM cases WHERE id = %s LIMIT 1", (case_id,))
        except Exception as e:
            print(f"❌ Error retrieving complete case: {e}")
            return None
    if not _supabase:
        return None
    try:
        response = _supabase.table("cases").select("*").eq("id", case_id).single().execute()
        return response.data
    except Exception as e:
        print(f"❌ Error retrieving complete case: {e}")
        return None


def get_user_cases_complete(uid: str):
    if is_postgres_configured():
        try:
            return execute("SELECT * FROM cases WHERE user_id = %s ORDER BY timestamp DESC", (uid,))
        except Exception as e:
            print(f"❌ Error retrieving user cases: {e}")
            return []
    if not _supabase:
        return []
    try:
        response = _supabase.table("cases").select("*").eq("user_id", uid).order("timestamp", desc=True).execute()
        return response.data or []
    except Exception as e:
        print(f"❌ Error retrieving user cases: {e}")
        return []


def get_case_pdf_download_info(case_id: str) -> Optional[Dict[str, str]]:
    row = get_case_complete(case_id)
    if not row or not row.get("pdf_url"):
        return None
    report = row.get("structured_report") or {}
    if isinstance(report, str):
        try:
            report = json.loads(report)
        except Exception:
            report = {}
    return {
        "download_url": row.get("pdf_url"),
        "case_type": report.get("incident_type", "Unknown") if isinstance(report, dict) else "Unknown",
        "created_at": row.get("timestamp"),
        "case_id": case_id,
    }


def search_cases_by_status(uid: str, status: str = "completed"):
    if is_postgres_configured():
        try:
            return execute(
                "SELECT * FROM cases WHERE user_id = %s AND status = %s ORDER BY timestamp DESC",
                (uid, status),
            )
        except Exception as e:
            print(f"❌ Error searching cases by status: {e}")
            return []
    if not _supabase:
        return []
    try:
        response = (
            _supabase.table("cases")
            .select("*")
            .eq("user_id", uid)
            .eq("status", status)
            .order("timestamp", desc=True)
            .execute()
        )
        return response.data or []
    except Exception as e:
        print(f"❌ Error searching cases by status: {e}")
        return []
