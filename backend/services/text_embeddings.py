"""Query/document embeddings: Nyaysahayak HTTP API or Google gemini-embedding-001."""
from __future__ import annotations

import json
import math
from typing import Literal

import requests

from backend.services.admin_models import GEMINI_EMBEDDING_MODEL, get_embedding_config

EmbedTask = Literal["RETRIEVAL_QUERY", "RETRIEVAL_DOCUMENT"]

_GOOGLE_BATCH = 16


def _l2_normalize(values: list[float]) -> list[float]:
    norm = math.sqrt(sum(v * v for v in values))
    if norm <= 0:
        return values
    return [v / norm for v in values]


def _fit_dim(values: list[float], dim: int) -> list[float]:
    cleaned = [float(v) for v in values]
    if len(cleaned) >= dim:
        cleaned = cleaned[:dim]
    else:
        cleaned = cleaned + [0.0] * (dim - len(cleaned))
    return _l2_normalize(cleaned)


def _embed_nyaysahayak(texts: list[str], dim: int, cfg: dict) -> list[list[float]]:
    url = cfg.get("embed_texts_url") or ""
    if not url:
        raise RuntimeError("Nyaysahayak embed-texts URL is not configured")
    resp = requests.post(
        url,
        headers={"Content-Type": "application/json; charset=utf-8"},
        data=json.dumps({"texts": texts, "normalize": True}, ensure_ascii=False).encode("utf-8"),
        timeout=60,
    )
    resp.raise_for_status()
    body = resp.json() or {}
    embeddings = body.get("embeddings") or []
    out: list[list[float]] = []
    for row in embeddings:
        if isinstance(row, list) and row:
            out.append(_fit_dim(row, dim))
    if len(out) != len(texts):
        raise RuntimeError(f"Nyaysahayak embed returned {len(out)} vectors for {len(texts)} texts")
    return out


def _extract_google_vectors(response: object) -> list[list[float]]:
    rows: list[list[float]] = []
    embeddings = getattr(response, "embeddings", None)
    if embeddings:
        for item in embeddings:
            values = getattr(item, "values", None)
            if values:
                rows.append([float(v) for v in values])
        return rows
    # dict-shaped SDK / REST fallback
    if isinstance(response, dict):
        for item in response.get("embeddings") or []:
            values = item.get("values") if isinstance(item, dict) else None
            if values:
                rows.append([float(v) for v in values])
    return rows


def _embed_google(texts: list[str], dim: int, model: str, task_type: EmbedTask) -> list[list[float]]:
    from google import genai
    from google.genai import types

    from backend.utils import _build_vertex_client, _gemini_key, _vertex_key

    vertex_key = _vertex_key()
    gemini_key = _gemini_key()
    client = None
    errors: list[str] = []
    if vertex_key:
        try:
            client = _build_vertex_client(vertex_key)
        except Exception as exc:  # noqa: BLE001
            errors.append(f"vertex: {exc}")
            client = None
    if client is None and gemini_key:
        try:
            client = genai.Client(api_key=gemini_key)
        except Exception as exc:  # noqa: BLE001
            errors.append(f"gemini: {exc}")
            client = None
    if client is None:
        detail = ("; ".join(errors) or "no API key").strip()
        raise RuntimeError(
            "VERTEX_API_KEY or GEMINI_API_KEY is required for gemini-embedding-001 "
            f"({detail})"
        )

    out: list[list[float]] = []
    config = types.EmbedContentConfig(
        task_type=task_type,
        output_dimensionality=dim,
    )
    for start in range(0, len(texts), _GOOGLE_BATCH):
        chunk = texts[start : start + _GOOGLE_BATCH]
        response = client.models.embed_content(
            model=model or GEMINI_EMBEDDING_MODEL,
            contents=chunk,
            config=config,
        )
        vectors = _extract_google_vectors(response)
        if len(vectors) != len(chunk):
            raise RuntimeError(
                f"Google embed returned {len(vectors)} vectors for {len(chunk)} texts"
            )
        out.extend(_fit_dim(row, dim) for row in vectors)
    return out


def embed_texts(
    texts: list[str],
    *,
    task_type: EmbedTask = "RETRIEVAL_DOCUMENT",
) -> list[list[float]]:
    """Embed texts with the admin-selected provider. Always returns `output_dimensionality` floats."""
    cleaned = [(t or "").strip() or " " for t in texts]
    if not cleaned:
        return []
    cfg = get_embedding_config()
    dim = int(cfg.get("output_dimensionality") or 768)
    provider = (cfg.get("provider") or "nyaysahayak").strip().lower()
    model = (cfg.get("model") or "").strip()
    if provider in ("vertex", "gemini", "google"):
        return _embed_google(cleaned, dim, model or GEMINI_EMBEDDING_MODEL, task_type)
    return _embed_nyaysahayak(cleaned, dim, cfg)


def embed_query(text: str) -> list[float]:
    vecs = embed_texts([text or ""], task_type="RETRIEVAL_QUERY")
    return vecs[0] if vecs else []
