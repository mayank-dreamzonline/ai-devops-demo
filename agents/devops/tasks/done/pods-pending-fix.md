# pods-pending-fix
**Request:** Handed off from SRE (agents/sre/tasks/done/pods-pending.md). Root cause: live drift on terraform/eks — a `fault-injected=true:NoExecute` taint exists on both nodes from `scripts/inject_fault.sh`'s `-var fault_active=true` CLI override, which never touched `current_state.auto.tfvars` (still correctly `fault_active = false`). No `.tf`/`.tfvars` edit needed — fix is applying the already-declared config to reconcile state and remove the taint.

**No PR needed:** zero file diff existed (fault was live-state drift only, via a CLI `-var` override — see SRE's diagnosis). Went straight to plan → Checker → Gate → apply.
**Outcome:** `terraform -chdir=terraform/eks apply` — 0 added, 1 changed, 0 destroyed (removed the `fault-injected:NoExecute` taint). Verified: `kubectl get nodes` shows no taints; all 5 previously-Pending pods (whoami x3, coredns x2) now `Running` 1/1.
