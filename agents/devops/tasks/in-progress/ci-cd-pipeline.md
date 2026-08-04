# ci-cd-pipeline

**Request:** Build the CI/CD pipeline layer (Part 1 of the two-part
pipeline demo) per `inbox/requirement_pipeline.md` (Mayank,
in-conversation request). This brief **supersedes** the earlier
`inbox/requirement_ci-cd.md` / `PROGRESS_ci_cd_demo.md` design — that
earlier build was validated once, then deliberately reset (commit
`ebf82b4`, "Reset pipeline layer for a clean two-part demo rebuild") so
it could be rebuilt live from a corrected brief with every bug found
during the first validation pass folded in as stated requirements
(permissions block, kustomize-already-installed, verify-dev's race
condition, Trivy version pinning, environment settings-drift gotchas).
`PROGRESS_ci_cd_demo.md` is now stale pre-reset tracking (old
`main→QA→feature` branch model, dropped) — do not use it as a source of
truth for this task; `inbox/requirement_pipeline.md` is authoritative.

**Initial planning pass (this update) — current state confirmed by
reading the repo directly, not assumed from old task notes:**

Already done, nothing to redo:
- **Section 0 (Dockerfile):** `app/Dockerfile` confirmed present and
  matches spec — multi-stage (`deps`→`runtime`), non-root `USER node`,
  and the `rm -rf` of bundled npm/npx already in place post-copy,
  pre-`USER`.
- **Section 5 (one-time GitHub setup):** all four items verified live via
  `gh api`, not just assumed:
  - Repo is public.
  - `main-branch-protection` ruleset exists (id `20360917`), targets
    `refs/heads/main`, `pull_request` rule with
    `required_approving_review_count: 0`, no bypass actors —
    `required_status_checks` intentionally still absent per the brief
    (added only after the workflow has run once and check names become
    selectable). Logged in `agents/devops/tasks/done/branch-protection-ruleset-main.md`.
  - `dev`/`staging`/`prod` Environments all exist. `staging` and `prod`
    both have required reviewer `mayank-dreamzonline`,
    `can_admins_bypass: false`, and a custom deployment-branch-policy
    scoped to `main`. `dev` has no protection rules (correct — brief only
    requires it to exist).
  - `AWS_ROLE_ARN` repo variable set to
    `arn:aws:iam::713415772392:role/ai-devops-demo-github-actions`.

Still to build — confirmed **not present** in the repo (wiped by the
reset commit, nothing since re-created):
- **Section 1:** `cicd/k8s/ai-devops-demo-app/{base,overlays/{dev,staging,prod}}` —
  Kustomize manifests (ClusterIP service, `prod` replica-count patch).
- **Section 2:** `.github/actions/deploy-to-env/action.yml` — composite
  action (conditional kustomize install, set image, apply, rollout
  status).
- **Section 3:** `.github/workflows/_reusable-ci-cd.yml` — all pipeline
  logic (build-lint-test/dependency-scan/secrets-scan → package →
  security-scan → deploy-dev → verify-dev → deploy-staging →
  deploy-prod), `workflow_call`-parameterized.
- **Section 4:** `.github/workflows/ai-devops-demo-app.yml` — thin caller
  workflow wiring PR/push/dispatch triggers to the reusable workflow.

**Built** (on branch `ci-cd-pipeline`, verified with `actionlint` +
`kubectl kustomize` for all four Kustomize builds before commit):
Sections 1–4 as scoped above.

**PR opened:** https://github.com/mayank-dreamzonline/ai-devops-demo/pull/17
(branch `ci-cd-pipeline` → `main`). Waiting for review/merge — nothing in
Part 1 actually triggers the pipeline; that's Part 2, developer's request.
