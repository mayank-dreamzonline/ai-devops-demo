# pods-pending
**Symptom:** Some pods continuously in Pending state in ai-devops-demo cluster.

**Root cause:** Live drift, not a node/capacity problem. `terraform/eks/current_state.auto.tfvars` already declares `fault_active = false`, but both nodes carry a live `fault-injected=true:NoExecute` taint — applied via `scripts/inject_fault.sh`'s `-var fault_active=true` CLI override, which never touched the tfvars file. No pod tolerates the taint, so whoami (x3) and coredns (x2) were evicted and can't reschedule ("0/2 nodes are available: 2 node(s) had untolerated taint(s)"). Confirmed via read-only `terraform -chdir=terraform/eks plan`: exactly one pending change — remove the taint block — to reconcile state to the already-correct file.

**Handed to DevOps:** apply the already-declared config, `terraform -chdir=terraform/eks apply` (no `-var` override), through the normal branch/PR/Checker/Gate path. No `.tf`/`.tfvars` file edit needed.
