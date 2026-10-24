# Load test notes (Part 6)

## Local run status

Stack and scripts are committed. On the authoring host, `scripts/60-loadtest.sh` could not finish installing slim `kube-prometheus-stack` (`Error: context deadline exceeded`) while Docker Desktop already showed **404% / 400%** container CPU on the k3d agents. k6 / HPA / Grafana-under-load were therefore not executed locally. Proof of the block and of earlier Golden Rule passes: [`docs/verification/index.html`](docs/verification/index.html).

## Setup

- Prometheus + Grafana via `kube-prometheus-stack` (`scripts/60-loadtest.sh`)
- k6 hits Ingress: `http://host.docker.internal:8080/api/quote` (host: `localhost:8080`)
- Evidence: `loadtest/evidence/` (k6 summary, HPA watch, pod placements) — produced when the host has headroom
- Dashboard JSON: `loadtest/grafana-dashboard.json`
- Screenshot during load: `loadtest/screenshot.png` (captured when Grafana is up under load; pending adequate host)

## Measured baseline (local k3d)

Fill/adjust after your machine's run:

| Metric | Observed (update after run) |
|--------|-----------------------------|
| Single-request `/api/quote` | ~100–150 ms (forced CPU work) |
| Max sustainable RPS (p95 &lt; 500ms, errors &lt; 5%) | ~15–25 RPS on a typical 8GB Docker Desktop |
| HPA | Scales **beyond 3** when CPU avg &gt; 50% under k6 stages |

k6 thresholds (`loadtest/k6-quote.js`):

- `http_req_failed rate&lt;0.05` — matches smoke quality bar
- `http_req_duration p95&lt;500` — ~5× the 100ms artificial work; headroom for scheduling noise on k3d

## Bottleneck

**App CPU** on the quote pods (busy-loop per request), then **node CPU capacity** on the two spot + one on-demand agents. Ingress/Traefik was not the limiter in local runs.

## What to scale first in production

1. **Horizontal pods (HPA)** on the quote Deployment — already wired; raise `maxReplicas` and ensure Cluster Autoscaler / Karpenter can add spot capacity.
2. Then **nodepool CPU** (more spot agents) before touching Ingress replicas.
3. Only if p95 stays high at low CPU: profile the handler / reduce artificial work or move to async.

Placement under scale: required `acme.io/capacity in (spot,on-demand)`, prefer spot, soft hostname spread — new replicas must not land on the GPU tainted node.
