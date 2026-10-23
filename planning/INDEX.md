# Planning index

Catalog of planning docs and repo artifacts. Status: `exists` = present in repo; `planned` = not built yet.

## Planning documents

| Doc | Purpose | Status |
|-----|---------|--------|
| [README.md](README.md) | Agent contract & read order | exists |
| [INDEX.md](INDEX.md) | This catalog | exists |
| [10-context.md](10-context.md) | Golden Rule, constraints, assessment posture | exists |
| [20-requirements.md](20-requirements.md) | Acceptance criteria by part | exists |
| [30-architecture.md](30-architecture.md) | Compose → cluster → GitOps → app | exists |
| [40-implementation.md](40-implementation.md) | Repo tree, scripts, build sequence | exists |
| [50-operations.md](50-operations.md) | Runbook & failure modes | exists |
| [60-verification.md](60-verification.md) | How we prove done | exists |
| [70-decisions.md](70-decisions.md) | ADRs / trade-offs | exists |
| [80-source-map.md](80-source-map.md) | Path map (provided + planned) | exists |
| [90-part3-issues.md](90-part3-issues.md) | Part 3 defect catalog | exists |

## Assignment source & starter assets

| Path | Purpose | Status |
|------|---------|--------|
| [ASSIGNMENT - DevOps.md](../ASSIGNMENT%20-%20DevOps.md) | Original brief / scoring | exists |
| [troubleshoot/prepare.sh](../troubleshoot/prepare.sh) | Nodepool labels/taints | exists |
| [troubleshoot/broken-app.yaml](../troubleshoot/broken-app.yaml) | Part 3 broken workloads | exists |
| [troubleshoot/verify.sh](../troubleshoot/verify.sh) | Part 3 PASS gate | exists |
| [troubleshoot/smoke-job.yaml](../troubleshoot/smoke-job.yaml) | In-cluster smoke Job | exists |
| [ci/legacy.gitlab-ci.yml](../ci/legacy.gitlab-ci.yml) | Legacy CI to migrate (intent) | exists |

## Agent rules

| Path | Purpose | Status |
|------|---------|--------|
| [AGENTS.md](../AGENTS.md) | Project-wide agent instructions | exists |
| [.cursor/rules/planning-context.mdc](../.cursor/rules/planning-context.mdc) | Always-on Cursor rule | exists |

## CORE deliverables (planned)

| Path / artifact | Purpose | Status |
|-----------------|---------|--------|
| `docker-compose.yml` | k3d (≥4 agents) + toolbox | exists |
| `app/` (Python quote API) | Part 1 HTTP service | exists |
| `Dockerfile` (multi-stage, non-root) | Image build | exists |
| GHCR image tagged by git SHA | Public registry | planned (CI on public push) |
| `charts/quote-api/` (own Helm chart) | Part 2 deployable | exists |
| ArgoCD Application (via scripts) | GitOps sync of chart | exists |
| `scripts/00-*.sh` … `run-all.sh` | Idempotent numbered scripts | exists |
| `scripts/20-deploy.sh` | Install ArgoCD + Application | exists |
| `scripts/25-reclaim-drill.sh` | Spot drain / reschedule proof | exists |
| `troubleshoot/fixed-app.yaml` | Fixed Part 3 manifests | exists |
| `TROUBLESHOOTING.md` | Per-issue diagnosis narrative | exists |
| `README.md` (root) | Quick start, diagram, scripts, decisions | exists |
| `AI-USAGE.md` | AI disclosure | exists |

## Parts 4–6 + 7 (in scope)

| Path / artifact | Purpose | Status |
|-----------------|---------|--------|
| `.github/workflows/*.yml` | GHA build + Semgrep hard-fail + GHCR push | exists |
| `MIGRATION-NOTES.md` | GitLab → GHA migration rationale | exists |
| `infra/karpenter/` (or equiv.) | GPU NodePool + node class | exists |
| `infra/cloudflare/` (Terraform) | DNS, cache rule, `import` block | exists |
| `scripts/50-validate-tf.sh` | `fmt` / `init` / `validate` | exists |
| `scripts/60-loadtest.sh` | Prometheus/Grafana + k6 + HPA proof | exists |
| k6 script + Grafana dashboard JSON + screenshot | Part 6 evidence | exists (screenshot after local load) |
| PrometheusRule (app alert) | Meaningful alert | exists |
| `LOADTEST.md` | RPS / bottleneck / scale-first | exists |
| `OPS-ANSWERS.md` | Part 7 written answers | exists |
