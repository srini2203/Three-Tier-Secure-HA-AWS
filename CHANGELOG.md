# Changelog

## [1.0.0] — Locked
- Initial architecture: VPC (3-tier, 2 AZs), ALB + ASG, RDS Multi-AZ,
  Secrets Manager, IAM roles, CloudWatch + SNS.
- Terraform written flat (no modules) for readability at this project's
  scope. Validated via `terraform validate`, not deployed live.
- Console screenshots from hands-on SAA study added, mapped to
  Terraform files in `docs/console-walkthrough.md`.