# tip-terraform-category

**Request:** `inbox/requirement_app.md`, Section 3 — Part 2 of the pipeline
demo: add a `terraform` category to `/tip`.

Base branch: `main`. Target branch: `main` directly (no `develop`, dropped
repo-wide). Scope: add 2-3 `{ text, category: 'terraform' }` entries to
`app/data/tips.js`, plus one test asserting `category=terraform` now
returns `200` with a valid tip. No new route, no new file, no new
dependency — `lookup()` and the existing `/tip` route already support
this once the data exists.

**Built** (branch `tip-terraform-category`): 3 terraform tips added to
`app/data/tips.js`, one test added to `__tests__/tip.test.js`. 8/8 tests
pass locally, lint clean. Verified live locally: 400 -> 200 flip for
`category=terraform` confirmed before commit.

**PR #27 opened**: https://github.com/mayank-dreamzonline/ai-devops-demo/pull/27

**PR #27 merged** (merge commit `7eb3b11`). Triggered the pipeline for
the first time — full run https://github.com/mayank-dreamzonline/ai-devops-demo/actions/runs/30936758908,
all 9 jobs succeeded: `dependency-scan`, `build-lint-test`,
`secrets-scan`, `package`, `security-scan`, `deploy-dev`, `verify-dev`,
`deploy-staging` (approved), `deploy-prod` (approved).

Verified live at every stage via `kubectl port-forward` + curl,
`category=terraform`:
- **dev:** `200` with a real terraform tip, right after `deploy-dev`.
- **staging:** `200`, right after approval + `deploy-staging`.
- **prod:** `200`, right after approval + `deploy-prod` — confirmed the
  `400 -> 200` flip against the same environment that was `400` before
  this PR.

**Status: done.** Part 2 complete — the pipeline (Part 1) has now been
exercised end-to-end for real, promoting a genuine app change through
dev, staging, and prod with both approval gates exercised.
