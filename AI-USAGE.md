# AI usage disclosure

## Tools

- **Cursor (Composer / agent)** — primary pair-programmer for scaffolding compose/toolbox, Helm chart, scripts, Part 3 fixes, CI, Terraform, and docs from the `planning/` contract.
- Planning docs in `planning/` were treated as authoritative (not re-invented from memory).

## Representative prompts that moved work forward

1. “Read `planning/README.md`, `INDEX.md`, and the domain docs; implement CORE + Parts 4–6 + 7 so `docker compose up -d` then `./scripts/run-all.sh` works.”
2. “Pre-diagnose `troubleshoot/broken-app.yaml` into a defect catalog and produce `fixed-app.yaml` without deleting default-deny or removing GPU taints.”
3. “Migrate `ci/legacy.gitlab-ci.yml` intent to GitHub Actions with Semgrep hard-fail and GHCR SHA tags — do not photocopy allow_failure / latest-only / secrets-in-YAML.”

## Where AI was wrong or suboptimal (and how caught)

**Example:** An early deploy sketch suggested **disabling Traefik** on k3d (`--k3s-arg --disable=traefik`) while still expecting host `curl http://localhost:8080/api/quote` via Ingress. That would break the Ingress path.

**Caught by:** Cross-check against `planning/30-architecture.md` (Ingress → Service → Pods) and k3d port-map semantics (`8080:80@loadbalancer` needs an Ingress controller).

**Fix:** Leave default Traefik enabled; publish `8080:80@loadbalancer`; use a Traefik-compatible Ingress in the Helm chart.

**Second catch:** Chart `ServiceMonitor` enabled by default would fail ArgoCD sync before kube-prometheus-stack CRDs exist. Deferred ServiceMonitor to `scripts/60-loadtest.sh` / `loadtest/servicemonitor.yaml`.
