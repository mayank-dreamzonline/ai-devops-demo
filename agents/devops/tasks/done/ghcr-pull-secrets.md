# ghcr-pull-secrets

**Request:** Add a GHCR image-pull secret (`kubernetes.io/dockerconfigjson`)
to each of `dev`/`staging`/`prod`, since GHCR stays private, per the CI/CD
demo design pinned in `PROGRESS_ci_cd_demo.md` (Mayank, in-conversation
request).

**PR:** https://github.com/mayank-dreamzonline/ai-devops-demo/pull/7 —
merged, `terraform validate` clean. **Applied and verified**: 3 secrets
created (`ghcr-pull-secret` in `dev`/`staging`/`prod`), confirmed via
`kubectl get secret ghcr-pull-secret -n <ns>` in all three.
