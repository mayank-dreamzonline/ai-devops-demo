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
`inbox/requirement_pipeline.md`) something real to build, test, and
promote — keep it small. It's separate from `terraform/app`'s whoami,
which keeps serving the Terraform/infra demo unchanged.

**Status:** Section 0 and Section 1 (`/tip`) below were both built and
merged to `main` as described — accurate history, not hypothetical.
**Section 2 (`/fact`) and the parallel-developer/merge-conflict notes are
superseded** — dropped as unnecessary complexity. The demo now uses a
single feature (`/tip` only). **Part 2 of the pipeline demo is Section 3
below** — pinned down precisely (not left as "one more simple change") so
there's no ambiguity for whoever builds it: a `developer` change on a
feature branch, PR'd directly against `main`, no second identity or
deliberate conflict involved.

**Current deployment status:** the required infrastructure (VPC, EKS,
`dev`/`staging`/`prod` namespaces, GitHub OIDC role, GHCR pull secret) is
applied, and the app is already running in all three namespaces —
`dev` (1 replica), `staging` (1 replica), `prod` (2 replicas), all on the
same image tag, pulling from GHCR without issue. `/health` and `/tip`
both respond correctly when checked directly against the live pods, and
the full test suite passes (7/7: health, lookup, tip). **This is a
brownfield scenario** — any pipeline or app work from here on is shipping
a change to an app that's already live, not a first deployment; narrate
and document it that way.

---

## Section 0 — Base app scaffold

**Directory:** `app/`
**Base branch:** `main` (this demo's stand-in for "production" — the repo's
existing trunk, not a separately-created branch)
**Target branch:** `main` directly — this section represents already-
existing baseline code, not a reviewed feature, so it doesn't go through
the `develop`-branch review flow Sections 1/2 use.

- Node.js + Express, minimal dependencies.
- `/health` endpoint — returns JSON. This is for Kubernetes liveness/
  readiness probes later, not meant for a human to read in a browser.
- A shared `lookup(data, category)` helper: given an array of
  `{ text, category }` items and an optional `category`, returns a random
  matching item, or a random item from the full array if no category is
  given, or throws/signals an error if `category` doesn't match anything
  in the data. Content-agnostic — Sections 1 and 2 each bring their own
  data array and call this same helper.
- A single shared router/route-registration file that Sections 1 and 2
  will both add a route to — this is the deliberate merge-conflict point
  between the two features.
- Test framework wired up (Jest or similar), with at least one passing
  test for `/health` and at least one for the `lookup` helper itself, so
  the suite isn't empty before Sections 1/2 add to it.
- `Dockerfile` — multi-stage build, non-root user, slim runtime image.
- `.dockerignore`.
- ESLint config, no lint errors on the scaffold itself.
- No feature routes beyond `/health` yet.

## Section 1 — Feature A: `/tip`

**Base branch:** `main` (after Section 0 is merged)
**Target branch:** `develop`

- Add a `data/tips.js` array of DevOps tips, each `{ text, category }`
  (categories: `git`, `docker`, `kubernetes` — at least a couple of tips
  per category).
- Register `GET /tip` in the shared router file, calling Section 0's
  `lookup(tips, req.query.category)`:
  - No `category` query param → a random tip from the full set.
  - Valid `category` → a random tip filtered to that category.
  - Unrecognized `category` → `400` with an error message.
- Plain text or simple rendered HTML response — no separate frontend, no
  build step.
- 3 unit tests: default (assert the result is one of the known tips),
  valid category (assert the result belongs to that category),
  unrecognized category (assert `400`).

## Section 2 — Feature B: `/fact`

**Base branch:** `main` (after Section 0 is merged)
**Target branch:** `develop`

- Same shape as Section 1, different content: add a `data/facts.js` array
  of DevOps/tech facts, each `{ text, category }`, same three categories.
- Register `GET /fact` in the **same shared router file** Section 1
  registers `/tip` in, calling `lookup(facts, req.query.category)` with
  the same three behaviors (default/valid/unrecognized category). Both
  features touching that file is deliberate, not a mistake: it's what
  makes the merge into `develop` a real merge conflict to resolve, rather than
  two conflict-free parallel merges.
- Same 3 unit tests, mirrored for `/fact`.

## Section 3 — Part 2 of the pipeline demo: add a `terraform` category to `/tip`

**Base branch:** `main`
**Target branch:** `main` directly (no `develop` branch — dropped
repo-wide, see `inbox/requirement_pipeline.md`'s branching note)

**Current behavior, before this change** (verified live against
`app/data/tips.js` + `app/src/router.js`):

| Request | Response |
|---|---|
| `GET /tip` | random tip from all 9 (3 each: `git`, `docker`, `kubernetes`) |
| `GET /tip?category=git` (or `docker`/`kubernetes`) | random tip from that category |
| `GET /tip?category=terraform` | **`400`** — `lookup: no items found for category "terraform"` |

**The change — smallest real diff, same shape as Section 1, nothing
structurally new:**
- Add 2–3 new `{ text, category: 'terraform' }` entries to the existing
  `app/data/tips.js` array (e.g. "Pin provider versions to avoid surprise
  upgrades.", "Use remote state with locking, never local `.tfstate` in
  a team repo.", "Review `terraform plan` output before every apply.").
- **No new route, no new file, no new dependency.** `GET /tip`'s
  existing `category` query-param handling (Section 0's `lookup()`
  helper) already supports this — extending the data array is the whole
  change.
- Add one test asserting `category=terraform` now returns a valid tip
  (mirrors Section 1's three existing `/tip` tests — default/valid
  category/unrecognized category — this is a new "valid category" case).

**Behavior after this change:**

| Request | Response |
|---|---|
| `GET /tip?category=terraform` | **was `400`, now `200`** — a real terraform tip |

That `400` → `200` flip is the whole demo payload: easy to verify with
one `curl` per environment, and easy to see on camera that it's actually
new content, not a coincidence.

**Verification curls to actually run on camera — use explicit category
params, not the bare `/tip`.** The bare `GET /tip` picks randomly across
*all* categories once terraform tips exist, so it won't read as a clean,
consistent before/after on camera (it might show a kubernetes tip either
way, by chance). Use one fixed category on each side instead, so the
output is deterministic and the same command always proves the same
thing:

- **Before-state check** (any environment, pre- or unaffected by this
  change): `curl <env-url>/tip?category=kubernetes` → always returns a
  real kubernetes tip. Proves the app is up and serving its existing
  behavior correctly.
- **After-state check** (the actual proof this change shipped):
  `curl <env-url>/tip?category=terraform` → **`400` before this change
  is deployed to that environment, `200` with a real tip after.**

**Run the after-state check at every stage of the promotion, not just
staging/prod** — developer (or whoever's driving the reveal) runs `curl
.../tip?category=terraform` and shows the output at each of:
1. **`dev`** — right after `deploy-dev` completes (auto, no gate).
2. **`staging`** — right after `deploy-staging` completes (after your
   approval click). This is the first gated "it's really there" moment.
3. **`prod`** — right after `deploy-prod` completes (after your second
   approval click). Same command, same proof, now in prod.

Same URL path in all three, just a different environment's endpoint —
same evidence repeated at every stage is what makes the promotion visible
on camera, not just asserted.

---

## Notes for whoever's running the parallel-terminal session (historical — Sections 1/2 only, superseded)

**These notes describe the original two-feature/two-identity plan and no
longer reflect current reality — kept for history, not as current
guidance.** The `develop` branch they reference was dropped repo-wide
(see `inbox/requirement_pipeline.md`'s branching note), and Section 2
(`/fact`) itself is superseded per the Status note at the top. Section 3
is what's actually active now, and it targets `main` directly — read
Section 3's own Base/Target branch lines for current guidance, not this
section.

- Section 0 must merge to `main` before Sections 1 and 2 can branch —
  it's the only ordering dependency. Sections 1 and 2 have no dependency
  on each other and can be worked fully concurrently once Section 0 is in.
- Sections 1 and 2 are meant to be worked by two separate developer
  sessions/identities ("Dev A", "Dev B" — separate `git commit --author`,
  not separate GitHub accounts), each opening its own PR against `develop`.
- Every PR into `develop` needs its CI checks to pass plus 1 required approving
  review (the "lead developer" role) before merge — the developer agent
  stops at "PR opened, waiting," it never merges its own work.
- CI/CD pipeline work (the GitHub Actions workflow, Kubernetes manifests,
  Terraform for namespaces/OIDC) is **not** in this file and isn't the
  developer agent's job — that's `devops`, per `inbox/requirement_pipeline.md`.
