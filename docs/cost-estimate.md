# Cost Estimate

Since this isn't deployed live, this is a planning estimate — the kind
of exercise an SA does *before* provisioning, not a bill.

| Service | Configuration | Est. Monthly Cost (USD) |
|---|---|---|
| NAT Gateway | 1x + data processing | ~$35 + $0.045/GB |
| ALB | 1x + LCU usage | ~$20 |
| EC2 (ASG) | 2x t3.micro | ~$15 (or $0 on free tier for the first 12 months) |
| RDS | db.t3.micro, Multi-AZ | ~$28 (or $0 on free tier, Single-AZ only) |
| Secrets Manager | 1 secret | ~$0.40 |
| CloudWatch | 1 alarm + basic metrics | ~$1 |
| **Estimated total** | | **~$100/month** (non-free-tier) |

## Free Tier Notes
- EC2 `t3.micro`/`t2.micro`: free for 12 months, 750 hrs/month
- RDS `db.t3.micro`: free for 12 months, **Single-AZ only** — Multi-AZ
  is not covered by free tier, so `db_multi_az = true` in this repo
  would incur real cost if actually applied
- NAT Gateway: **not** covered by free tier at all — this is the
  single biggest cost driver in this architecture

## Optimization Candidates (if deployed)
- Switch `db_multi_az` to `false` for a free-tier-only dev deployment
- Replace the NAT Gateway with a NAT instance for near-zero cost at
  small scale (trade-off: no longer AWS-managed, so more operational burden)