# ci-cd-pipeline

**Request:** Build the CI/CD pipeline itself — Kustomize manifests
(`k8s/base` + `k8s/overlays/{dev,staging,prod}`) and the GitHub Actions
workflow (`.github/workflows/ci-cd.yml`) — per the design pinned in
`PROGRESS_ci_cd_demo.md` and `inbox/requirement_ci-cd.md` (Mayank,
in-conversation request).

**Built, extensible structure** (per-service, checked against a real
Jenkins shared-library pattern for structural inspiration only, then
translated to GitHub's own reusable-workflow mechanism rather than
copying it directly — a single-app demo has nothing to actually share
yet, so a full shared-library scaffold would be indirection with no
payoff):
- `cicd/k8s/ai-devops-demo-app/{base,overlays/{dev,staging,prod}}` —
  Kustomize manifests. A second service adds a sibling
  `cicd/k8s/<service>/`.
- `.github/actions/deploy-to-env/` — one composite action (kustomize set
  image + apply + rollout status), called 3x (dev/staging/prod) instead
  of repeating the same steps three times.
- `.github/workflows/_reusable-ci-cd.yml` — all the actual pipeline logic
  (build/lint/test/dependency-scan/secrets-scan/package/security-scan/
  deploy-dev/verify-dev/deploy-staging/deploy-prod), parameterized via
  `workflow_call` inputs.
- `.github/workflows/ai-devops-demo-app.yml` — thin caller: triggers on
  `app/**` + this service's k8s path, passes this service's inputs to the
  reusable workflow. A second service adds its own caller file here, not
  more logic in the reusable workflow.

**Still needed before this can run for real** (one-time manual GitHub
setup, not code): `AWS_ROLE_ARN` repo variable (the OIDC role's ARN,
`arn:aws:iam::713415772392:role/ai-devops-demo-github-actions`), and
`staging`/`prod` Environments with required reviewers configured.
