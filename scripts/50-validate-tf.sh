#!/usr/bin/env bash
# Terraform fmt / init / validate for Cloudflare (and Karpenter if TF present).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=/dev/null
source "${ROOT}/scripts/lib.sh"

validate_dir() {
  local dir="$1"
  [[ -d "${dir}" ]] || return 0
  log "Validating Terraform in ${dir}..."
  (
    cd "${dir}"
    terraform fmt -check -recursive
    terraform init -backend=false -input=false
    terraform validate
  )
  log "OK: ${dir}"
}

validate_dir "${ROOT}/infra/cloudflare"

# Karpenter is YAML in this repo; if a TF dir appears later, validate it too
if [[ -d "${ROOT}/infra/karpenter" ]] && ls "${ROOT}/infra/karpenter"/*.tf >/dev/null 2>&1; then
  validate_dir "${ROOT}/infra/karpenter"
fi

log "Terraform validation complete"
