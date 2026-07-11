# redeploy-whoami

**Request:** deploy the whoami sample app so it's reachable. Code already
exists in `terraform/app/whoami.tf` (previously applied, then torn down
before the recording per PROGRESS.md — `terraform/app` currently has 0
resources in state) — validate, then re-apply.

**Outcome:** `fmt`/`validate` clean, existing merged code, no diff to
review — applied directly through Checker + Gate. 2 resources added
(Deployment, ClusterIP Service), 0 changed/destroyed. Verified: 3/3 pods
`Running` spread across both nodes, `kubectl port-forward` to
`localhost:8765` returned `HTTP 200` from pod `whoami-7d576ff775-cpwq8`.
