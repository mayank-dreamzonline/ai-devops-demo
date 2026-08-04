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

**PR #17 merged**, then rolled back. Full sequence:

1. PR #17 (branch `ci-cd-pipeline`) opened, CI checks passed, merged to
   `main` (merge commit `eedb373`).
2. **Unexpected trigger on that merge:** the merge itself touched
   `cicd/k8s/ai-devops-demo-app/**` (first time those files existed),
   which matched the caller workflow's own `paths:` filter (Section 4 of
   the brief watched both `<app-path>/**` and `<k8s-path>/**`). Since
   that's a `push` to `main`, `deploy` evaluated `true` and the pipeline
   ran for real — contradicting the brief's stated Part 1 intent ("merge
   with nothing yet triggering it"). Root cause: Part 1's own deliverable
   *is* the first-ever `<k8s-path>/**` commit, so it can never avoid
   matching a trigger that watches that path. Not a bug in what was
   built — Section 4's trigger, built exactly as specified, colliding
   with what Part 1 necessarily is.
3. That real run (https://github.com/mayank-dreamzonline/ai-devops-demo/actions/runs/30915377899):
   CI jobs passed; `package` failed at the smoke-test step (`curl` exit
   56, `CURLE_RECV_ERROR` — connection accepted then reset, a failure
   mode `--retry-connrefused` doesn't cover since it only retries
   connection-*refused*). Downstream jobs all skipped. **Nothing
   deployed to any environment** — confirmed no cluster impact.
4. PR #18 opened (branch `narrow-ci-cd-trigger-paths`) to narrow the
   trigger to `app-path` only — then **closed unmerged**, superseded by
   a full rollback + brief correction instead (Mayank's call: fix the
   source of truth, not just the merged code).
5. **Rollback** (branch `rollback-pipeline-layer`): removed all of
   Sections 1–4's files from `main` again
   (`.github/workflows/_reusable-ci-cd.yml`, `ai-devops-demo-app.yml`,
   `.github/actions/deploy-to-env/`, `cicd/k8s/ai-devops-demo-app/`).
   Section 0 (Dockerfile) and Section 5 (GitHub settings) are untouched —
   still in place, still correct, nothing to redo there.
6. **`inbox/requirement_pipeline.md` corrected**: Section 4's trigger
   template now watches `<app-path>/**` only, with an inline note
   explaining why `<k8s-path>/**` was dropped (the bootstrapping
   collision above) — so a future rebuild starts from a brief that
   doesn't reproduce this bug.

7. **`inbox/requirement_pipeline.md` corrected again** (branch
   `fix-smoke-test-retry-spec`): Section 3's `package`-job smoke-test now
   specifies `curl --retry-all-errors` alongside `--retry-connrefused`.
   Root cause: `--retry-connrefused` only retries "connection refused"
   (curl exit 7); the real failure seen in step 3 above was `CURLE_RECV_ERROR`
   (exit 56) — a fresh container's port accepted by Docker's proxy then
   reset before the process inside finished starting, a different
   transient failure mode that needs `--retry-all-errors` to be retried
   at all.

**Status: done (rolled back and brief corrected, twice).** Both real bugs
hit during the first build attempt (trigger-path collision, smoke-test
retry gap) are now folded into `inbox/requirement_pipeline.md` as stated
requirements. Ready for a fresh build attempt from the corrected brief
whenever requested — that would be a new task, starting from `planned/`
again.
