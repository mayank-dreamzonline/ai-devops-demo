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

**PR merged:** https://github.com/mayank-dreamzonline/ai-devops-demo/pull/17
(branch `ci-cd-pipeline` → `main`, merge commit `eedb373`).

**Unexpected trigger on merge:** the merge itself touched
`cicd/k8s/ai-devops-demo-app/**` (first time those files existed) — which
matches the caller workflow's own `paths:` filter (Section 4 of the
brief). Since that's a `push` to `main`, `deploy` evaluated `true` and the
full deploy chain ran for real, contradicting the brief's stated Part 1
intent ("merge with nothing yet triggering it"). Not a bug in what was
built — it's Section 4's trigger definition (built exactly as specified)
colliding with the fact that Part 1's own deliverable is the first-ever
`cicd/k8s/**` commit to `main`. Worth the brief being corrected if this
pipeline is rebuilt again.

**Result of that real run** (https://github.com/mayank-dreamzonline/ai-devops-demo/actions/runs/30915377899):
`build-lint-test`/`dependency-scan`/`secrets-scan` passed. `package`
failed at the smoke-test step — `curl` exit 56 (`CURLE_RECV_ERROR`,
connection accepted then reset), a transient-failure mode not covered by
`--retry-connrefused` (which only covers connection-*refused*, not
reset-after-connect). Downstream jobs (`security-scan` through
`deploy-prod`) all skipped as a result. **Nothing deployed to any
environment.**

**Fix applied** (branch `narrow-ci-cd-trigger-paths`): dropped
`cicd/k8s/ai-devops-demo-app/**` from `ai-devops-demo-app.yml`'s
`pull_request`/`push` `paths:` filters — now watches `app/**` only.
Decision (Mayank, in-conversation): this demo never exercises a
manifest-only change triggering a deploy, so the realism that path
bought wasn't worth its cost — it made Part 1's own first-ever manifest
commit indistinguishable from "a manifest changed, redeploy," which is
exactly what fired mid-recording. Removing it makes that collision
structurally impossible instead of something to work around each rebuild
(e.g. via disable/re-enable workflow). Editing the workflow file itself
doesn't match either watched path, so merging this fix does not trigger
a run.

**Still open, not addressed by this fix:** the `package` job's
smoke-test `curl` failure (exit 56, connection reset) from the earlier
real run — that bug is independent of the trigger-path issue and will
still be there whenever Part 2 actually exercises the pipeline for real.
