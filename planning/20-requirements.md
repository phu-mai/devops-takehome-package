# Requirements & acceptance criteria

Scope locked: **CORE (Parts 1–3 + docs) + Parts 4, 5, 6 + Part 7**.

## CORE — Part 1: Quote API

Python HTTP API (~100 lines) exposing:

| Endpoint | Behavior |
|----------|----------|
| `GET /healthz` | Liveness |
| `GET /readyz` | Readiness |
| `GET /metrics` | Prometheus format; ≥1 custom counter (e.g. requests total) |
| `GET /api/quote` | Random motivational quote as JSON; **~100ms simulated CPU work** per request |

Also:

- Multi-stage Dockerfile; runs as **non-root**; sensible image size.
- Image on GHCR tagged with **git SHA**.

## CORE — Part 2: GitOps + placement

Via `scripts/20-deploy.sh`:

1. Install ArgoCD; deploy service via ArgoCD `Application` syncing **our Helm chart from this repo** (no manual `helm install` of the app).
2. Own Helm chart: probes, requests/limits, `securityContext` (non-root, read-only rootfs), Service + Ingress, **HPA minReplicas: 3**, PodDisruptionBudget.
3. Placement with 3 replicas:
   - Prefer **spot** (cost).
   - **≥1 replica always on on-demand** (availability).
   - Soft topology spread across nodes (rescheduling must still work when a node disappears).
   - Hard-pinning all replicas to on-demand = score zero. Avoid GPU node.
4. `scripts/25-reclaim-drill.sh`: drain one spot node, prove service still answers (`curl` loop), show pods rescheduling, uncordon.
5. After deploy: `curl http://localhost:<port>/api/quote` from host works.

## CORE — Part 3: Troubleshooting

1. Ensure `prepare.sh` ran (compose bootstrap).
2. Apply `troubleshoot/broken-app.yaml`.
3. Fix until `./troubleshoot/verify.sh` prints `PASS`.
4. Rules: keep default-deny NP (add least-privilege allows); do not remove node taints/labels; commit fixes as `troubleshoot/fixed-app.yaml`.
5. `TROUBLESHOOTING.md`: symptom, commands, root cause, fix per issue.

Defect catalog (pre-diagnosed): [90-part3-issues.md](90-part3-issues.md).

## CORE — Documentation

Root `README.md` must include:

1. Quick start (matches Golden Rule).
2. Architecture diagram (Mermaid or image).
3. Script reference (one line each).
4. Design decisions & trade-offs.
5. Troubleshooting notes (2–3 reviewer machine issues).

Bonus: production AWS diagram (EKS, nodepools, RDS, CDN, observability).

## CORE — AI disclosure

`AI-USAGE.md`: tools used, 2–3 real prompts, ≥1 AI wrong/suboptimal example + how caught.

## Part 4 — CI/CD migration

- Working GitHub Actions: build Part 1 image → GHCR with SHA tags.
- Static SAST that **hard-fails** on findings: **Semgrep** (locked).
- Do not preserve legacy `allow_failure` / flaky-continue / secrets-in-YAML spirit.
- `MIGRATION-NOTES.md`: what changed and why; how to migrate GitLab variables/secrets for real projects.
- Bonus (optional): Trivy HIGH/CRITICAL gate, cosign signing.

## Part 5 — IaC (validate-only)

**5a Karpenter (current stable API):** GPU NodePool + node class; spot preferred / on-demand fallback (weights); `nvidia.com/gpu:NoSchedule`; consolidation safe for long inference; sensible limits; short spot vs OD paragraph.

**5b Cloudflare Terraform:** proxied DNS `quote-api.example.com`; cache rule bypass `/api/*`, aggressive static cache; `import` block for pre-existing record; `scripts/50-validate-tf.sh` runs `fmt -check`, `init -backend=false`, `validate`.

## Part 6 — Load test & observability

Via `scripts/60-loadtest.sh`:

1. Prometheus + Grafana (kube-prometheus-stack); scrape app `/metrics`.
2. k6 through Ingress with thresholds justified from measured baseline.
3. Prove HPA scale-out beyond 3; new replicas respect Part 2 placement.
4. One meaningful PrometheusRule; justify threshold from load observations.
5. Grafana dashboard JSON (3–4 panels) + screenshot **during** load test.
6. `LOADTEST.md`: max sustainable RPS, bottleneck, what to scale first in prod.

## Part 7 — Ops questions

`OPS-ANSWERS.md` (max ~1.5 pages): EKS 1.33→1.35 upgrade; spot reclaim alert storms; Cloudflare LCP/HTML cache diagnosis; EKS secrets comparison + pick for multi-cluster startup.

## Explicit out of scope / cut list

- No live AWS/Cloudflare apply (validate-only for TF).
- No copying a full third-party Helm chart as “ours.”
- No gold-plated APM unless time allows (bonus only).
- No secrets, kubeconfig blobs, or credential examples beyond placeholder docs.
- No rewriting `prepare.sh` or stripping verify-checked labels/taints/default-deny.
