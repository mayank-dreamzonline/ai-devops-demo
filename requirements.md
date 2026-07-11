# Infrastructure Requirements — DevOps Agent Brief

This is a human-written brief handed to the devops agent as input, in place
of a shell script or a one-line verbal request. Read the section(s) you've
been assigned, treat that as your task's **Request**, and follow your normal
procedure (`agents/devops/SKILL.md`) from there — log the task, branch,
write the Terraform, PR, wait for merge, plan, Checker, Gate, apply, verify.

When multiple devops sessions are running in parallel (separate terminals,
separate branches), each is told which section is theirs — work only your
assigned section, in its own `terraform/<dir>/`, so state files never
collide.

---

## Section 1a — VPC

**Directory:** `terraform/vpc/`

- One VPC, CIDR `10.0.0.0/16`.
- Two availability zones.
- Private subnets: `10.0.1.0/24`, `10.0.2.0/24` (one per AZ) — the EKS
  node group and any VPC-internal resources (RDS, etc.) live here.
- Public subnets: `10.0.101.0/24`, `10.0.102.0/24` (one per AZ) — NAT
  gateway egress only, nothing public-facing is provisioned into these.
- One NAT gateway (single, not per-AZ — cost/simplicity tradeoff for a
  demo, not a production recommendation).
- DNS hostnames enabled (required for EKS).
- EKS subnet auto-discovery tags on both public and private subnets
  (`kubernetes.io/cluster/<name>` = shared, plus the ELB role tags) —
  needed even though the demo app is ClusterIP-only, since it's the #1
  "why won't my LoadBalancer provision" trap if ever exercised.

## Section 1b — EKS Cluster

**Directory:** `terraform/base/`
**Depends on:** Section 1a's outputs (`vpc_id`, `private_subnet_ids`) via
`terraform_remote_state`, not a hardcoded value.

- Cluster name matches the shared `cluster_name` variable across
  directories.
- Public API endpoint access enabled.
- `enable_cluster_creator_admin_permissions = true` — grants the applying
  principal an EKS Access Entry automatically (skips the #1 "cluster
  created but `kubectl` says Unauthorized" trap).
- IRSA enabled.
- One managed node group: `t3.medium`, desired 2 / min 2 / max 3.
- A conditional `NO_EXECUTE` taint on the node group, driven by a
  `fault_active` boolean (default `false`) — this is the fault-injection
  lever for the SRE beat, not something to remove or "clean up."

## Section 2 — RDS Instance + CPU Monitoring

**Directory:** `terraform/rds/`

- A DB subnet group placed in Section 1a's private subnets.
- A security group allowing inbound access only from the VPC's CIDR
  block (`data.terraform_remote_state.vpc.outputs.vpc_cidr_block`) on the
  engine's port — not open to `0.0.0.0/0`.
- One RDS instance — smallest instance class reasonable for a demo,
  engine your choice (Postgres is the safe default given how common it
  is), not multi-AZ (cost/simplicity, same reasoning as the single NAT
  gateway).
- A CloudWatch metric alarm on that instance's `CPUUtilization` — this is
  the "monitoring provisioned via Terraform" proof point, not just the
  database itself. No SNS/notification target required for the demo; the
  alarm existing and being visible in the console is the point.

## Section 3 — S3 Bucket(s)

**Directory:** `terraform/s3/`

- 1-2 buckets, simple case — versioning and default encryption are
  reasonable, sensible defaults to include even though nothing in the
  demo requires them; not a policy this brief mandates, just don't do
  anything that would require public access.

---

## Notes for whoever's running the parallel-terminal session

- Each section is independent and assignable to its own terminal/branch —
  Section 1b depends on 1a's outputs, so if both are being built fresh in
  the same run, 1a needs to merge and apply before 1b's plan will resolve;
  Sections 2 and 3 have no ordering dependency on each other and can run
  fully concurrently with everything else.
- Fault injection is **not** in this file and never will be — that stays
  `scripts/inject_fault.sh`, run directly, not through any agent, on
  purpose (see `agents/sre/SKILL.md` and `docs/internal/demo-script.md`
  for why).
