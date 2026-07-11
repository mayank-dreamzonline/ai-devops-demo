#!/usr/bin/env bash
# Checker hook — PreToolUse, scoped to `Bash(terraform apply *)` via the `if`
# matcher in .claude/settings.json. Reads the pending command from stdin and
# validates the plan BEFORE it's allowed to execute.
#
# This can only make the call MORE restrictive: it may "deny", but it must
# never emit "allow" — that would skip Claude Code's own approval prompt
# entirely, and that prompt is the actual human-in-the-loop Gate. A plan that
# passes this script still has to clear a real human approval afterward.

set -euo pipefail

input=$(cat)
command=$(echo "$input" | jq -r '.tool_input.command // empty')

deny() {
  local reason="$1"
  jq -n --arg reason "$reason" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: $reason
    }
  }'
  exit 0
}

if [[ -z "$command" ]]; then
  deny "Could not read the pending command — refusing to validate blind."
fi

# Extract -chdir=<dir> and the plan file argument (last whitespace-separated
# token of the terraform invocation itself). Agents are instructed to always
# apply an explicit -out= plan file, never a bare `terraform apply`. Strip
# anything after a pipe/redirect/chain operator first — e.g. `... tfplan |
# tee log` or `... tfplan 2>&1` are legitimate ways to run this command, and
# the redirect target isn't the plan file.
tf_segment=$(echo "$command" | sed -E 's/[|;&].*$//; s/[0-9]*>>?[^ ]*//g')
chdir=$(echo "$tf_segment" | grep -oE -- '-chdir=[^ ]+' | head -1 | cut -d= -f2)
planfile=$(echo "$tf_segment" | awk '{print $NF}')

if [[ -z "$chdir" || -z "$planfile" || "$planfile" == "apply" ]]; then
  deny "Could not determine which plan file this apply targets. Run 'terraform -chdir=<dir> plan -out=tfplan' first, then apply that exact file — never a bare 'terraform apply'."
fi

planpath="$chdir/$planfile"
if [[ ! -f "$planpath" ]]; then
  deny "Plan file '$planpath' does not exist. Run terraform plan -out=$planfile first."
fi

if ! terraform -chdir="$chdir" validate -json > /tmp/tf-checker-validate.json 2>&1; then
  deny "terraform validate failed for $chdir — fix the configuration before applying."
fi

plan_json=$(terraform -chdir="$chdir" show -json "$planfile")

lb_violation=$(echo "$plan_json" | jq -r '
  [.resource_changes[]? |
    select(.type == "kubernetes_service") |
    select(.change.after.spec[0].type? == "LoadBalancer")
  ] | length'
)

if [[ "$lb_violation" -gt 0 ]]; then
  deny "This plan creates a LoadBalancer-type kubernetes_service. Public-facing LoadBalancer services are not permitted on this cluster for this demo — use ClusterIP instead."
fi

protected_deletion=$(echo "$plan_json" | jq -r '
  [.resource_changes[]? |
    select(.change.actions[]? == "delete") |
    select(.address | test("^module\\.(eks|vpc)\\."))
  ] | length'
)

if [[ "$protected_deletion" -gt 0 ]]; then
  deny "This plan deletes protected base infrastructure (cluster, node group, or VPC). Blocked — if this is genuinely intended, it needs to happen outside this workflow, not be auto-approved here."
fi

# All checks passed — emit nothing. Falls through to Claude Code's own
# approval prompt, which is the Gate.
exit 0
