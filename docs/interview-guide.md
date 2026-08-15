# Interview Guide

## Why Terraform?
Infrastructure as Code — repeatable, version-controlled, and
reviewable before anything is created, unlike manual console changes.

## Why three tiers / private subnets?
Limits blast radius — a compromised app instance can't directly reach
the internet with data, and the DB is never internet-facing at all.

## Why Multi-AZ RDS?
Automatic failover to a standby replica in a second AZ if the primary
fails — no manual intervention needed.

## Why one NAT Gateway instead of two?
Cost trade-off — see `tradeoffs.md`. App availability doesn't depend on
it; only outbound internet from the app tier does.

## Why IAM roles instead of access keys on EC2?
No credentials to leak from the instance — the role is assumed via the
instance profile, temporary credentials only.

## Why is this project not deployed live?
Deliberate choice to avoid ongoing AWS cost for a portfolio piece.
`terraform validate` confirms correctness; the console screenshots
demonstrate hands-on familiarity with the same services from SAA study.

## What would you change for a real production deployment?
Add a WAF on the ALB, tighten the Secrets Manager IAM policy to one
specific ARN, add a second NAT Gateway for full AZ independence, and
actually deploy + load test it.

## Where's the single point of failure?
The NAT Gateway (see `tradeoffs.md`) — everything else has AZ redundancy.