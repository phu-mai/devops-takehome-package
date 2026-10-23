# Part 7 — Ops answers

## 1) EKS 1.33 → 1.35 zero-downtime upgrade

**Order:** (1) Read release notes / deprecated APIs for 1.34 and 1.35; fix in-cluster objects first. (2) Upgrade **add-ons that must track the control plane** carefully—typically upgrade **vpc-cni, kube-proxy, coredns**, then CSI (EBS/EFS) to versions that support the *target* Kubernetes version (or the skew AWS documents). (3) Upgrade the **EKS control plane** 1.33→1.34, validate, then 1.34→1.35 (one minor at a time). (4) **Node pools / Karpenter AMIs**: surge or blue/green nodegroups / NodePools so old nodes drain only after new Ready capacity exists; respect PDBs. (5) Re-validate add-ons and workloads (webhooks, CSI, DNS).

**Top 3 risks:** (a) Add-on / webhook incompatibility causing Pending pods or broken CNI mid-drain. (b) PDB + insufficient surge capacity → stuck drains / prolonged partial outage. (c) Deprecated API removals (CRDs/controllers) that only surface after the control plane moves.

## 2) Spot reclaim alert storms (`KubeNodeUnreachable`)

Treat spot interruption as **expected**. Alert on **symptom classes**, not every NotReady:

- Suppress or route `KubeNodeUnreachable`/`NodeNotReady` for nodes with spot labels / interruption taints to a low-urgency channel; require **multi-node** or **zone** failure for page.
- Page on **customer impact**: elevated error rate, SLO burn, Pending pods with `Insufficient` for on-demand capacity, or FailedSchedules for non-spot-tolerant critical Deployments.
- Keep a **real** node-failure signal: NotReady on **on-demand** / system nodegroups, or NotReady lasting beyond reclaim window **without** corresponding ASG/Karpenter replacement.

## 3) Cloudflare LCP 5s — HTML caching diagnosis

1. **Headers from edge:** `curl -sI https://site/` — check `cf-cache-status` (DYNAMIC/MISS/EXPIRED vs HIT), `cache-control`, `age`, `content-type`.
2. **Rules:** Confirm Cache Rules / Page Rules don’t bypass HTML; marketing HTML often set to bypass or respect origin `Cache-Control: no-store`.
3. **Origin:** Origin may send `no-cache`/`private` or `Set-Cookie` on HTML → Cloudflare won’t cache. Compare origin vs edge TTLs.
4. **HTML vs assets:** Assets may HIT while HTML is DYNAMIC—LCP element (hero image/font) might still be uncached or too large; check LCP resource waterfall.
5. **Fix direction:** Cache HTML with short edge TTL + stale-while-revalidate if content allows; strip unnecessary cookies on cacheable paths; optimize LCP asset; avoid Cloudflare “cache everything” without understanding Set-Cookie.

## 4) Secrets on EKS (multi-cluster startup)

**Compare:** (A) **Sealed Secrets / SOPS in Git** — encrypt in repo, decrypt in-cluster; simple, GitOps-friendly, key distribution and rotation are the hard parts. (B) **External Secrets Operator + cloud secret manager (AWS Secrets Manager / SSM)** — source of truth outside git; central rotation/IAM; needs IRSA per cluster and network to AWS APIs.

**Pick for multi-cluster startup:** **External Secrets + Secrets Manager** with IRSA. One secret inventory across clusters, IAM-scoped access, no sealed-key sprawl per cluster, and GitOps only stores `ExternalSecret` references—not ciphertext that is painful to rotate when a controller key is compromised.
