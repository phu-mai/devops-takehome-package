# Verification

Proof checklist for submission. Update evidence paths when artifacts land.

## Gate 0 — Golden Rule

- [ ] Fresh clone on a clean machine (or equivalent) succeeds with only:

  ```bash
  docker compose up -d
  ./scripts/run-all.sh
  ```

- [ ] No manual kubectl/helm steps required for CORE path.

## Part 1

- [ ] `/healthz`, `/readyz`, `/metrics`, `/api/quote` behave as specified.
- [ ] `/api/quote` shows measurable CPU work (~100ms).
- [ ] Image on GHCR: `…/quote-api:<git-sha>` (public).
- [ ] Dockerfile multi-stage; process non-root.

## Part 2

- [ ] ArgoCD installed; Application Healthy/Synced to **our** chart in this repo.
- [ ] HPA minReplicas ≥ 3; PDB present; securityContext + probes + resources.
- [ ] Pods prefer spot; ≥1 on on-demand; none on GPU; soft spread.
- [ ] `scripts/25-reclaim-drill.sh` exits 0; service answers during drain.
- [ ] Host `curl http://localhost:<port>/api/quote` succeeds.

## Part 3

- [ ] `./troubleshoot/verify.sh` prints `PASS` after applying `fixed-app.yaml`.
- [ ] Default-deny NP still present; node labels/taints intact.
- [ ] `TROUBLESHOOTING.md` covers each issue (symptom, commands, cause, fix).

## Documentation / AI

- [ ] Root `README.md`: quick start, architecture Mermaid, script reference, decisions, troubleshooting notes.
- [ ] `AI-USAGE.md` complete (tools, prompts, AI-wrong example).

## Part 4

- [ ] Public GHA runs green on main.
- [ ] Semgrep job **fails the pipeline** on findings (no allow_failure).
- [ ] Image push uses SHA tag.
- [ ] `MIGRATION-NOTES.md` explains intent migration from legacy GitLab.

## Part 5

- [ ] Karpenter manifests use **current** stable API (verified against docs at authoring time).
- [ ] Cloudflare TF includes proxied record, cache rules, `import` block.
- [ ] `scripts/50-validate-tf.sh` passes `fmt -check`, `init -backend=false`, `validate`.

## Part 6

- [ ] Prometheus scrapes app `/metrics`; Grafana reachable as documented.
- [ ] k6 thresholds justified from baseline in `LOADTEST.md`.
- [ ] Evidence of HPA scaling >3 and placement still respected.
- [ ] PrometheusRule committed; threshold justified.
- [ ] Dashboard JSON + screenshot taken **during** load.
- [ ] `LOADTEST.md`: RPS, bottleneck, scale-first recommendation.

## Part 7

- [ ] `OPS-ANSWERS.md` answers all four questions within length guidance.

## Planning hygiene

- [ ] [`INDEX.md`](INDEX.md) statuses flipped from `planned` → `exists` as artifacts land.
- [ ] Material design changes reflected in [30](30-architecture.md)/[40](40-implementation.md)/[70](70-decisions.md).
