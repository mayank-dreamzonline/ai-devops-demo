# rds-cpu-alarm

**Request:** requirements.md Section 2 — RDS Instance + CPU Monitoring.
DB subnet group in the VPC's private subnets, a security group scoped to
the VPC CIDR only (no `0.0.0.0/0`), one Postgres instance (smallest
reasonable class, not multi-AZ), and a CloudWatch alarm on its
`CPUUtilization`.

**Outcome:** PR [#2](https://github.com/mayank-dreamzonline/ai-devops-demo/pull/2)
reviewed, merged (squash, `acb4f48`). Plan showed 5 to add, 0 change/destroy
both pre- and post-merge. Applied through Checker + Gate:
`db.t3.micro` Postgres 17.10, single-AZ, encrypted storage, security group
scoped to the VPC CIDR on 5432 only, master password generated via the
`random` provider (never committed). CloudWatch alarm on `CPUUtilization`
(>80% / 10 min) created alongside it. Verified live via `aws rds
describe-db-instances` (status `available`, not publicly accessible,
storage encrypted) and `aws cloudwatch describe-alarms` (alarm exists,
threshold 80, `INSUFFICIENT_DATA` state expected pre-traffic).
