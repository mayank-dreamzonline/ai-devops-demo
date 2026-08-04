# tip-terraform-category

**Request:** `inbox/requirement_app.md`, Section 3 — Part 2 of the pipeline
demo: add a `terraform` category to `/tip`.

Base branch: `main`. Target branch: `main` directly (no `develop`, dropped
repo-wide). Scope: add 2-3 `{ text, category: 'terraform' }` entries to
`app/data/tips.js`, plus one test asserting `category=terraform` now
returns `200` with a valid tip. No new route, no new file, no new
dependency — `lookup()` and the existing `/tip` route already support
this once the data exists.
