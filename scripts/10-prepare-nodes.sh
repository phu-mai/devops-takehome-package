#!/usr/bin/env bash
# Label/taint nodepools via the provided prepare.sh (do not fork that logic).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=/dev/null
source "${ROOT}/scripts/lib.sh"

log "Running troubleshoot/prepare.sh..."
bash "${ROOT}/troubleshoot/prepare.sh"
log "Nodepools prepared"
