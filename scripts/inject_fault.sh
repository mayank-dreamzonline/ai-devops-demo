#!/usr/bin/env bash
# Deterministic, non-agent fault injection — simulates someone making a bad
# infrastructure change. Kept outside the agent workflow on purpose: this is
# the one step where variability would be purely bad ("let's see if the
# agent breaks it correctly" is not the point of this beat).
set -euo pipefail

cd "$(dirname "$0")/../terraform/eks"

echo "Injecting fault: applying a NO_EXECUTE taint to the node group (node count unchanged)..."
terraform apply -auto-approve -var fault_active=true

echo ""
echo "Fault injected. Nodes will begin draining. Watch recovery with:"
echo "  kubectl get nodes -w"
echo "  kubectl get pods -A"
