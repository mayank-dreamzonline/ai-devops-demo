# ghcr-pull-secrets

**Request:** Add a GHCR image-pull secret (`kubernetes.io/dockerconfigjson`)
to each of `dev`/`staging`/`prod`, since GHCR stays private, per the CI/CD
demo design pinned in `PROGRESS_ci_cd_demo.md` (Mayank, in-conversation
request).

**PR:** https://github.com/mayank-dreamzonline/ai-devops-demo/pull/7 —
merged, `terraform validate` clean. **Blocked on apply**: needs a real
GitHub PAT (`read:packages` scope) supplied via
`terraform/namespaces/terraform.tfvars` (gitignored, copy from
`terraform.tfvars.example`) — not something I can generate myself. Task
stays in-progress until that's supplied and the apply/verify happens.
