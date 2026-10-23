# Architecture

## Local harness (reviewer path)

```mermaid
flowchart TB
  Host[Host_machine]
  Compose[docker_compose]
  K3d[k3d_cluster]
  Toolbox[toolbox_container]
  Prepare[troubleshoot_prepare_sh]
  Spot1[spot_node_1]
  Spot2[spot_node_2]
  OD[on_demand_node]
  GPU[gpu_node_tainted]
  Argo[ArgoCD]
  AppChart[Helm_chart_quote_api]
  Ingress[Ingress_controller]
  Quote[quote_api_pods]

  Host -->|compose_up| Compose
  Compose --> K3d
  Compose --> Toolbox
  Toolbox -->|bind_mount_scripts| Scripts[scripts_NN]
  Scripts --> Prepare
  Prepare --> Spot1
  Prepare --> Spot2
  Prepare --> OD
  Prepare --> GPU
  K3d --> Spot1
  K3d --> Spot2
  K3d --> OD
  K3d --> GPU
  Scripts -->|20_deploy| Argo
  Argo -->|Application_sync| AppChart
  AppChart --> Quote
  Quote -->|prefer_spot_require_OD| Spot1
  Quote -->|prefer_spot_require_OD| Spot2
  Quote -->|at_least_one| OD
  Host -->|curl_localhost_port| Ingress
  Ingress --> Quote
```

## Components

| Piece | Role |
|-------|------|
| `docker-compose.yml` | Starts k3d (≥4 agents) + toolbox; mounts `./scripts` (and repo as needed) |
| Toolbox | kubectl, helm, terraform, k6; runs numbered scripts |
| k3d/k3s | Local Kubernetes; NetworkPolicy enforced (Part 3) |
| `prepare.sh` | Labels 2 spot, 1 on-demand, 1 GPU+taint |
| ArgoCD | Installs via script; Application points at repo Helm chart |
| Helm chart `quote-api` | Deployment, Service, Ingress, HPA, PDB, securityContext, affinity |
| Ingress | Host-reachable `http://localhost:<port>/api/quote` |

## Placement policy (Part 2)

With **minReplicas 3** (HPA):

1. **Prefer spot** — weighted node affinity / preferredDuringScheduling for `acme.io/capacity=spot`.
2. **Require one on-demand** — pod anti-affinity / topology or dedicated preferred + required mix so at least one replica schedules on `acme.io/capacity=on-demand` (e.g. soft prefer spot + a required “spread” or a second affinity schedule that keeps OD occupied — implement carefully; document in chart values).
3. **Soft topology spread** (`whenUnsatisfiable: ScheduleAnyway`) across `kubernetes.io/hostname` so reclaim/drain still allows reschedule.
4. **Avoid GPU** — do not match GPU labels; no toleration for `nvidia.com/gpu`.

Hard constraints that pin *all* pods to on-demand defeat the exercise.

## Ingress path

Host → published compose/k3d port → cluster Ingress → Service → Pods → `/api/quote`.

Exact port chosen at implementation time; document in root README and scripts.

## Part 6 observability overlay

kube-prometheus-stack scrapes ServiceMonitor / annotations on quote-api `/metrics`. Grafana dashboard + PrometheusRule live in-cluster; k6 hits the same Ingress URL.

## Bonus: production AWS outline (for root README)

Not implemented locally; diagram-only:

```mermaid
flowchart LR
  Users[Users]
  CF[Cloudflare_CDN_DNS]
  ALB[ALB_Ingress]
  EKS[EKS]
  SpotPool[Karpenter_spot]
  ODPool[Karpenter_on_demand]
  GPUPool[Karpenter_GPU]
  RDS[RDS]
  Prom[AMP_or_Prometheus]
  Users --> CF --> ALB --> EKS
  EKS --> SpotPool
  EKS --> ODPool
  EKS --> GPUPool
  EKS --> RDS
  EKS --> Prom
```

Boxes: EKS control plane; Karpenter nodepools (spot / OD / GPU); app Deployments; Cloudflare → ALB/NLB Ingress; RDS if stateful later; metrics/traces → managed Prometheus / OpenTelemetry.
