# Operations

## Reviewer runbook (Golden Rule)

```bash
git clone <repo> && cd <repo>
docker compose up -d
./scripts/run-all.sh
```

Optional: run `scripts/00-*.sh` … individually for debugging. After CORE deploy, from host:

```bash
curl http://localhost:<port>/api/quote
```

Port is defined by compose/k3d ingress publish — set and document at implementation time.

## What must never be changed

| Asset | Rule |
|-------|------|
| [`troubleshoot/prepare.sh`](../troubleshoot/prepare.sh) | Do not rewrite labeling/tainting; call as provided |
| Node labels `acme.io/capacity`, `acme.io/node-type` | Do not remove to fix scheduling |
| Taint `nvidia.com/gpu=true:NoSchedule` | Do not remove |
| NetworkPolicy `default-deny` in `troubleshoot` ns | Keep; add allow rules only |
| Secrets | Never commit |

`verify.sh` re-checks NP existence and node labels/taints.

## Reclaim drill (`25-reclaim-drill.sh`) expected behavior

1. Identify a node with `acme.io/capacity=spot`.
2. `kubectl drain` (respect PDB; use appropriate flags for local demo).
3. Loop `curl` against service/Ingress — expect continued success (may briefly retry).
4. Show pods leaving drained node and landing on remaining spot/OD (not GPU).
5. `kubectl uncordon` the node.
6. Exit 0 only if service stayed reachable and pods recovered.

Soft topology spread is critical: hard `DoNotSchedule` spread can block reschedule when capacity shrinks.

## Likely reviewer machine failures

| Symptom | Likely cause | Fix direction |
|---------|--------------|---------------|
| Compose / k3d fails | Insufficient RAM/CPU; Docker Desktop resources | Raise Docker memory (≥8GB recommended); reduce concurrent stacks |
| Port already in use | Host port conflict for Ingress/API | Change published port in compose; document in README |
| `prepare.sh` ERROR need ≥4 workers | Cluster created with too few agents | Recreate k3d with `--agents 4` (compose must bake this in) |
| Arm64 / amd64 image pull issues | Platform mismatch | Multi-arch build or document `--platform` |
| ArgoCD sync stuck | Repo URL private / wrong path / chart missing | Public repo; correct `path`/`targetRevision` |
| Part 3 smoke Job fails | NetworkPolicy missing DNS/HTTP egress/ingress | Least-privilege allows — see [90-part3-issues.md](90-part3-issues.md) |
| HPA does not scale | Metrics server / resource requests missing | Ensure metrics-server (k3d) + requests set for HPA |

## Toolbox usage

Scripts run **inside** the toolbox container (or via `docker compose exec toolbox …`) with kubeconfig pointed at the compose-created cluster. Host-installed kubectl is optional for the reviewer.

## Idempotency

Re-running `run-all.sh` or individual scripts must not require teardown. Prefer `helm upgrade --install`, ArgoCD apply, `kubectl apply`, and guards like “install if missing.”
