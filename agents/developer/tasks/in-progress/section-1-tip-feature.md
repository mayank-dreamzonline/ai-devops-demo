# section-1-tip-feature

**Request:** inbox/requirement_app.md, Section 1 — Feature A: `/tip`.

Directory: `app/`. Base branch: `main` (after Section 0). Target branch:
`develop`.

Scope:
- `data/tips.js` array of DevOps tips, each `{ text, category }`
  (categories: `git`, `docker`, `kubernetes`, at least a couple per
  category).
- Register `GET /tip` in the shared router file, calling
  `lookup(tips, req.query.category)`:
  - No `category` → random tip from the full set.
  - Valid `category` → random tip filtered to that category.
  - Unrecognized `category` → `400` with an error message.
- Plain text or simple rendered HTML response — no frontend/build step.
- 3 unit tests: default, valid category, unrecognized category (400).

**PR:** https://github.com/mayank-dreamzonline/ai-devops-demo/pull/10
(branch `section-1-tip-feature` → `develop`). Local `npm test` (7 tests)
and `eslint .` both clean; manual smoke test against a local server
confirmed 200/200/400 for no-category/valid-category/bad-category. Note:
`app/src/router.js` is the deliberate shared merge-conflict point with
Section 2 (`/fact`); a separate concurrent session appears to be working
that section in this same working tree. Waiting on review/merge.
