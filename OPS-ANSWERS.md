# Part 7 — Ops answers

## 1) EKS 1.33 → 1.35 zero-downtime upgrade

**Order:** (1) Read release notes / deprecated APIs for 1.34 and 1.35; fix in-cluster objects first. (2) Upgrade **add-ons that must track the control plane** carefully—typically upgrade **vpc-cni, kube-proxy, coredns**, then CSI (EBS/EFS) to versions that support the *target* Kubernetes version (or the skew AWS documents). (3) Upgrade the **EKS control plane** 1.33→1.34, validate, then 1.34→1.35 (one minor at a time). (4) **Node pools / Karpenter AMIs**: surge or blue/green nodegroups / NodePools so old nodes drain only after new Ready capacity exists; respect PDBs. (5) Re-validate add-ons and workloads (webhooks, CSI, DNS).

**Top 3 risks:** (a) Add-on / webhook incompatibility causing Pending pods or broken CNI mid-drain. (b) PDB + insufficient surge capacity → stuck drains / prolonged partial outage. (c) Deprecated API removals (CRDs/controllers) that only surface after the control plane moves.

## 2) Spot reclaim alert storms (`KubeNodeUnreachable`)

### Alerting Strategy
* **Lifecycle-Aware Labeling & Filtering:** Tag Spot worker nodes with a dedicated label (`lifecycle: spot`). Configure Prometheus alerting rules to either exclude `lifecycle: spot` nodes from immediate unreachability alerts or apply distinct thresholds.
* **Time-Based Hysteresis (`for` duration):** Increase the evaluation delay (`for: 5m` or `10m`) for single-node unreachability, while maintaining rapid alerting (`for: 0m`) only when multiple nodes across distinct AZs fail simultaneously (indicating a broader zone outage).

## 3) Cloudflare LCP 5s — HTML caching diagnosis

11. **Inspect Response Headers (`CF-Cache-Status`):** Use `curl -I https://example.com` or browser dev tools to inspect the response headers. If `CF-Cache-Status` returns `DYNAMIC`, `BYPASS`, or is missing entirely, Cloudflare is serving the HTML straight from the origin.
2. **Examine Origin Cache-Control & Cookies:** Check if the origin server sends `Cache-Control: private, no-store` or emits a `Set-Cookie` header. By default, Cloudflare automatically bypasses cache if `Set-Cookie` is present to prevent leaking user sessions.
3. **Verify Cloudflare Cache Rules:** Confirm whether a Cache Rule or Page Rule exists for the root path and `.html` extensions. By default, Cloudflare does **not** cache static HTML extensions without explicit configuration.
4. **Implement Fixes:**
   * Create a Cache Rule matching the marketing paths with **Cache Everything** enabled.
   * Set an Edge Cache TTL (e.g., 4 hours) and enable **Respect Origin Headers: No** (or configure cache key settings to ignore query strings and cookies for anonymous page views).
   * Ensure origin drops unnecessary `Set-Cookie` headers for unauthenticated visitors. 
   * *Result:* Origin TTFB drops from ~2–3s to <50ms (edge delivery), immediately collapsing LCP below 2.5s.

## 4) Application Secrets on EKS: Comparison & Selection

### Approach A: Native Kubernetes Secrets + External Secrets Operator (ESO)
* **Mechanism:** Secrets are stored securely in a dedicated external vault (AWS Secrets Manager or SSM Parameter Store). The External Secrets Operator syncs them into native Kubernetes `Secret` objects inside the cluster.
* **Pros:** Native Kubernetes developer experience (`kubectl get secrets`, standard envVar or volume-mount injection); leverages robust AWS IAM, native audit logging, and automated rotation out-of-the-box.
* **Cons:** Secrets exist as standard base64-encoded Kubernetes secrets at rest in etcd (unless etcd encryption at rest is explicitly enabled).

### Approach B: HashiCorp Vault + Vault Agent Injector
* **Mechanism:** Vault manages all secrets. An admission webhook injects a sidecar container into pods to fetch and render secrets into shared memory volumes.
* **Pros:** Highly granular dynamic secrets (e.g., auto-expiring database credentials), advanced multi-cloud secret management, and fine-grained ACLs.
* **Cons:** High operational complexity. Running, scaling, backing up, and maintaining a highly available Vault cluster across multiple production EKS clusters introduces significant operational overhead for a startup.

### Selected Approach for a Startup
**Approach A (Kubernetes Secrets + External Secrets Operator backed by AWS Secrets Manager)** is the optimal choice. Startups require maximum engineering velocity and minimal operational toil. ESO provides a secure, zero-infrastructure-overhead bridge between AWS-managed secret storage and native Kubernetes workloads across multiple clusters without requiring an on-cluster stateful secret management cluster.