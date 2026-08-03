# section-0-base-scaffold

**Request:** inbox/requirement_app.md, Section 0 — Base app scaffold.

Directory: `app/`. Base branch: `main`. Target branch: `main` directly
(baseline/scaffold, not a reviewed feature — no `QA` review flow).

Scope:
- Node.js + Express, minimal dependencies.
- `GET /health` endpoint returning JSON.
- Shared `lookup(data, category)` helper (random match by category, random
  overall if no category, error/signal if category doesn't match anything).
- Single shared router/route-registration file for Sections 1/2 to extend.
- Test framework (Jest) with a passing test for `/health` and for `lookup`.
- `Dockerfile` (multi-stage, non-root user, slim runtime), `.dockerignore`.
- ESLint config, no lint errors on the scaffold.
- No feature routes beyond `/health` yet.
