#!/usr/bin/env bash
# Ordered Golden Rule entrypoint: CORE then Part 5 validate then Part 6 load test.
# If invoked on the host (outside toolbox), re-exec inside the toolbox container.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "${ROOT}"

if [[ ! -f /kubeconfig/kubeconfig.yaml ]] && command -v docker >/dev/null 2>&1; then
  if docker compose ps --status running 2>/dev/null | grep -q toolbox; then
    echo "[run-all] Re-executing inside toolbox container..."
    exec docker compose exec -T toolbox ./scripts/run-all.sh
  fi
fi

run() {
  local script="$1"
  echo ""
  echo "========== $(basename "${script}") =========="
  bash "${script}"
}

run "${ROOT}/scripts/00-wait-cluster.sh"
run "${ROOT}/scripts/10-prepare-nodes.sh"
run "${ROOT}/scripts/20-deploy.sh"
run "${ROOT}/scripts/25-reclaim-drill.sh"
run "${ROOT}/scripts/30-fix-troubleshoot.sh"
run "${ROOT}/scripts/50-validate-tf.sh"
run "${ROOT}/scripts/60-loadtest.sh"

echo ""
echo "=============================================="
echo " ALL SCRIPTS COMPLETED"
echo " Host check: curl http://localhost:${INGRESS_HOST_PORT:-8080}/api/quote"
echo "=============================================="
