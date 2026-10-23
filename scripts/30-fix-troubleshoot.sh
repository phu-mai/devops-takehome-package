#!/usr/bin/env bash
# Apply fixed Part 3 manifests and run the official verifier.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=/dev/null
source "${ROOT}/scripts/lib.sh"

FIXED="${ROOT}/troubleshoot/fixed-app.yaml"
[[ -f "${FIXED}" ]] || die "Missing ${FIXED}"

log "Applying troubleshoot/fixed-app.yaml..."
kubectl apply -f "${FIXED}"

log "Waiting briefly for rollouts..."
kubectl -n troubleshoot rollout status deployment/web --timeout=120s || true
kubectl -n troubleshoot rollout status deployment/ai-inference --timeout=120s || true

log "Running troubleshoot/verify.sh..."
bash "${ROOT}/troubleshoot/verify.sh"
