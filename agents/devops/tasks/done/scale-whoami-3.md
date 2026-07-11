# scale-whoami-3
**Request:** scale whoami from 1 pod to 3

**Outcome:** Changed `replicas` 1 -> 3 in `terraform/app/whoami.tf`. Plan
showed 1 resource to change, 0 add/destroy. Applied through Checker +
Gate. Verified: `kubectl get pods -l app=whoami` shows 3/3 `Running`
(`whoami-7d576ff775-4jmll`, `-rdvrz`, `-z2sj6`), spread across 2 nodes.
