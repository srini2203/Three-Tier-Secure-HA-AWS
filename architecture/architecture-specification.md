# Architecture Specification

## 1. Purpose & Scope

This document specifies the three-tier, highly available AWS
architecture implemented as Terraform in `../terraform/`. It covers
the network, compute, data, security, and monitoring design and the
reasoning behind each decision. For narrower deep-dives, see:

- `architecture/network` — VPC, subnet, and routing design
- `architecture/security` — IAM, security groups, and data protection
- `architecture/monitoring` — CloudWatch and SNS alarming
- `architecture/deployment` — how this gets deployed (Terraform workflow)

## 2. Goals

- Survive a single Availability Zone failure without manual
  intervention (compute and database tiers).
- No tier is reachable from the internet except the load balancer.
- No long-lived credentials anywhere in the system (EC2 uses IAM
  roles; the app reads DB credentials from Secrets Manager).
- Stay inside a single AWS account/region, at a scale and cost
  appropriate for a portfolio/learning project, not production
  traffic.

## 3. Non-Goals

- Multi-region / cross-region DR.
- Live production traffic — this repo is validate-only, not applied.
  See `docs/design-decisions.md`.
- CI/CD automation of `terraform apply`.

## 4. High-Level Architecture
Internet
                        |
                 [Internet Gateway]
                        |
                ┌───────┴────────┐
                │  Public subnets │  (2 AZs)
                │  Application    │
                │  Load Balancer  │
                └───────┬────────┘
                        | app_port
                ┌───────┴────────┐
                │ Private-app     │  (2 AZs)
                │ subnets — EC2   │
                │ in an ASG       │
                └───────┬────────┘
                        | db_port
                ┌───────┴────────┐
                │ Private-db      │  (2 AZs)
                │ subnets — RDS   │
                │ MySQL Multi-AZ  │
                └────────────────┘

See `architecture/network` for the full routing picture (NAT Gateway
placement, route tables) and `architecture/High level Diagram.png`
for the AWS-icon version of this diagram.

## 5. Tiers

### 5.1 Web tier — Application Load Balancer
- Internet-facing, spans both public subnets.
- Listens on HTTP:80, forwards to the app tier's target group.
- Health checks against `/` drive both ALB routing and ASG
  replacement decisions (`health_check_type = "ELB"`).

### 5.2 Application tier — EC2 in an Auto Scaling Group
- Amazon Linux 2023, launched from a Launch Template.
- No public IP; reachable only from the ALB security group.
- IMDSv2 enforced (`http_tokens = "required"`).
- Instance role grants Secrets Manager read access (DB credentials)
  and SSM (for shell access with no open port 22).
- Sized `asg_min_size` / `asg_max_size` / `asg_desired_capacity`
  (defaults: 2 / 4 / 2) across both AZs.

### 5.3 Data tier — RDS MySQL, Multi-AZ
- Private subnets, no route table (isolated by default, not just by
  security group rule — see `architecture/security`).
- Multi-AZ standby handles AZ failure with automatic failover; no
  read replicas (traffic profile doesn't need read scaling).
- Storage encrypted at rest with an AWS-managed KMS key.
- Master credentials generated with `random_password` and stored
  only in Secrets Manager, never in Terraform state as a plain
  variable value... other than inside the state file itself, which
  is why the S3 backend (commented out in `providers.tf`) should be
  encrypted when this project moves beyond local state.

## 6. Availability

| Component | HA mechanism | Single point of failure? |
|---|---|---|
| ALB | Multi-AZ by default | No |
| ASG | Spans 2 AZs | No |
| RDS | Multi-AZ standby, automatic failover | No |
| NAT Gateway | Single instance, one AZ | **Yes** — see `docs/tradeoffs.md` |

The NAT Gateway is the one deliberate single point of failure in this
design, traded off for cost. It only affects outbound internet from
the app tier (patching, external API calls); it does not affect
inbound traffic or the app-to-DB path.

## 7. Related Documents

| Topic | Location |
|---|---|
| Why each decision was made | `docs/design-decisions.md` |
| Explicit trade-offs | `docs/tradeoffs.md` |
| Security control matrix | `docs/security.md` / `architecture/security` |
| Cost estimate | `docs/cost-estimate.md` |
| Console-to-Terraform mapping | `docs/console-walkthrough.md` |
| Interview Q&A prep | `docs/interview-guide.md` |