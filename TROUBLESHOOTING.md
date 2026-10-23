# Part 3 — Troubleshooting narrative

Each issue below was diagnosed against `troubleshoot/broken-app.yaml` after `troubleshoot/prepare.sh` labeled/tainted the nodepools. Fixes live in `troubleshoot/fixed-app.yaml`. The default-deny NetworkPolicy and node labels/taints were **not** removed.

Verifier: `./troubleshoot/verify.sh` → `PASS`.

---

## Issue A — Invalid nginx image tag

| | |
|---|---|
| **Symptom** | `web` pods stuck in `ImagePullBackOff` / `ErrImagePull` |
| **Commands** | `kubectl describe pod -n troubleshoot -l app=web`; `kubectl get events -n troubleshoot --sort-by=.lastTimestamp` |
| **Root cause** | Image `nginx:1.25.99` does not exist on Docker Hub |
| **Fix** | Use a real tag: `nginx:1.25` |

## Issue B — Unschedulable memory requests

| | |
|---|---|
| **Symptom** | Pods `Pending` with `Insufficient memory` |
| **Commands** | `kubectl describe pod -n troubleshoot -l app=web` → FailedScheduling |
| **Root cause** | `requests/limits.memory: 16Gi` exceeds local k3d agent capacity |
| **Fix** | Lower to `64Mi` request / `128Mi` limit |

## Issue C — Probe port mismatch

| | |
|---|---|
| **Symptom** | Containers start then fail probes / restart |
| **Commands** | `kubectl describe pod -n troubleshoot -l app=web` (probe failures on port 8080) |
| **Root cause** | Liveness/readiness hit port **8080**; nginx listens on **80** |
| **Fix** | Probe `port: 80` |

## Issue D — Wrong ConfigMap name

| | |
|---|---|
| **Symptom** | `CreateContainerConfigError` |
| **Commands** | `kubectl describe pod -n troubleshoot -l app=web` |
| **Root cause** | Volume referenced ConfigMap `web-conf`; object is named `web-config` |
| **Fix** | `configMap.name: web-config` |

## Issue E — Service selector mismatch

| | |
|---|---|
| **Symptom** | Service has no Endpoints; verify step 6 fails |
| **Commands** | `kubectl get endpoints web-svc -n troubleshoot`; `kubectl get pods -n troubleshoot --show-labels` |
| **Root cause** | Service selector `app: webapp` vs pods labeled `app: web` |
| **Fix** | Selector `app: web` |

## Issue F — Service targetPort mismatch

| | |
|---|---|
| **Symptom** | Endpoints exist but smoke curl fails / connection issues |
| **Commands** | `kubectl describe svc web-svc -n troubleshoot` |
| **Root cause** | `targetPort: 8080` but container listens on **80** |
| **Fix** | `targetPort: 80` |

## Issue G — Wrong GPU nodeSelector key

| | |
|---|---|
| **Symptom** | `ai-inference` stays `Pending` |
| **Commands** | `kubectl describe pod -n troubleshoot -l app=ai-inference`; `kubectl get nodes --show-labels` |
| **Root cause** | Selector used `node-type: gpu`; prepare labels **`acme.io/node-type=gpu`** |
| **Fix** | `nodeSelector: acme.io/node-type: gpu` |

## Issue H — Missing GPU taint toleration

| | |
|---|---|
| **Symptom** | Still `Pending` after selector fix |
| **Commands** | `kubectl describe pod …` → untolerated taint `nvidia.com/gpu=true:NoSchedule` |
| **Root cause** | GPU node is tainted by `prepare.sh`; deployment had no matching toleration |
| **Fix** | Add toleration for `nvidia.com/gpu=true:NoSchedule` — **do not** remove the taint |

## Issue I — Default-deny blocks smoke path

| | |
|---|---|
| **Symptom** | Deployments Ready but smoke Job fails/times out (verify step 7) |
| **Commands** | `kubectl logs job/smoke-test -n troubleshoot`; `kubectl get networkpolicy -n troubleshoot` |
| **Root cause** | `default-deny` blocks Ingress+Egress: DNS to CoreDNS and HTTP from smoke-client → web |
| **Fix** | Keep `default-deny`. Add least-privilege policies: DNS egress to `kube-system` (UDP/TCP 53), and ingress on `app=web` from `app=smoke-client` on TCP 80. Deleting default-deny is not accepted. |

---

## Fix order used

1. Image + memory + ConfigMap (pods create)  
2. Probes + Service selector/targetPort (Ready + endpoints)  
3. NetworkPolicies (smoke Job)  
4. GPU selector + toleration (`ai-inference` on GPU node)  

Then: `kubectl apply -f troubleshoot/fixed-app.yaml && ./troubleshoot/verify.sh` → **PASS**.
