"""Quote API — small FastAPI service for the DevOps take-home."""

from __future__ import annotations

import os
import random
import time
from typing import Any

from fastapi import FastAPI, Response
from prometheus_client import CONTENT_TYPE_LATEST, Counter, generate_latest

app = FastAPI(title="quote-api", version="0.1.0")

REQUESTS = Counter(
    "http_requests_total",
    "Total HTTP requests",
    ["method", "endpoint", "status"],
)

QUOTES = [
    "Ship small, verify often.",
    "Automate the boring paths; document the sharp edges.",
    "Prefer soft constraints when capacity can disappear.",
    "GitOps: the cluster mirrors the repo, not the other way around.",
    "A failing gate beats a green lie.",
    "Least privilege is a feature, not a chore.",
    "Spot is cheap until reclaim; on-demand is the seatbelt.",
    "Measure before you threshold.",
]


def _busy_cpu_ms(duration_ms: float = 100.0) -> None:
    """Burn CPU for ~duration_ms so load tests have something to scale on."""
    end = time.perf_counter() + (duration_ms / 1000.0)
    x = 0
    while time.perf_counter() < end:
        x = (x * 1103515245 + 12345) & 0x7FFFFFFF
    # Keep the work observable to optimizers
    if x < 0:
        raise RuntimeError("unreachable")


@app.get("/healthz")
def healthz() -> dict[str, str]:
    REQUESTS.labels("GET", "/healthz", "200").inc()
    return {"status": "ok"}


@app.get("/readyz")
def readyz() -> dict[str, str]:
    REQUESTS.labels("GET", "/readyz", "200").inc()
    return {"status": "ready"}


@app.get("/metrics")
def metrics() -> Response:
    return Response(generate_latest(), media_type=CONTENT_TYPE_LATEST)


@app.get("/api/quote")
def quote() -> dict[str, Any]:
    work_ms = float(os.getenv("QUOTE_CPU_MS", "100"))
    _busy_cpu_ms(work_ms)
    body = {
        "quote": random.choice(QUOTES),
        "work_ms": work_ms,
        "service": "quote-api",
    }
    REQUESTS.labels("GET", "/api/quote", "200").inc()
    return body
