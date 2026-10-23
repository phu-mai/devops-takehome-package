# Planning — agent contract

`planning/` is the **authoritative working context** for this DevOps take-home. The original brief lives in [`ASSIGNMENT - DevOps.md`](../ASSIGNMENT%20-%20DevOps.md). This folder is the interpreted contract: architecture, requirements, implementation sequence, ops constraints, and verification.

When planning and code disagree, **stop and reconcile** — update planning or code; never silently diverge.

## Mandatory read order

Before any implementation, diagnosis, refactor, or documentation rewrite:

1. Read this file.
2. Read [`INDEX.md`](INDEX.md).
3. Load the smallest additional set for the task domain:

| Task domain | Read next |
|-------------|-----------|
| Scope / scoring / deliverables | [`20-requirements.md`](20-requirements.md) |
| Cluster, GitOps, placement, ingress | [`30-architecture.md`](30-architecture.md) |
| App, scripts, Helm, CI, IaC, load test | [`40-implementation.md`](40-implementation.md) |
| Reviewer runbook, failure modes | [`50-operations.md`](50-operations.md) |
| Acceptance / proof artifacts | [`60-verification.md`](60-verification.md) |
| Why we chose X | [`70-decisions.md`](70-decisions.md) |
| Where files live | [`80-source-map.md`](80-source-map.md) |
| Part 3 broken-app diagnosis | [`90-part3-issues.md`](90-part3-issues.md) |
| Constraints / Golden Rule | [`10-context.md`](10-context.md) |

For broad work, also skim [`10-context.md`](10-context.md) and [`20-requirements.md`](20-requirements.md).

## When to update planning

Update the relevant docs (and refresh [`INDEX.md`](INDEX.md) status) when you change:

- Architecture, nodepools, placement, or ingress path
- Script names, order, or bootstrap behavior
- Language, image tagging, registry, or Helm chart shape
- CI/CD gates, Karpenter/Cloudflare IaC, or observability stack
- Part 3 fix approach or verification evidence
- Locked decisions (add an ADR entry in [`70-decisions.md`](70-decisions.md))

## Hard constraints (never violate)

- No secrets in git.
- Do not modify [`troubleshoot/prepare.sh`](../troubleshoot/prepare.sh) node labeling/tainting intent.
- Do not remove node labels/taints or the default-deny NetworkPolicy to “fix” Part 3.
- Reviewer path must work: `docker compose up -d` then `./scripts/run-all.sh` (or numbered scripts) with no manual steps.

## Locked product decisions

- Part 1 language: **Python**
- Local cluster: **k3d** (≥4 agents) + toolbox
- Hands-on tracks: **Parts 4, 5, and 6** (CORE + Part 7 required)
- Part 4 SAST: **Semgrep** (hard-fail; no allow_failure)
