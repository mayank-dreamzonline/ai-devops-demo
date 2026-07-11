# Teardown and Reset — manual runbook

Not a script, deliberately. `terraform destroy` is permanently denied to
any agent (Checker deny list), so this is always run by a human, typing
the commands directly — a runbook checklist stays accurate as new
`terraform/` directories get added over time; a script encoding a fixed
directory list and order doesn't.

## Reset between dry runs (keep the cluster, clear app-layer + fault state)

Run in order:

1. If `terraform/app/terraform.tfstate` has any resources:
   `terraform -chdir=terraform/app destroy -auto-approve`
2. Restore the node group to healthy:
   `terraform -chdir=terraform/base apply -auto-approve -var fault_active=false`

`terraform/vpc/`, `terraform/rds/`, `terraform/s3/` are untouched by a
reset — only the app layer and the fault-injection toggle reset between
takes.

## Full teardown (post-recording only, tears down everything)

Dependency order matters — later layers depend on earlier ones' outputs,
so destroy in reverse:

1. `terraform -chdir=terraform/app destroy -auto-approve` (if any state)
2. `terraform -chdir=terraform/rds destroy -auto-approve` (if any state)
3. `terraform -chdir=terraform/s3 destroy -auto-approve` (if any state)
4. `terraform -chdir=terraform/base destroy -auto-approve` — the EKS
   cluster and node group. Real cost stops accruing after this step.
5. `terraform -chdir=terraform/vpc destroy -auto-approve` — must be last,
   everything above depends on this VPC's outputs.

If a new `terraform/<something>/` directory gets added later that depends
on `vpc`/`base`, add its destroy step between 3 and 4 (destroy anything
that depends on the cluster before destroying the cluster itself).

Do not run the full teardown until the recording is confirmed good —
re-provisioning `vpc`/`base` from scratch costs a real ~10-15 minute EKS
control-plane wait.
