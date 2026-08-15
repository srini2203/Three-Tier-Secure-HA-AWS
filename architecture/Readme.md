# Architecture Documentation

This directory contains the architecture artifacts for the **three-tier-ha-aws** project.

The diagrams are grouped by architectural concern rather than placing every component into a single diagram.

---

## Diagram Overview

| Diagram | Purpose 
|----------|---------
| High-Level Architecture | Overall system view 
| Network Architecture | VPC, routing and subnets 
| Security Architecture | IAM, WAF, Security Groups, KMS 
| Monitoring Architecture | CloudWatch, CloudTrail, Config, SNS 
| Deployment Architecture | CloudFormation deployment workflow 

---

## Source Files

Editable diagrams are stored under:

```
architecture/images/Architecture diagram.drawio
```

---

## Exported Images

PNG exports used by the documentation are stored under:

```
architecture/images/
```

---

## AWS Icons

Official AWS Architecture Icons are used wherever possible.

---

## Documentation Standards

Each diagram should:

- Represent a single architectural concern.
- Avoid unnecessary complexity.
- Follow official AWS iconography.
- Be easy to understand within five minutes.