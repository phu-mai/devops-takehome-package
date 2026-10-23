# Context & constraints

## Golden Rule (first gate)

Reviewers run **only**:

```bash
git clone <your-repo> && cd <your-repo>
docker compose up -d
./scripts/run-all.sh        # or scripts/NN-*.sh one by one
```

If that works **without reading documentation**, the first gate passes.

## Non-negotiables

1. **Public Git repo** (GitHub preferred).
2. **Public container registry** — GHCR; images tagged with **git SHA** (`latest` alone is insufficient).
3. **`docker-compose.yml` self-contained**: local Kubernetes with **≥4 worker nodes** (k3d recommended) **plus** a toolbox container (kubectl, helm, terraform, k6).
4. **Numbered scripts** in `./scripts/`, bind-mounted into the toolbox; **idempotent** (safe to re-run).
5. Bootstrap must run provided [`troubleshoot/prepare.sh`](../troubleshoot/prepare.sh) to label/taint nodepools.
6. Root `README.md` explains scripts, but reviewers must not *need* it to get a running system.

## Environment constraints

- **No cloud account** required. Everything runs locally in Docker.
- Terraform is **validate-only** (Part 5).
- **CNI:** Part 3 needs NetworkPolicy enforcement. k3d/k3s enforces out of the box; kind would need Calico/Cilium (we use k3d — see [70-decisions.md](70-decisions.md)).

## Assessment posture

- AI tools are encouraged; **verify** all AI output.
- If a provided file is broken, inconsistent, or missing: treat as a **production incident** — diagnose, decide, work around or fix, document in README / troubleshooting notes.
- Partial submissions with clear notes beat silent omissions.
- Do not commit secrets (instant fail). Do not require manual reviewer steps. Do not gold-plate; document cuts in README / [70-decisions.md](70-decisions.md).

## Simulated production nodepools

After `prepare.sh` (do not reverse these):

| Count | Labels / taints | Role |
|-------|-----------------|------|
| 2 | `acme.io/capacity=spot` | Prefer for cost (Part 2) |
| 1 | `acme.io/capacity=on-demand` | Availability anchor (Part 2) |
| 1 | `acme.io/node-type=gpu` + taint `nvidia.com/gpu=true:NoSchedule` | Part 3 AI workload only |

Part 2 quote-api must **not** land on the GPU node.
