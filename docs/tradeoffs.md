# Trade-offs

## Single NAT Gateway vs. one per AZ
Chose one for cost. Risk: an AZ outage on the NAT's AZ removes outbound
internet from the app subnet in the other AZ. App availability itself
is unaffected — inbound via ALB and the DB path don't route through NAT.

## Multi-AZ RDS vs. Single-AZ
Chose Multi-AZ for automatic failover — the standard HA pattern for a
"highly available" architecture. Trade-off: not covered by AWS free
tier, so this specific setting would cost real money if deployed as-is.

## Flat Terraform vs. modules
Chose flat for readability at this project's scope. Trade-off: doesn't
demonstrate module design or reuse patterns — a deliberate scope
decision for a fresher-level project, not an oversight (see
`design-decisions.md`).

## Validate-only vs. live deployment
Chose validate-only to avoid cost and operational risk. Trade-off: no
live-traffic evidence (no real failover test, no real load test) — the
console screenshots substitute hands-on evidence for that gap.