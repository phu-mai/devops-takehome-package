# Migration notes — GitLab CI → GitHub Actions

Source of intent (not a photocopy): [`ci/legacy.gitlab-ci.yml`](ci/legacy.gitlab-ci.yml).

## What changed and why

| Legacy practice | Migration | Why |
|-----------------|-----------|-----|
| `sonar_check` with `allow_failure: true` | **Semgrep** job with `--error` (hard-fail); no `continue-on-error` | A quality gate that cannot fail is decoration. Semgrep runs in CI without hosting Sonar in the compose harness. |
| `npm test \|\| echo "tests flaky, continuing"` | Removed flaky-continue pattern | Flaky-continue trains the pipeline to ignore signal. |
| Image tagged **`latest` only** | Tags with full **`GITHUB_SHA`** (and short SHA) on GHCR | Immutable, diggable releases; `latest` alone is insufficient per assignment. |
| AWS keys **inlined in YAML** | No cloud credentials in workflow; GHCR uses **`GITHUB_TOKEN`** via `docker/login-action` | Secrets in git/YAML are an instant fail; OIDC/`GITHUB_TOKEN` is the default path. |
| Deploy via `kubectl set image` + kubeconfig blob | **GitOps**: ArgoCD Application syncs the Helm chart from this repo | Matches Part 2; cluster state follows git, not a one-shot imperative mutate. |
| `only: master` + manual deploy | `push`/`pull_request` on `main`/`master`; image push on push | PRs still get Semgrep + build; publish on merge/push. |

## Migrating GitLab variables / secrets for a real project

1. **Inventory** GitLab CI/CD variables (masked/protected) and which jobs consume them.
2. **Classify**: build-time (registry login) vs runtime (app secrets in cluster) vs cloud deploy (AWS/GCP).
3. **Map to GitHub**:
   - Registry: prefer `GITHUB_TOKEN` + GHCR or OIDC to cloud registries.
   - Cloud: GitHub OIDC → cloud IAM role (no long-lived access keys in Actions secrets).
   - App secrets: External Secrets / Sealed Secrets / SOPS into the cluster — **not** baked into the workflow YAML.
4. **Delete** legacy keys from the GitLab file and rotate anything that was ever committed (the example AWS keys in the legacy file are documentation placeholders — still treat committed credentials as burned).
5. **Replace** imperative deploy jobs with GitOps: CI builds/pushes immutable tags; ArgoCD (or Flux) reconciles the chart/values that reference those tags.

## Out of scope / optional next

- Trivy HIGH/CRITICAL gate and cosign signing (assignment bonus) — not required for this submission; Semgrep + SHA tags are the locked gate.
