# deploy-whoami
**Request:** deploy the whoami sample app so it's reachable

**Outcome:** Already applied (Deployment + ClusterIP Service in
`terraform/app/whoami.tf`). `terraform plan` showed no drift. Verified
reachable: port-forwarded `svc/whoami` to `localhost:8765`, confirmed
`HTTP 200` both via curl and directly in the user's browser, response
from pod `whoami-7d576ff775-4jmll`.
