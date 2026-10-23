#!/usr/bin/env bash
# Wait until the API is reachable and ≥4 worker nodes are Ready.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=/dev/null
source "${ROOT}/scripts/lib.sh"

log "Waiting for Kubernetes API..."
for _ in $(seq 1 60); do
  if kubectl get --raw=/readyz >/dev/null 2>&1; then
    break
  fi
  sleep 5
done
kubectl get --raw=/readyz >/dev/null

log "Waiting for ≥4 Ready worker nodes..."
for _ in $(seq 1 60); do
  WORKERS=$(kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name}{" "}{.metadata.labels.node-role\.kubernetes\.io/control-plane}{"\n"}{end}' \
    | awk '$2 == "" {print $1}' | wc -l | tr -d ' ')
  READY=$(kubectl get nodes --no-headers 2>/dev/null | grep -c ' Ready' || true)
  if [[ "${WORKERS}" -ge 4 && "${READY}" -ge 5 ]]; then
    kubectl get nodes
    log "Cluster ready (${WORKERS} workers, ${READY} Ready nodes)"
    exit 0
  fi
  sleep 5
done

die "Cluster not ready (need ≥4 workers). Found workers=${WORKERS:-?} ready=${READY:-?}"
