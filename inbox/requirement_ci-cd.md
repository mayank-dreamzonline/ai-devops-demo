# CI/CD Requirements — DevOps Agent Brief

This is a human-written brief for the second demo (CI/CD use case), same
format as `requirements.md` — read the section(s) assigned, treat it as your
task's **Request**, and follow the normal `agents/devops/SKILL.md` procedure:
log the task, branch, write the change, PR, wait for merge, apply, verify.

---

## Scope decision — read first

`agents/devops/SKILL.md` currently scopes this agent to Terraform only
("the only agent that ever writes or applies Terraform"). A CI/CD pipeline
definition is not Terraform — it's pipeline-as-code. Rather than add a new
agent, **extend `devops`'s remit to cover CI/CD pipeline authoring and
deployment tooling**, matching how `devops` is already scoped one repo over
in `~/Desktop/Portfolio/ai-agent-orchestration` ("CI/CD,
infrastructure-as-code, provisioning, deployment tooling"). Update
`agents/devops/SKILL.md`'s identity section to match before starting the
pipeline work, so the two repos describe the same role consistently.

`coordinator` routes a pipeline-setup/change request to `devops` the same
way it already routes an infra-change request — no new routing logic needed,
just confirm `coordinator`'s classification covers "add/change a CI/CD
pipeline" as a `devops` job.

---

## Demo target flow

Matches the standard CI pipeline → CD pipeline model (build/test/package on
the CI side, environment-by-environment deploy on the CD side):

```
Build → Unit tests → Package → Integration tests → Artifact repo
  → Deploy to DEV → Integration + security scan
  → Deploy to STAGING → Deploy to PROD
```

Targets the EKS cluster already provisioned by `terraform/eks` — the
compute layer is reused as-is. The existing `terraform/app` (whoami) is
**not** reused for this demo: whoami is a pre-built public image with no
source, no Dockerfile, no tests, so it has nothing for "Build" or "Unit
tests" to operate on. See Section 0.

## Section 0 — Sample application (new, small, purpose-built)

- A minimal fresh web service — a handful of routes plus a `/health`
  endpoint, whatever language/framework is fastest to stand up. Small
  enough to build in seconds; the point is exercising the pipeline, not the
  app itself.
- 5-10 real unit tests — enough for "Unit tests" to be a genuine pass/fail
  gate, not decorative.
- A `Dockerfile` for the Package stage.
- Lives in this repo (e.g. `app/`), separate from `terraform/app`'s whoami
  — whoami keeps serving the Terraform/infra demo unchanged; this is a
  second, small app that exists only to give the CI/CD pipeline something
  real to build, test, and promote.
- Freshly written for this repo, so no confidentiality/IP question — same
  treatment as everything else already in this reference implementation.

## Section 1 — CI stage (build, test, package)

**File:** a new GitHub Actions workflow, e.g. `.github/workflows/ci-cd.yml`.

- Trigger: PR open/update against `main` runs CI only (build + unit tests +
  package + integration tests). Merge to `main` runs CI, then proceeds to CD.
- Build: the Section 0 sample app.
- Unit tests: run the app's own test suite; fail the pipeline on failure.
- Package: `docker build`, tag with the commit SHA — this tag is the
  artifact that gets promoted unchanged through every later stage. Do not
  rebuild per environment; rebuilding per environment is the #1 thing that
  makes a CI/CD demo look naive rather than production-grade.
- Integration tests: a lightweight smoke test against the built container
  (spin up, hit a health endpoint, tear down) — not a full environment test,
  that happens after DEV deploy.
- Artifact repo: push the tagged image to GitHub Container Registry (GHCR) —
  no new infra, already free with the existing GitHub remote this repo
  depends on.

## Section 2 — CD stage (environment promotion)

**Mechanism:** GitHub Environments, one per tier (`dev`, `staging`, `prod`),
each referenced by the workflow's `environment:` key. This is the gate
mechanism — reuses the same "a human has to approve before anything real
happens" story as the Terraform demo's Gate, just implemented via GitHub's
own environment protection rules instead of Claude Code's approval prompt.

- **Deploy to DEV** — automatic on merge to `main`, no approval required.
  `kubectl set image` (or equivalent) against the existing EKS cluster's
  `dev` namespace, using the exact image tag built in Section 1 — never a
  fresh build.
- **Integration + security scan** — runs against the DEV deployment.
  Security scan: a container image scanner (e.g. Trivy or Grype — either is
  a single GitHub Action step, no new infra) against the same image tag.
  Fail the pipeline on a high/critical finding.
- **Deploy to STAGING** — gated by GitHub Environment required-reviewer
  protection. Same image tag, same deploy mechanism, `staging` namespace.
- **Deploy to PROD** — gated the same way, separate required reviewer if
  meaningful for the demo. `prod` namespace. This is the moment to narrate
  the promotion discipline explicitly on camera: it's the same artifact that
  passed DEV and STAGING, not a rebuild — that's the detail worth stopping
  on.

## Section 3 — Namespacing

Reuse the existing EKS cluster; add `dev`/`staging`/`prod` Kubernetes
namespaces if they don't already exist (the current Terraform app layer may
only target one). If adding namespaces requires a Terraform or `kubectl`
change, that piece goes through `devops`'s existing Terraform/apply path
first — the pipeline work in Sections 1-2 assumes the namespaces already
exist.

## Out of scope for this demo

- A ticket/change-management gate before each promotion (real systems often
  have one; not needed to demonstrate the pattern).
- Splitting CD out into a separate GitOps repo + ArgoCD/Flux sync — direct
  `kubectl set image` from the pipeline is enough to demonstrate gated
  promotion; GitOps is a real refinement but adds a second repo and tool for
  no new teaching value in a 1-hour recording.
- Automated rollback — optional stretch if time allows once the above is
  solid; a manual `kubectl rollout undo` narrated on camera is enough if
  automation doesn't fit the recording window. Natural tie-in to the
  existing `sre`-hands-off-to-`devops` story if it's included.
- Multi-region / multi-account promotion.

## Recording notes (carried from `agents/tasks/InProgress/drona-059.md`)

- Test audio levels with a short clip before the full take — this was the
  one thing flagged on the first demo.
- The current folder path visible on screen is fine for this recording,
  no redaction needed (unlike other-audience demos).
- If any real chance this gets reused elsewhere (portfolio, other bids),
  record from a generically-named location from the start rather than
  needing a second take later.
