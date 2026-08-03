# Sample App Requirements — Developer Agent Brief

This is a human-written brief handed to the developer agent as input, in
place of a shell script or a one-line verbal request. Read the section(s)
you've been assigned, treat that as your task's **Request**, and follow
your normal procedure (`agents/developer/SKILL.md`) from there — log the
task, branch, write the code + tests, PR, wait for merge.

When multiple developer sessions are running in parallel (separate
terminals, separate branches/identities), each is told which section is
theirs — work only your assigned section.

This app exists purely to give the CI/CD pipeline (see
`inbox/requirement_ci-cd.md`) something real to build, test, and promote —
keep it small. It's separate from `terraform/app`'s whoami, which keeps
serving the Terraform/infra demo unchanged.

---

## Section 0 — Base app scaffold

**Directory:** `app/`
**Base branch:** `main` (this demo's stand-in for "production" — the repo's
existing trunk, not a separately-created branch)
**Target branch:** `main` directly — this section represents already-
existing baseline code, not a reviewed feature, so it doesn't go through
the `QA`-branch review flow Sections 1/2 use.

- Node.js + Express, minimal dependencies.
- `/health` endpoint — returns JSON. This is for Kubernetes liveness/
  readiness probes later, not meant for a human to read in a browser.
- Test framework wired up (Jest or similar), with at least one passing
  test for `/health`, so the suite isn't empty before Sections 1/2 add to
  it.
- A single shared router/route-registration file that Sections 1 and 2
  will both add to.
- `Dockerfile` — multi-stage build, non-root user, slim runtime image.
- `.dockerignore`.
- ESLint config, no lint errors on the scaffold itself.
- No routes beyond `/health` yet.

## Section 1 — Feature A

**Base branch:** `main` (after Section 0 is merged)
**Target branch:** `QA`

- One route, your choice of what it does — keep it small enough that a
  viewer can see the response and immediately tell it's different from
  Feature B.
- Plain text or simple rendered HTML response is enough — no separate
  frontend, no build step. `/health` stays JSON; this route doesn't need
  to be.
- Register the route in the shared router file from Section 0.
- At least one unit test for the route.

## Section 2 — Feature B

**Base branch:** `main` (after Section 0 is merged)
**Target branch:** `QA`

- Same shape as Section 1 — one route, visibly distinct from Feature A's,
  plain text/simple HTML response, at least one unit test.
- Register the route in the same shared router file Section 1 uses — both
  features touching that file is deliberate, not a mistake: it's what
  makes the merge into `QA` a real merge conflict to resolve, rather than
  two conflict-free parallel merges.

---

## Notes for whoever's running the parallel-terminal session

- Section 0 must merge to `main` before Sections 1 and 2 can branch —
  it's the only ordering dependency. Sections 1 and 2 have no dependency
  on each other and can be worked fully concurrently once Section 0 is in.
- Sections 1 and 2 are meant to be worked by two separate developer
  sessions/identities ("Dev A", "Dev B" — separate `git commit --author`,
  not separate GitHub accounts), each opening its own PR against `QA`.
- Every PR into `QA` needs its CI checks to pass plus 1 required approving
  review (the "lead developer" role) before merge — the developer agent
  stops at "PR opened, waiting," it never merges its own work.
- CI/CD pipeline work (the GitHub Actions workflow, Kubernetes manifests,
  Terraform for namespaces/OIDC) is **not** in this file and isn't the
  developer agent's job — that's `devops`, per `inbox/requirement_ci-cd.md`.
