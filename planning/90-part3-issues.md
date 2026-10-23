# Part 3 — defect catalog (`broken-app.yaml`)

Pre-implementation diagnosis of [`troubleshoot/broken-app.yaml`](../troubleshoot/broken-app.yaml). **Do not apply fixes in the planning-only phase.** Fixes belong in `troubleshoot/fixed-app.yaml` + narrative in `TROUBLESHOOTING.md`.

Rules reminder: keep `default-deny`; do not remove node labels/taints; fix workloads/policies.

Verifier: [`troubleshoot/verify.sh`](../troubleshoot/verify.sh). Smoke: [`troubleshoot/smoke-job.yaml`](../troubleshoot/smoke-job.yaml) curls `http://web-svc.troubleshoot.svc.cluster.local` expecting `TROUBLESHOOT-OK`.

---

## Issue A — Invalid nginx image tag

| Field | Detail |
|-------|--------|
| **Symptom** | `web` pods `ImagePullBackOff` / ErrImagePull |
| **Diagnose** | `kubectl describe pod -n troubleshoot -l app=web`; `kubectl get events -n troubleshoot` |
| **Root cause** | Image `nginx:1.25.99` does not exist |
| **Fix** | Use a real tag (e.g. `nginx:1.25`) |

## Issue B — Unschedulable memory requests

| Field | Detail |
|-------|--------|
| **Symptom** | Pods Pending: Insufficient memory |
| **Diagnose** | `kubectl describe pod …` → FailedScheduling |
| **Root cause** | requests/limits `memory: 16Gi` unrealistic for local agents |
| **Fix** | Sensible requests/limits (e.g. 64–128Mi) |

## Issue C — Probe port mismatch

| Field | Detail |
|-------|--------|
| **Symptom** | Pods run but fail liveness/readiness; restarts |
| **Diagnose** | `kubectl describe pod`; probe failures on port 8080 |
| **Root cause** | Probes hit port **8080**; nginx listens on **80** (`containerPort: 80`) |
| **Fix** | Probe port 80 (or configure nginx on 8080 consistently) |

## Issue D — Wrong ConfigMap name

| Field | Detail |
|-------|--------|
| **Symptom** | CreateContainerConfigError / missing volume |
| **Diagnose** | `kubectl describe pod` → configmap “web-conf” not found |
| **Root cause** | Volume refs `web-conf`; ConfigMap is named `web-config` |
| **Fix** | Align names (`web-config`) |

## Issue E — Service selector mismatch

| Field | Detail |
|-------|--------|
| **Symptom** | Service has no endpoints; verify step 6 fails |
| **Diagnose** | `kubectl get endpoints web-svc -n troubleshoot`; `kubectl get pods --show-labels` |
| **Root cause** | Service selector `app: webapp`; pods labeled `app: web` |
| **Fix** | Selector `app: web` |

## Issue F — Service targetPort mismatch

| Field | Detail |
|-------|--------|
| **Symptom** | Endpoints exist but smoke curl fails / connection issues |
| **Diagnose** | `kubectl describe svc web-svc`; compare targetPort to containerPort |
| **Root cause** | `targetPort: 8080` but container listens on **80** |
| **Fix** | `targetPort: 80` |

## Issue G — Wrong GPU nodeSelector key

| Field | Detail |
|-------|--------|
| **Symptom** | `ai-inference` Pending |
| **Diagnose** | `kubectl describe pod -l app=ai-inference`; node labels from prepare |
| **Root cause** | `nodeSelector: node-type: gpu` but prepare labels **`acme.io/node-type=gpu`** |
| **Fix** | `acme.io/node-type: gpu` |

## Issue H — Missing GPU taint toleration

| Field | Detail |
|-------|--------|
| **Symptom** | Still Pending on GPU node after selector fix |
| **Diagnose** | describe pod → untolerated taint `nvidia.com/gpu` |
| **Root cause** | prepare taints GPU node `nvidia.com/gpu=true:NoSchedule`; deployment has no toleration |
| **Fix** | Add matching toleration; **do not** remove taint |

## Issue I — Default-deny blocks smoke path

| Field | Detail |
|-------|--------|
| **Symptom** | Deployments Ready but smoke Job Failed / timeout; verify step 7 |
| **Diagnose** | Job logs; confirm NP `default-deny` selects all pods Ingress+Egress |
| **Root cause** | Default-deny blocks client→Service HTTP and likely DNS (kube-dns) egress |
| **Fix** | Keep default-deny; add least-privilege NetworkPolicies: DNS egress (kube-system DNS), client→web **ingress** on 80, **and** smoke-client→web **egress** on 80 (default-deny blocks both directions). Deleting default-deny is **not** accepted |

---

## Suggested fix order

1. Image + memory + ConfigMap (get pods creating)  
2. Probe + Service selector/targetPort (get Ready + endpoints)  
3. NetworkPolicies (smoke Job)  
4. GPU selector + toleration (`ai-inference` on GPU node)  

Then: `kubectl apply -f troubleshoot/fixed-app.yaml` && `./troubleshoot/verify.sh` → `PASS`.
