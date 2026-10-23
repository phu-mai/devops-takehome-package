# AGENTS.md — project agent instructions

This repository is a DevOps take-home (Kubernetes, GitOps, CI/CD, IaC, load testing). **`planning/` is the authoritative source of project context** for every AI-assisted and human-assisted task.

The original brief is [`ASSIGNMENT - DevOps.md`](ASSIGNMENT%20-%20DevOps.md). Working interpretation, architecture, requirements, and verification live under [`planning/`](planning/).

## Required: start every task from planning/

Before implementing, diagnosing, refactoring, reviewing, testing, or writing submission docs:

1. Read [`planning/README.md`](planning/README.md) (agent contract).
2. Read [`planning/INDEX.md`](planning/INDEX.md) (catalog + artifact status).
3. Load the **smallest** additional set of planning docs for the task domain (see the table in `planning/README.md`).

Do **not** invent architecture, script names, placement rules, or CI gates from memory when they are already specified in `planning/`.

## Conflict resolution

If code, scripts, or docs **conflict** with `planning/`:

- **Stop** — do not silently pick one side.
- Reconcile: update planning to match a deliberate decision, or change code to match planning.
- Record decision changes in [`planning/70-decisions.md`](planning/70-decisions.md) and refresh [`planning/INDEX.md`](planning/INDEX.md) status when artifacts appear or paths move.

## After material changes

Update the relevant planning files in the **same session** as the change:

- Architecture / placement / ingress → `30-architecture.md`
- Scripts / tree / build order → `40-implementation.md`
- Ops / failure modes → `50-operations.md`
- Acceptance proof → `60-verification.md`
- New locked choice → `70-decisions.md`
- Path moves → `80-source-map.md` + `INDEX.md`

## Hard constraints

- Never commit secrets or credential-like values.
- Never remove or rewrite away [`troubleshoot/prepare.sh`](troubleshoot/prepare.sh) labeling/tainting intent.
- Never “fix” Part 3 by deleting the default-deny NetworkPolicy or by removing node labels/taints.
- Preserve the Golden Rule: `docker compose up -d` then `./scripts/run-all.sh` (or numbered scripts) without manual reviewer steps.

## Locked scope (see planning for detail)

- Language: **Python** quote API
- Cluster: **k3d** (≥4 agents) + toolbox
- Tracks: **CORE + Parts 4, 5, 6 + Part 7**
- Part 4 SAST: **Semgrep** hard-fail

## Cursor rule

An always-on rule mirrors this contract: [`.cursor/rules/planning-context.mdc`](.cursor/rules/planning-context.mdc). Keep it aligned with this file when the contract changes.
