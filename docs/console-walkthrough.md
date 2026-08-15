# Console Walkthrough

Each screenshot below is from hands-on AWS console configuration during
SAA study, mapped to the Terraform file that expresses the same setup.

| Screenshot | Terraform file | What it shows |
|---|---|---|
| `01-vpc-and-subnets.png` | `vpc.tf` | VPC with public/private-app/private-db subnet split across 2 AZs |
| `02-route-tables.png` | `vpc.tf` | Public route table (IGW) vs. private route table (NAT) |
| `03-security-groups.png` | `security-groups.tf` | Tier-scoped inbound rules (ALB -> App -> DB) |
| `04-ec2-instance.png` | `compute.tf` | EC2 instance in a private subnet, no public IP |
| `05-rds-multi-az.png` | `database.tf` | RDS instance with Multi-AZ enabled |
| `06-iam-role.png` | `compute.tf` | IAM role attached to EC2, no access keys |
| `07-cloudwatch-alarm.png` | `monitoring.tf` | CPU alarm configuration and SNS subscription |

*(Fill in one or two sentences per row once screenshots are added —
what you clicked, and how it maps to the resource block.)*