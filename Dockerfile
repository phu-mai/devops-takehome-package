# Multi-stage quote-api image — non-root, slim runtime
FROM python:3.12-slim-bookworm AS builder

WORKDIR /build
COPY app/requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

FROM python:3.12-slim-bookworm AS runtime

RUN useradd --create-home --uid 10001 --shell /usr/sbin/nologin appuser \
    && mkdir -p /app \
    && chown -R appuser:appuser /app

COPY --from=builder /install /usr/local
COPY --chown=appuser:appuser app/main.py /app/main.py

WORKDIR /app
USER 10001:10001

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    QUOTE_CPU_MS=100

EXPOSE 8000

# No writable FS required; uvicorn binds 8000
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
