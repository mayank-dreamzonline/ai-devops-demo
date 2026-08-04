# ci-cd-pipeline-rebuild

**Request:** Build the CI/CD pipeline layer per `inbox/requirement_pipeline.md`
(Part 1 of the two-part pipeline demo) — a fresh build attempt from the
corrected brief. The previous attempt (`agents/devops/tasks/done/ci-cd-pipeline.md`,
PR #17) was merged, hit a real curl-retry bug in the `package` job's
smoke-test step, and was fully rolled back. Since then the brief has been
corrected twice: Section 4's trigger now watches `<app-path>/**` only (not
`<k8s-path>/**`, which caused the original bootstrapping collision), and
Section 3's smoke-test curl commands now include `--retry-all-errors`.
Sections to build: 1 (Kustomize manifests), 2 (composite action), 3
(reusable workflow), 4 (caller workflow) — Section 0 (Dockerfile) and
Section 5 (GitHub setup) were already confirmed in place during the prior
attempt and untouched by the rollback.

**Built** (branch `ci-cd-pipeline-rebuild`, verified with `actionlint` on
both workflow files and `kubectl kustomize` on all four overlays before
commit): Sections 1-4 as scoped above. Two deviations from the literal
brief text, both required for correctness and verified live before
pinning:
- `gitleaks/gitleaks-action` pinned to `@v3`, not the brief's `@v2` — v3
  is now the current major release.
- `security-scan` gained a GHCR login step before the Trivy scan, since
  GHCR images default to private visibility (even in a public repo) and
  the job otherwise has no credentials to pull the image `package` just
  pushed.

**PR #25 opened**: https://github.com/mayank-dreamzonline/ai-devops-demo/pull/25

**Status: waiting on review/merge.** Per procedure, not planning or
applying anything further until the PR is merged — there's no
Terraform in this task anyway, so the next step after merge is simply
verifying the workflow exists on `main` untriggered (paths filter
only matches `app/**`, which this PR doesn't touch).
