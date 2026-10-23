#!/usr/bin/env bash
# Create (or reuse) a k3d cluster with ≥4 agents and publish Ingress on host :8080.
# Traefik stays enabled (default) so Ingress routes work for Part 2/6.
set -euo pipefail

CLUSTER_NAME="${CLUSTER_NAME:-devops-takehome}"
KUBECONFIG_PATH="${KUBECONFIG:-/kubeconfig/kubeconfig.yaml}"
INGRESS_HOST_PORT="${INGRESS_HOST_PORT:-8080}"

mkdir -p "$(dirname "$KUBECONFIG_PATH")"

if k3d cluster list --no-headers 2>/dev/null | awk '{print $1}' | grep -qx "${CLUSTER_NAME}"; then
  echo "[bootstrap] Cluster '${CLUSTER_NAME}' already exists — reusing"
else
  echo "[bootstrap] Creating k3d cluster '${CLUSTER_NAME}' (1 server + 4 agents)..."
  k3d cluster create "${CLUSTER_NAME}" \
    --servers 1 \
    --agents 4 \
    --port "${INGRESS_HOST_PORT}:80@loadbalancer" \
    --wait
fi

k3d kubeconfig get "${CLUSTER_NAME}" > "${KUBECONFIG_PATH}"

# From the toolbox container, reach the API via the Docker Desktop host gateway
sed -i \
  -e 's|https://0\.0\.0\.0:|https://host.docker.internal:|g' \
  -e 's|https://127\.0\.0\.1:|https://host.docker.internal:|g' \
  -e 's|https://localhost:|https://host.docker.internal:|g' \
  "${KUBECONFIG_PATH}"

export KUBECONFIG="${KUBECONFIG_PATH}"
echo "[bootstrap] Waiting for nodes..."
for _ in $(seq 1 60); do
  READY=$(kubectl get nodes --no-headers 2>/dev/null | grep -c ' Ready' || true)
  # 1 server + 4 agents = 5 Ready nodes
  if [[ "${READY}" -ge 5 ]]; then
    echo "[bootstrap] ${READY} nodes Ready"
    kubectl get nodes
    exit 0
  fi
  sleep 5
done

echo "[bootstrap] ERROR: cluster did not become ready in time" >&2
kubectl get nodes || true
exit 1
