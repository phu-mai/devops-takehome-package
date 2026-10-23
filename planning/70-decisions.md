# Decisions (ADRs)

Short locked decisions. Add new entries when choices change; do not silently diverge in code.

## ADR-001 — Python for Part 1

**Decision:** Implement quote-api in **Python** (FastAPI preferred at implement time).

**Why:** Fast to write ~100-line HTTP + metrics; fine for take-home; reviewers can read quickly.

**Trade-off:** Larger image than Go; mitigate with slim multi-stage image and non-root user.

## ADR-002 — k3d, not kind

**Decision:** Local cluster via **k3d** with ≥4 agents inside compose.

**Why:** Agents are containers; NetworkPolicy works out of the box (k3s); assignment recommends k3d.

**Trade-off:** Docker-in-Docker / nested complexity in compose — keep toolbox separate and document resource needs.

## ADR-003 — Semgrep as SAST gate (Part 4)

**Decision:** Use **Semgrep** with hard-fail on findings (not SonarQube CE in compose, not SonarCloud).

**Why:** Real failing gate without hosting Sonar in the harness; avoids legacy `allow_failure: true` spirit.

**Trade-off:** Different product than legacy Sonar job — migration notes must explain intent (quality gate that can fail), not photocopy.

## ADR-004 — Soft topology spread + weighted spot preference

**Decision:** Prefer spot via **weights**; keep **≥1** replica on on-demand; use **soft** topology spread (`ScheduleAnyway`).

**Why:** Reclaim drill must reschedule when a spot node disappears; hard spread/pins cause Pending storms or OD-only pinning (score zero).

## ADR-005 — ArgoCD syncs chart from this repo

**Decision:** App deploys only via ArgoCD Application → Helm chart path in **this** public repo.

**Why:** Matches assignment; demonstrates GitOps over `kubectl set image` (legacy CI anti-pattern).

## ADR-006 — All three optional tracks in scope

**Decision:** Implement Parts **4, 5, and 6** after CORE; Part 7 required.

**Why:** User-locked scope for planning; sequence CORE first so optional tracks do not starve the Golden Rule.

**Cut rule:** If time pressure appears, finish CORE + one track cleanly before polishing bonuses (Trivy/cosign/APM). Prefer documenting cuts in root README over half-broken tracks.

## ADR-007 — Planning folder is working contract

**Decision:** `planning/` + `AGENTS.md` + always-on Cursor rule govern AI/human work.

**Why:** Starter package is sparse; without a single context root, agents will re-derive conflicting architectures.

**Update rule:** Material changes update planning in the same PR/session as code.

## ADR-008 — Host Ingress on port 8080

**Decision:** Publish k3d load balancer `8080:80` (Traefik left enabled).

**Why:** Stable reviewer curl URL `http://localhost:8080/api/quote` without disabling the default Ingress controller.

## ADR-009 — In-cluster git-daemon for local ArgoCD

**Decision:** `20-deploy.sh` seeds an in-cluster `git daemon` with a bare clone of the workspace so ArgoCD syncs `charts/quote-api` without requiring a public remote for the Golden Rule.

**Why:** Reviewers must get a Synced Application before GitHub is public. After publish, switch `repoURL` to GitHub; same chart path.

## ADR-010 — ServiceMonitor after kube-prometheus-stack

**Decision:** Chart `serviceMonitor.enabled=false` by default; Part 6 applies `loadtest/servicemonitor.yaml`.

**Why:** Avoid ArgoCD sync failures when `monitoring.coreos.com` CRDs are not installed yet.
