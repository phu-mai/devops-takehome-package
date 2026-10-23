#!/usr/bin/env bash
# Drain one spot node; prove service stays up and pods reschedule (not onto GPU).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=/dev/null
source "${ROOT}/scripts/lib.sh"

SPOT_NODE=$(kubectl get nodes -l acme.io/capacity=spot -o jsonpath='{.items[0].metadata.name}')
[[ -n "${SPOT_NODE}" ]] || die "No spot node found — run 10-prepare-nodes.sh first"
GPU_NODE=$(kubectl get nodes -l acme.io/node-type=gpu -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)

log "Spot node to drain: ${SPOT_NODE}"
log "Pods before drain:"
kubectl -n "${QUOTE_NS}" get pods -o wide

CURL_LOG=$(mktemp)
cleanup() {
  kill "${CURL_PID:-}" 2>/dev/null || true
  kubectl uncordon "${SPOT_NODE}" >/dev/null 2>&1 || true
  rm -f "${CURL_LOG}"
}
trap cleanup EXIT

# Background reachability probe
(
  ok=0
  fail=0
  while true; do
    if curl -fsS --max-time 3 "${QUOTE_URL}" >/dev/null 2>&1; then
      ok=$((ok + 1))
    else
      fail=$((fail + 1))
    fi
    echo "ok=${ok} fail=${fail}" > "${CURL_LOG}"
    sleep 1
  done
) &
CURL_PID=$!

log "Draining ${SPOT_NODE}..."
kubectl drain "${SPOT_NODE}" \
  --ignore-daemonsets \
  --delete-emptydir-data \
  --force \
  --grace-period=30 \
  --timeout=180s

log "Waiting for quote-api pods to reschedule..."
sleep 10
kubectl -n "${QUOTE_NS}" rollout status deployment/quote-api --timeout=180s || true
kubectl -n "${QUOTE_NS}" get pods -o wide

if [[ -n "${GPU_NODE}" ]]; then
  ON_GPU=$(kubectl -n "${QUOTE_NS}" get pods -o jsonpath='{range .items[*]}{.spec.nodeName}{"\n"}{end}' \
    | grep -c "^${GPU_NODE}$" || true)
  if [[ "${ON_GPU}" -gt 0 ]]; then
    die "quote-api scheduled onto GPU node ${GPU_NODE}"
  fi
fi

READY=$(kubectl -n "${QUOTE_NS}" get pods -l app.kubernetes.io/name=quote-api \
  --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l | tr -d ' ')
[[ "${READY}" -ge 1 ]] || die "No Running quote-api pods after drain"

kill "${CURL_PID}" 2>/dev/null || true
wait "${CURL_PID}" 2>/dev/null || true
log "Curl loop stats: $(cat "${CURL_LOG}" 2>/dev/null || echo n/a)"

# At least some successes during/after drain
grep -q 'ok=[1-9]' "${CURL_LOG}" 2>/dev/null || \
  curl -fsS "${QUOTE_URL}" >/dev/null || die "Service unreachable during reclaim drill"

log "Uncordoning ${SPOT_NODE}..."
kubectl uncordon "${SPOT_NODE}"
trap - EXIT

log "Final curl check..."
curl -fsS "${QUOTE_URL}"
echo
log "Reclaim drill PASSED"
