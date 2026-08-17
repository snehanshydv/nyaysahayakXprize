"""Per-graph legal RAG retrieval thresholds (top_k + min_similarity).

Stored in ``system_config`` under key ``rag_retrieval``. Separate from the RAG
funnel ingest settings (``rag_funnel``).
"""
from __future__ import annotations

from copy import deepcopy
from typing import Any

from backend.services import admin_models

RAG_RETRIEVAL_CONFIG_KEY = "rag_retrieval"

# Match historical hardcoded defaults
DEFAULT_CHAT_TOP_K = 10
DEFAULT_CLASH_TOP_K = 5
TOP_K_MIN = 1
TOP_K_MAX = 30

GRAPH_IDS = ("chat_agent", "clash_agent")

GRAPH_LABELS = {
    "chat_agent": "Chat agent",
    "clash_agent": "Clash agent",
}


def default_rag_retrieval_config() -> dict[str, Any]:
    return {
        "chat_agent": {"top_k": DEFAULT_CHAT_TOP_K, "min_similarity": 0.0},
        "clash_agent": {"top_k": DEFAULT_CLASH_TOP_K, "min_similarity": 0.0},
    }


def _clamp_top_k(value: Any, fallback: int) -> int:
    try:
        n = int(value)
    except (TypeError, ValueError):
        return fallback
    return max(TOP_K_MIN, min(TOP_K_MAX, n))


def _clamp_min_similarity(value: Any) -> float:
    try:
        n = float(value)
    except (TypeError, ValueError):
        return 0.0
    if n <= 0:
        return 0.0
    return max(0.0, min(1.0, n))


def _normalize_graph_settings(raw: Any, *, default_top_k: int) -> dict[str, Any]:
    base = {"top_k": default_top_k, "min_similarity": 0.0}
    if not isinstance(raw, dict):
        return base
    return {
        "top_k": _clamp_top_k(raw.get("top_k"), default_top_k),
        "min_similarity": _clamp_min_similarity(raw.get("min_similarity")),
    }


def get_rag_retrieval_config() -> dict[str, Any]:
    """Defaults merged with stored system_config (clamped)."""
    defaults = default_rag_retrieval_config()
    stored = admin_models.read_config_key(RAG_RETRIEVAL_CONFIG_KEY, {})
    out: dict[str, Any] = {}
    for gid in GRAPH_IDS:
        default_top = int(defaults[gid]["top_k"])
        out[gid] = _normalize_graph_settings(stored.get(gid), default_top_k=default_top)
    return out


def get_rag_retrieval_settings(graph_id: str) -> dict[str, Any]:
    """Resolve ``{top_k, min_similarity}`` for a graph id."""
    cfg = get_rag_retrieval_config()
    gid = (graph_id or "chat_agent").strip()
    if gid not in cfg:
        gid = "chat_agent"
    return deepcopy(cfg[gid])


def save_rag_retrieval_config(body: dict[str, Any]) -> dict[str, Any]:
    """Validate, persist, and return the normalized config."""
    defaults = default_rag_retrieval_config()
    current = get_rag_retrieval_config()
    if not isinstance(body, dict):
        raise ValueError("Body must be a JSON object")
    merged = deepcopy(current)
    for gid in GRAPH_IDS:
        if gid not in body:
            continue
        default_top = int(defaults[gid]["top_k"])
        merged[gid] = _normalize_graph_settings(body.get(gid), default_top_k=default_top)
    admin_models.write_config_key(RAG_RETRIEVAL_CONFIG_KEY, merged)
    return get_rag_retrieval_config()


def filter_rows_by_similarity(
    rows: list | None,
    min_similarity: float,
) -> list:
    """Drop rows below min_similarity when threshold > 0. Rows without a score are kept."""
    if not rows or not min_similarity or min_similarity <= 0:
        return list(rows or [])
    out = []
    for row in rows:
        if not isinstance(row, dict):
            continue
        sim = row.get("similarity")
        if sim is None:
            out.append(row)
            continue
        try:
            if float(sim) >= float(min_similarity):
                out.append(row)
        except (TypeError, ValueError):
            out.append(row)
    return out
