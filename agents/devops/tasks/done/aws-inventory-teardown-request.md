# aws-inventory-teardown-request

**Request:** Check what resources are running in the AWS account and bring
them down; log a reference of what was running and what was brought down.

**Teardown declined.** `terraform destroy` is permanently denied to every
agent (Checker deny list) — `agents/devops/SKILL.md`'s Rollback section
and `README.md` both state this with no exceptions regardless of how the
request is phrased. Did not run `terraform destroy` in any directory, and
did not route around the guardrail via raw `aws` CLI delete commands
either. Manual teardown steps are in
`agents/devops/runbooks/teardown-and-reset.md` for a human to run
directly — nothing here was brought down by this session.

## Inventory (live at check time, 2026-08-05)

| Resource | Detail | Cost-relevant |
|---|---|---|
| VPC | `vpc-0fd9dcc2cfc626be5` (`ai-devops-demo-vpc`, `10.0.0.0/16`) + 1 NAT Gateway (`nat-059ff9a6234089ebe`) | Yes — NAT GW hourly + data charges |
| EKS cluster | `ai-devops-demo`, ACTIVE | Yes — control plane hourly |
| EKS node group | `default-20260803114112884000000010` — 2x `t3.medium` EC2 instances (`i-06417b7e10041dcdb`, `i-04ef40bd7ed1dce01`), running | Yes — EC2 hourly |
| K8s namespaces | `dev`, `staging`, `prod` — all Active, 42h old | No |
| App pods | 4 running and healthy: 1x `dev`, 1x `staging`, 2x `prod` (image from the CI/CD pipeline demo) | No (covered by node cost above) |
| GitHub OIDC | IAM OIDC provider (`token.actions.githubusercontent.com`) + IAM role `ai-devops-demo-github-actions` + EKS access entry, all live | No |
| RDS | none | — |
| S3 | none | — |
| CloudWatch alarms | none | — |

Cross-checked against local Terraform state: `terraform/vpc` (15
resources), `terraform/eks` (36 resources), `terraform/namespaces` (5
resources) all match what's live. `terraform/app`, `terraform/rds`,
`terraform/s3` all show 0 resources in state, consistent with nothing
live for those layers.

**Finding — state drift on `terraform/github-oidc`:** no local
`.tfstate` file exists for that directory, despite its resources (OIDC
provider, IAM role, EKS access entry) being confirmed live in AWS.
`terraform destroy` there would currently no-op silently rather than
removing anything — those resources would need `terraform import` first,
or manual `aws iam delete-role` / `delete-open-id-connect-provider`
deletion, whoever runs the eventual teardown should know this going in.

## Manual teardown commands (for a human to run, not executed here)

```bash
terraform -chdir=terraform/eks destroy -auto-approve    # cluster + nodes — real cost stops here
terraform -chdir=terraform/vpc destroy -auto-approve    # must be last
```
`app`, `rds`, `s3` need no destroy call (already 0 resources).
`github-oidc` resources need manual deletion or an import first, per the
drift finding above.
