# section-1-tip-feature

**Request:** inbox/requirement_app.md, Section 1 — Feature A: `GET /tip`.

Directory: `app/`. Base branch: `main`.

Scope:
- `data/tips.js` — an array of DevOps tips, each `{ text, category }`.
- `GET /tip` registered in the shared router, calling the Section 0
  `lookup(tips, req.query.category)` helper: random tip by default,
  filtered by category when given, `400` on an unrecognized category.
- 3 unit tests: default selection, valid category, invalid category.

**PR:** https://github.com/mayank-dreamzonline/ai-devops-demo/pull/10 —
merged (originally into a since-removed `develop` integration branch, as
part of a branching model that was later simplified away).

**Outcome:** Feature validated through the full CI/CD pipeline during
initial pipeline testing — build, test, package, deploy to dev, staging
approval, prod approval, all exercised for real. When `develop` was
later deleted as part of dropping that branching model, the feature's
code was recovered directly onto `main` from the intact merge commit
(`5cca848`) rather than lost. `/tip` is live on `main`, ready for the
pipeline to be rebuilt around it.
