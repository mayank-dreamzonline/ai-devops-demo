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
