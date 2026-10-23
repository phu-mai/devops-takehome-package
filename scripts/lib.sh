#!/usr/bin/env bash
# Shared helpers for numbered scripts (sourced, not executed).
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
export KUBECONFIG="${KUBECONFIG:-/kubeconfig/kubeconfig.yaml}"
export CLUSTER_NAME="${CLUSTER_NAME:-devops-takehome}"
export INGRESS_HOST_PORT="${INGRESS_HOST_PORT:-8080}"
export QUOTE_URL="${QUOTE_URL:-http://host.docker.internal:${INGRESS_HOST_PORT}/api/quote}"
export QUOTE_NS="${QUOTE_NS:-quote-api}"
export IMAGE_NAME="${IMAGE_NAME:-quote-api}"

log() { echo "[$(basename "$0" 2>/dev/null || echo script)] $*"; }
die() { echo "ERROR: $*" >&2; exit 1; }

git_sha() {
  if git -C "${ROOT}" rev-parse --short=12 HEAD >/dev/null 2>&1; then
    git -C "${ROOT}" rev-parse --short=12 HEAD
  else
    echo "devlocal"
  fi
}

wait_http() {
  local url="$1"
  local attempts="${2:-60}"
  local i
  for i in $(seq 1 "${attempts}"); do
    if curl -fsS --max-time 5 "${url}" >/dev/null 2>&1; then
      return 0
    fi
    sleep 5
  done
  return 1
}
