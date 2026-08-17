"""
ASGI entrypoint for local + Cloud Run.

Keeps existing deployment start commands unchanged:
  uvicorn main:app --host 0.0.0.0 --port $PORT
"""
from backend.main import app

__all__ = ["app"]
