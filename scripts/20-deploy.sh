#!/usr/bin/env bash
# Build/import quote-api, install ArgoCD, sync Application from in-cluster git daemon.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=/dev/null
source "${ROOT}/scripts/lib.sh"

# Fix Git dubious ownership error globally for containerized environments
git config --global --add safe.directory '*' || true

SHA="$(git_sha)"
FULL_IMAGE="${IMAGE_NAME}:${SHA}"
ARGO_NS=argocd
GIT_NS=git-server

log "Building image ${FULL_IMAGE}..."
docker build -t "${FULL_IMAGE}" -f "${ROOT}/Dockerfile" "${ROOT}"

log "Importing image into k3d cluster '${CLUSTER_NAME}'..."
k3d image import "${FULL_IMAGE}" -c "${CLUSTER_NAME}"

# --- Prepare a bare git repo of the workspace for ArgoCD ---
log "Preparing bare git repository..."
if ! git -C "${ROOT}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git -C "${ROOT}" init
fi
git -C "${ROOT}" config user.email "devops@local" || true
git -C "${ROOT}" config user.name "DevOps Takehome" || true
# Commit current tree so ArgoCD sees the chart (local-only; not pushed remotely)
git -C "${ROOT}" add -A
git -C "${ROOT}" commit -m "argo sync snapshot $(date -u +%Y%m%d%H%M%S)" --allow-empty || true

BARE="/tmp/quote-api.git"
rm -rf "${BARE}"
git clone --bare "${ROOT}" "${BARE}"
git -C "${ROOT}" push --force "${BARE}" HEAD:refs/heads/main 2>/dev/null \
  || git -C "${ROOT}" push --force "${BARE}" HEAD:main || true
# Default branch for dumb clients
git -C "${BARE}" symbolic-ref HEAD refs/heads/main 2>/dev/null || true

log "Deploying in-cluster git daemon..."
kubectl create namespace "${GIT_NS}" --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: git-daemon
  namespace: ${GIT_NS}
spec:
  replicas: 1
  selector:
    matchLabels:
      app: git-daemon
  template:
    metadata:
      labels:
        app: git-daemon
    spec:
      containers:
        - name: git
          image: alpine:3.20
          command: ["sh", "-c"]
          args:
            - |
              apk add --no-cache git git-daemon >/dev/null
              mkdir -p /git
              exec git daemon --verbose --export-all --base-path=/git --reuseaddr --listen=0.0.0.0 --port=9418
          ports:
            - containerPort: 9418
              name: git
          volumeMounts:
            - name: git-data
              mountPath: /git
          readinessProbe:
            tcpSocket:
              port: 9418
            initialDelaySeconds: 5
            periodSeconds: 5
      volumes:
        - name: git-data
          emptyDir: {}
---
apiVersion: v1
kind: Service
metadata:
  name: git-daemon
  namespace: ${GIT_NS}
spec:
  selector:
    app: git-daemon
  ports:
    - name: git
      port: 9418
      targetPort: 9418
EOF

kubectl -n "${GIT_NS}" rollout status deployment/git-daemon --timeout=180s
GIT_POD=$(kubectl -n "${GIT_NS}" get pod -l app=git-daemon -o jsonpath='{.items[0].metadata.name}')

log "Copying bare repo into git-daemon pod..."
tar -C /tmp -cf /tmp/bare.tar quote-api.git
kubectl -n "${GIT_NS}" cp /tmp/bare.tar "${GIT_POD}:/tmp/bare.tar"
kubectl -n "${GIT_NS}" exec "${GIT_POD}" -- sh -c 'mkdir -p /git && tar -xf /tmp/bare.tar -C /git && ls -la /git'

REPO_URL="git://git-daemon.${GIT_NS}.svc.cluster.local/quote-api.git"

# --- ArgoCD ---
log "Installing ArgoCD (idempotent)..."
kubectl create namespace "${ARGO_NS}" --dry-run=client -o yaml | kubectl apply -f -
helm repo add argo https://argoproj.github.io/argo-helm >/dev/null 2>&1 || true
helm repo update argo >/dev/null
helm upgrade --install argo-cd argo/argo-cd \
  --namespace "${ARGO_NS}" \
  --set configs.params."server.insecure"=true \
  --set server.service.type=ClusterIP \
  --set dex.enabled=false \
  --set notifications.enabled=false \
  --set applicationSet.enabled=false \
  --wait --timeout 10m

kubectl create namespace "${QUOTE_NS}" --dry-run=client -o yaml | kubectl apply -f -

log "Applying ArgoCD Application (repo=${REPO_URL})..."
# Delete stale app to pick up new revision when re-run
kubectl -n "${ARGO_NS}" delete application quote-api --ignore-not-found >/dev/null 2>&1 || true
kubectl apply -f - <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: quote-api
  namespace: ${ARGO_NS}
spec:
  project: default
  source:
    repoURL: ${REPO_URL}
    targetRevision: HEAD
    path: charts/quote-api
    helm:
      parameters:
        - name: image.repository
          value: ${IMAGE_NAME}
        - name: image.tag
          value: "${SHA}"
        - name: image.pullPolicy
          value: IfNotPresent
  destination:
    server: https://kubernetes.default.svc
    namespace: ${QUOTE_NS}
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
EOF

log "Waiting for Application Synced/Healthy..."
for i in $(seq 1 90); do
  SYNC=$(kubectl -n "${ARGO_NS}" get application quote-api -o jsonpath='{.status.sync.status}' 2>/dev/null || echo "")
  HEALTH=$(kubectl -n "${ARGO_NS}" get application quote-api -o jsonpath='{.status.health.status}' 2>/dev/null || echo "")
  MSG=$(kubectl -n "${ARGO_NS}" get application quote-api -o jsonpath='{.status.conditions[0].message}' 2>/dev/null || echo "")
  if [[ "${SYNC}" == "Synced" && "${HEALTH}" == "Healthy" ]]; then
    log "Application Synced & Healthy"
    break
  fi
  if [[ $((i % 6)) -eq 0 ]]; then
    log "sync=${SYNC:-?} health=${HEALTH:-?} msg=${MSG:-}"
  fi
  sleep 5
done

kubectl -n "${QUOTE_NS}" rollout status deployment/quote-api --timeout=300s

log "Waiting for host Ingress ${QUOTE_URL}..."
if wait_http "${QUOTE_URL}" 60; then
  curl -fsS "${QUOTE_URL}"
  echo
else
  log "Host curl not ready yet; in-cluster check..."
  kubectl -n "${QUOTE_NS}" delete pod curl-quote --ignore-not-found >/dev/null 2>&1 || true
  kubectl -n "${QUOTE_NS}" run curl-quote --rm -i --restart=Never --image=curlimages/curl:8.7.1 -- \
    curl -fsS "http://quote-api.${QUOTE_NS}.svc.cluster.local/api/quote"
fi

echo ""
echo "=============================================="
echo " Quote API (host): http://localhost:${INGRESS_HOST_PORT}/api/quote"
echo " Image:            ${FULL_IMAGE}"
echo "=============================================="