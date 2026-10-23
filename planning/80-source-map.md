# Source map

Pointers from concern → path. Prefer updating this when paths change.

## Provided (do not treat as “ours to rewrite” unless fixing Part 3)

| Concern | Path |
|---------|------|
| Assignment brief | [`ASSIGNMENT - DevOps.md`](../ASSIGNMENT%20-%20DevOps.md) |
| Nodepool prep | [`troubleshoot/prepare.sh`](../troubleshoot/prepare.sh) |
| Broken workloads | [`troubleshoot/broken-app.yaml`](../troubleshoot/broken-app.yaml) |
| Part 3 verifier | [`troubleshoot/verify.sh`](../troubleshoot/verify.sh) |
| Smoke Job | [`troubleshoot/smoke-job.yaml`](../troubleshoot/smoke-job.yaml) |
| Legacy GitLab CI | [`ci/legacy.gitlab-ci.yml`](../ci/legacy.gitlab-ci.yml) |

## Agent / planning

| Concern | Path |
|---------|------|
| Agent contract | [`AGENTS.md`](../AGENTS.md) |
| Cursor always-on rule | [`.cursor/rules/planning-context.mdc`](../.cursor/rules/planning-context.mdc) |
| Planning hub | [`planning/README.md`](README.md) |
| Catalog | [`planning/INDEX.md`](INDEX.md) |

## Implementation paths

| Concern | Path |
|---------|------|
| Compose harness | `docker-compose.yml`, `Dockerfile.toolbox` |
| Quote API | `app/` |
| Container build | `Dockerfile` |
| Helm chart | `charts/quote-api/` |
| ArgoCD Application | `argocd/application.yaml` (+ live apply in `scripts/20-deploy.sh`) |
| Numbered scripts | `scripts/` |
| Fixed Part 3 manifests | `troubleshoot/fixed-app.yaml` |
| Part 3 narrative | `TROUBLESHOOTING.md` |
| GitHub Actions | `.github/workflows/ci.yml` |
| Migration notes | `MIGRATION-NOTES.md` |
| Karpenter | `infra/karpenter/` |
| Cloudflare Terraform | `infra/cloudflare/` |
| TF validate script | `scripts/50-validate-tf.sh` |
| Load test / dashboards | `loadtest/`, `scripts/60-loadtest.sh` |
| Load test write-up | `LOADTEST.md` |
| Ops answers | `OPS-ANSWERS.md` |
| Submission README | `README.md` (root) |
| AI disclosure | `AI-USAGE.md` |

## External artifacts

| Concern | Location |
|---------|----------|
| Container image | `ghcr.io/<owner>/<image>:<git-sha>` (set when repo/owner known) |
| Public git remote | TBD at publish time |
