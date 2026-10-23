# Implementation plan

This document is the working build sequence. Implementation is in the repo (compose, app, chart, scripts, Parts 4–7).

## Proposed repo tree

```
.
├── AGENTS.md
├── ASSIGNMENT - DevOps.md
├── AI-USAGE.md                 # planned
├── LOADTEST.md                 # planned
├── MIGRATION-NOTES.md          # planned
├── OPS-ANSWERS.md              # planned
├── README.md                   # planned (submission README)
├── TROUBLESHOOTING.md          # planned
├── docker-compose.yml          # planned
├── Dockerfile                  # planned (or app/Dockerfile)
├── app/                        # planned Python quote API
│   ├── main.py
│   ├── requirements.txt
│   └── ...
├── charts/quote-api/           # planned Helm chart
├── argocd/                     # planned Application manifest(s)
├── ci/legacy.gitlab-ci.yml
├── .github/workflows/          # planned GHA
├── infra/
│   ├── karpenter/              # planned Part 5a
│   └── cloudflare/             # planned Part 5b Terraform
├── loadtest/                   # planned k6 + dashboard JSON
├── planning/                   # this folder
├── scripts/
│   ├── run-all.sh
│   ├── 00-wait-cluster.sh
│   ├── 10-prepare-nodes.sh
│   ├── 20-deploy.sh
│   ├── 25-reclaim-drill.sh
│   ├── 30-fix-troubleshoot.sh
│   ├── 50-validate-tf.sh
│   └── 60-loadtest.sh
└── troubleshoot/               # provided (+ fixed-app.yaml planned)
```

## Script contract

All scripts: `set -euo pipefail` (or equivalent), **idempotent**, runnable inside toolbox with repo mounted.

| Script | Responsibility |
|--------|----------------|
| `00-wait-cluster.sh` | Wait until API ready and ≥4 worker nodes |
| `10-prepare-nodes.sh` | Call provided `troubleshoot/prepare.sh` (do not fork logic) |
| `20-deploy.sh` | Install ArgoCD if needed; apply Application; wait for sync/healthy; print curl URL |
| `25-reclaim-drill.sh` | Drain one spot node; curl loop; show reschedule; uncordon |
| `30-fix-troubleshoot.sh` | Apply `fixed-app.yaml` (or apply broken then fix path); run `verify.sh` |
| `50-validate-tf.sh` | `terraform fmt -check`, `init -backend=false`, `validate` in Cloudflare (and Karpenter if TF) dirs |
| `60-loadtest.sh` | Install kube-prometheus-stack if needed; run k6; capture HPA evidence hooks |
| `run-all.sh` | Ordered invocation of the above (CORE first; then 50/60) |

Compose bootstrap should ensure cluster + toolbox are up and preferably invoke wait + prepare (or document that `run-all` does).

## Part 1 — Python app

- FastAPI or Flask (~100 lines): endpoints per [20-requirements.md](20-requirements.md).
- `/api/quote`: busy-loop or hash work ~100ms CPU; return JSON quote.
- Prometheus client or hand-rolled `/metrics` with at least `http_requests_total` (or similar).
- Multi-stage Dockerfile: builder → slim runtime, `USER` non-root, minimal layers.
- Tag: `ghcr.io/<owner>/<repo>/quote-api:<git-sha>`.

## Part 2 — Helm + ArgoCD

Chart includes: Deployment, Service, Ingress, HPA (min 3), PDB, probes, resources, securityContext (runAsNonRoot, readOnlyRootFilesystem, drop caps as sensible), affinity/spread per [30-architecture.md](30-architecture.md).

ArgoCD Application: source = this repo path to chart; destination = cluster namespace (e.g. `quote-api`). Sync policy automated with prune/self-heal as appropriate for local demo (document choice).

## Part 3 — Fix path

1. Pre-diagnosed issues: [90-part3-issues.md](90-part3-issues.md).
2. Produce `troubleshoot/fixed-app.yaml`.
3. Narrative → `TROUBLESHOOTING.md`.
4. Script `30-fix-troubleshoot.sh` applies fix and runs `verify.sh`.

## Part 4 — GitHub Actions

- Trigger: push/PR to main (and tags if useful).
- Jobs: Semgrep (fail on findings) → build/push GHCR with SHA (and maybe branch SHA).
- OIDC or `GITHUB_TOKEN` for GHCR; **no** secrets in YAML.
- `MIGRATION-NOTES.md`: contrast with [ci/legacy.gitlab-ci.yml](../ci/legacy.gitlab-ci.yml) (allow_failure, flaky tests, `latest`-only, secrets in file, kubectl set image vs GitOps).

## Part 5 — IaC

- Karpenter YAML: current stable CRDs (verify docs at implement time — e.g. `karpenter.sh/v1` NodePool / EC2NodeClass or current names).
- Cloudflare TF: record, cache rules, `import` block; validate script only.

## Part 6 — Observability

- Helm install kube-prometheus-stack (idempotent).
- ServiceMonitor for quote-api.
- k6 script ramping through Ingress; thresholds from a baseline run documented in `LOADTEST.md`.
- Capture HPA watch / events (script may dump logs to `loadtest/evidence/`).
- PrometheusRule + Grafana dashboard JSON + screenshot path under `loadtest/`.

## Part 7

Write `OPS-ANSWERS.md` after CORE is stable (can draft in parallel).

## Build sequence

1. Compose + toolbox + `00`/`10` bootstrap  
2. Part 1 app + Dockerfile + local image (later GHCR)  
3. Part 2 Helm + ArgoCD + reclaim drill  
4. Part 3 fixed manifests + TROUBLESHOOTING  
5. Part 4 GHA (needs public repo)  
6. Part 5 TF/Karpenter + `50-validate-tf.sh`  
7. Part 6 stack + loadtest + `LOADTEST.md`  
8. Root README, AI-USAGE, OPS-ANSWERS; refresh planning INDEX statuses  
