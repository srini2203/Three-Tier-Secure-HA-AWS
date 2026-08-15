# Security Controls

| Layer | Control | Why |
|---|---|---|
| Network | 3-tier subnet isolation | App and DB tiers have no route to the internet |
| Network | Private DB subnets unassociated with any route table | Falls back to the VPC default table (local-only) — fully isolated by default, not by rule alone |
| Access | Security Groups scoped ALB -> App -> DB | Each tier reachable only from its designated upstream |
| Access | IMDSv2 enforced (`http_tokens = "required"`) | Blocks the SSRF-to-credential-theft path IMDSv1 allows |
| Access | SSM only, no SSH | No open port 22 anywhere in the design |
| Identity | IAM role on EC2, not hardcoded keys | Credentials never live in code or user-data |
| Data | RDS storage encrypted at rest | AWS-managed KMS key |
| Data | DB credentials in Secrets Manager, generated via `random_password` | Never a plaintext Terraform variable |

## Not yet covered (documented, not hidden)
- No WAF — the ALB is not yet behind a Web ACL (Future Improvements)
- No custom least-privilege IAM policy for Secrets Manager — using an
  AWS managed policy for now (see `design-decisions.md`)
- No live deployment, so no live-traffic security validation yet