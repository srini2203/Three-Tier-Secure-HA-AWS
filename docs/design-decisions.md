# Design Decisions

## Flat Terraform, no modules
**Decision:** every resource lives directly in `terraform/*.tf`, no
`module` blocks.
**Why:** modules add a real layer of indirection (variable passing,
output wiring across boundaries) that's worth it once a project reaches
team/reuse scale. At this project's size, flat files are easier to read
top-to-bottom and easier to defend line-by-line in an interview.

## Validate-only, not deployed
**Decision:** `terraform validate` and `terraform plan` are run; `apply`
is not.
**Why:** avoids ongoing AWS cost for a project that exists to
demonstrate design and IaC competence, not to serve real traffic.
Documented explicitly in the README so it's never ambiguous.

## Single NAT Gateway
**Decision:** one NAT Gateway, not one per AZ.
**Why:** halves NAT cost. Trade-off: if that AZ has an issue, the app
subnet in the other AZ loses outbound internet until it recovers — the
app itself stays reachable via the ALB regardless, since inbound
traffic and the DB path don't depend on NAT.

## RDS Multi-AZ, no read replicas
**Decision:** Multi-AZ standby for failover; no read replicas.
**Why:** this project's traffic profile doesn't need read scaling —
Multi-AZ solves the actual requirement (survive an AZ failure) without
extra complexity.

## AWS managed IAM policy for Secrets Manager (not custom JSON)
**Decision:** `SecretsManagerReadWrite` managed policy on the EC2 role.
**Why:** kept the code readable for this scope. Scoping it down to one
specific secret ARN is a known, documented "v2" tightening — listed
under Future Improvements, not hidden.