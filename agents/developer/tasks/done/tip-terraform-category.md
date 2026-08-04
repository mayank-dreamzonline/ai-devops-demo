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

**Status: waiting on review/merge.** This is the change that will
trigger the pipeline for the first time — once merged, `deploy-dev` /
`verify-dev` / `deploy-staging` / `deploy-prod` should all run for real.
