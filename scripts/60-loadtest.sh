#!/usr/bin/env bash
# Install kube-prometheus-stack, run k6 through Ingress, capture HPA evidence.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=/dev/null
source "${ROOT}/scripts/lib.sh"

MON_NS=monitoring
EVIDENCE="${ROOT}/loadtest/evidence"
mkdir -p "${EVIDENCE}"

log "Installing kube-prometheus-stack (slim)..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts >/dev/null 2>&1 || true
helm repo update prometheus-community >/dev/null
kubectl create namespace "${MON_NS}" --dry-run=client -o yaml | kubectl apply -f -

helm upgrade --install kps prometheus-community/kube-prometheus-stack \
  --namespace "${MON_NS}" \
  --set grafana.adminPassword=admin \
  --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false \
  --set prometheus.prometheusSpec.podMonitorSelectorNilUsesHelmValues=false \
  --set prometheus.prometheusSpec.ruleSelectorNilUsesHelmValues=false \
  --set alertmanager.enabled=false \
  --set kubeEtcd.enabled=false \
  --set kubeControllerManager.enabled=false \
  --set kubeScheduler.enabled=false \
  --set kubeProxy.enabled=false \
  --set defaultRules.create=true \
  --wait --timeout 15m

log "Applying ServiceMonitor + PrometheusRule for quote-api..."
kubectl apply -f "${ROOT}/loadtest/servicemonitor.yaml"
kubectl apply -f "${ROOT}/loadtest/prometheusrule.yaml"

# Optional: import Grafana dashboard ConfigMap
if [[ -f "${ROOT}/loadtest/grafana-dashboard.json" ]]; then
  kubectl -n "${MON_NS}" create configmap quote-api-dashboard \
    --from-file=quote-api.json="${ROOT}/loadtest/grafana-dashboard.json" \
    -o yaml --dry-run=client | kubectl apply -f -
  kubectl -n "${MON_NS}" label configmap quote-api-dashboard \
    grafana_dashboard=1 --overwrite
fi

log "Baseline: single request timing..."
START=$(date +%s%3N)
curl -fsS "${QUOTE_URL}" >/dev/null
END=$(date +%s%3N)
echo "baseline_ms=$((END - START))" | tee "${EVIDENCE}/baseline.txt"

log "Watching HPA in background..."
kubectl -n "${QUOTE_NS}" get hpa -w > "${EVIDENCE}/hpa-watch.txt" 2>&1 &
HPA_PID=$!

log "Capturing pods before load..."
kubectl -n "${QUOTE_NS}" get pods -o wide | tee "${EVIDENCE}/pods-before.txt"

log "Running k6 load test..."
k6 run "${ROOT}/loadtest/k6-quote.js" \
  -e QUOTE_URL="${QUOTE_URL}" \
  --summary-export="${EVIDENCE}/k6-summary.json" \
  | tee "${EVIDENCE}/k6-output.txt"

kill "${HPA_PID}" 2>/dev/null || true

log "HPA / pods after load..."
kubectl -n "${QUOTE_NS}" get hpa | tee "${EVIDENCE}/hpa-after.txt"
kubectl -n "${QUOTE_NS}" get pods -o wide | tee "${EVIDENCE}/pods-after.txt"
kubectl -n "${QUOTE_NS}" get events --sort-by=.lastTimestamp | tail -40 | tee "${EVIDENCE}/events.txt"

REPLICAS=$(kubectl -n "${QUOTE_NS}" get hpa quote-api -o jsonpath='{.status.currentReplicas}' 2>/dev/null || echo 0)
log "HPA currentReplicas=${REPLICAS}"
if [[ "${REPLICAS}" -gt 3 ]]; then
  log "HPA scaled beyond 3 — good"
else
  log "WARN: HPA currentReplicas=${REPLICAS} (may need longer/higher load on this machine)"
fi

# Placement check: no GPU
GPU_NODE=$(kubectl get nodes -l acme.io/node-type=gpu -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)
if [[ -n "${GPU_NODE}" ]]; then
  ON_GPU=$(kubectl -n "${QUOTE_NS}" get pods -o jsonpath='{range .items[*]}{.spec.nodeName}{"\n"}{end}' \
    | grep -c "^${GPU_NODE}$" || true)
  [[ "${ON_GPU}" -eq 0 ]] || die "Pods landed on GPU during load test"
fi

log "Load test script complete. Evidence in loadtest/evidence/"
log "Grafana: kubectl -n monitoring port-forward svc/kps-grafana 3000:80  (admin/admin)"
