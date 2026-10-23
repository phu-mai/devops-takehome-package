# Karpenter GPU NodePools (Part 5a)

Validate-only design for EKS GPU inference.

## Spot vs on-demand for AI inference

Spot GPU capacity is often 50–70% cheaper, but reclaim interrupts long inference jobs and can strand in-flight requests. Prefer spot (`weight: 100`) for cost, keep a smaller on-demand pool (`weight: 10`) as fallback when spot is unavailable, and use `consolidationPolicy: WhenEmpty` with a long `consolidateAfter` so Karpenter does not drain a busy inference node mid-request. Critical interactive/SLA-bound inference should pin to on-demand (or reserved) capacity; batch/async jobs can ride spot with checkpointing.

## Apply (production only)

These manifests are **not** applied by the local compose harness. After Karpenter is installed on EKS:

```bash
kubectl apply -f infra/karpenter/
```
