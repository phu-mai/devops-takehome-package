#!/usr/bin/env bash
# Point kubeconfig at the k3d serverlb on the Docker network (more reliable than host.docker.internal).
set -euo pipefail
KUBECONFIG_PATH="${KUBECONFIG:-/kubeconfig/kubeconfig.yaml}"
CLUSTER_NAME="${CLUSTER_NAME:-devops-takehome}"
LB="k3d-${CLUSTER_NAME}-serverlb"

if [[ ! -f "${KUBECONFIG_PATH}" ]]; then
  k3d kubeconfig get "${CLUSTER_NAME}" > "${KUBECONFIG_PATH}"
fi

# Prefer in-network LB:6443
sed -i -E "s|https://[^:]+:[0-9]+|https://${LB}:6443|g" "${KUBECONFIG_PATH}"
echo "[fix-kubeconfig] server -> https://${LB}:6443"
kubectl --kubeconfig="${KUBECONFIG_PATH}" get --raw=/readyz
echo
