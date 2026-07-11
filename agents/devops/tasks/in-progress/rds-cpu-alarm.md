# rds-cpu-alarm

**Request:** requirements.md Section 2 — RDS Instance + CPU Monitoring.
DB subnet group in the VPC's private subnets, a security group scoped to
the VPC CIDR only (no `0.0.0.0/0`), one Postgres instance (smallest
reasonable class, not multi-AZ), and a CloudWatch alarm on its
`CPUUtilization`.
