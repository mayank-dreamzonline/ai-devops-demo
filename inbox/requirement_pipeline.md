# CI/CD Pipeline Requirements — DevOps Agent Brief

Human-written brief handed to the devops agent, same convention as the
other `inbox/` briefs. Read the section(s) assigned, treat that as your
task's **Request**, follow the normal procedure (`agents/devops/SKILL.md`)
— log the task, branch, write the code, PR, wait for merge, verify.

Every requirement below is specified precisely enough to build a working
pipeline in a single pass — versions, trigger conditions, job ordering,
and the GitHub-side settings it depends on are all stated explicitly
rather than left to be discovered while building.

`app/` (Section 0 + `/tip`) and all infra (`terraform/vpc`,
`terraform/eks`, `terraform/namespaces`, `terraform/github-oidc`) already
exist and are already applied — this brief covers only the pipeline
layer: Kustomize manifests, the composite action, the two workflow
files, and the one-time GitHub setup.

**This is Part 1 of the two-part demo** — devops builds and merges this
entire brief to `main` first, with nothing yet triggering it. Part 2 (a
separate, later request) has `developer` make one real app change on a
feature branch, PR it against `main`, and merge — that merge is what
actually exercises the whole pipeline for the first time. Devops has no
role in Part 2.

**Code comment rule:** this is a professional reference implementation,
not internal notes — code comments must never name a specific person,
channel, or video as the source of a design decision. If a stage's shape
matches a well-known CI/CD pattern, describe it generically (e.g. "a
standard CI/CD flow: build → test → package → deploy" or "the flow
diagram this demo follows"), never attributed to anyone by name.

**Branching note:** feature branches PR directly against `main` — no
separate `develop` integration branch. Simpler, and consistent with
everything else in this repo. This is what Section 5 below reflects.

---

## Section 0 — Dockerfile

**File:** `app/Dockerfile` (already exists, confirm this detail is
present)

- Multi-stage (`deps` → `runtime`), non-root user, slim.
- In the runtime stage, **after** copying app code and **before**
  switching to the non-root user, remove the base image's bundled global
  npm/npx: `rm -rf /usr/local/lib/node_modules/npm /usr/local/bin/npm
  /usr/local/bin/npx`. The runtime only ever calls `node src/server.js` —
  npm/npx are build-time tools with no reason to be in a production
  image, and their own bundled dependencies (not this app's — the app
  only depends on `express`) are what a container security scan will
  otherwise flag.

## Section 1 — Kustomize manifests

**Directory:** `cicd/k8s/<service-name>/` — one directory per service,
so a second service adds a sibling directory, not changes to this one.

- `base/deployment.yaml` — Deployment: readiness + liveness probes on
  `/health`, `imagePullSecrets: [ghcr-pull-secret]`, image tag as a
  placeholder (real tag injected at deploy time via `kustomize edit set
  image`, never committed).
- `base/service.yaml` — **ClusterIP**, not LoadBalancer (internal +
  `kubectl port-forward` for verification is enough for a sample app).
- `base/kustomization.yaml` — references both.
- `overlays/{dev,staging,prod}/kustomization.yaml` — each sets
  `namespace:` to match: `dev`, `staging`, `prod`. `prod` additionally
  patches `spec.replicas` to `2` (JSON-patch style, targeting the
  Deployment by kind+name) — the only difference between environments
  besides the tag.

## Section 2 — Composite action: promote to one environment

**File:** `.github/actions/deploy-to-env/action.yml`

Inputs: `environment`, `k8s-path`, `app-name`, `image`, `image-tag`.

Steps, in order:
1. **Ensure kustomize is available** — check first (`command -v
   kustomize`), only install if genuinely missing. **`ubuntu-latest`
   runners already ship `kustomize`** — an unconditional install step
   fails when it's already present ("exists, remove it first"). Not
   optional: skipping the check breaks the run.
2. `kustomize edit set image "<image>=<image>:<image-tag>"`, run inside
   `<k8s-path>/overlays/<environment>`.
3. `kubectl apply -k <k8s-path>/overlays/<environment>`.
4. `kubectl rollout status deployment/<app-name> -n <environment>
   --timeout=120s` — confirm it actually came up, don't just fire-and-forget.

## Section 3 — The reusable workflow (all pipeline logic)

**File:** `.github/workflows/_reusable-ci-cd.yml`

`on: workflow_call`, inputs: `app-name`, `app-path`, `k8s-path`, `image`
(all `string`), `deploy` (`boolean` — true only when this should run the
CD half, not just CI).

Jobs, in dependency order:

1. **`build-lint-test`**, **`dependency-scan`**, **`secrets-scan`** — run
   unconditionally (both on PR and on merge). Node setup at the pinned
   version matching the Dockerfile; `npm ci`, `npm run lint`, `npm test`;
   `npm audit --audit-level=high`; `gitleaks/gitleaks-action@v2` (check
   its current major/version tag is still valid before using it — don't
   assume a version number without checking, see the note at the bottom
   of this brief).
2. **`package`** — `if: inputs.deploy`, needs all three above. Tag with
   the short commit SHA. `docker/login-action@v3` to GHCR using
   `github.token` (no PAT needed for pushing — that's a separate concern
   from the *cluster* pulling the image, which uses the
   already-provisioned `ghcr-pull-secret`). `docker/build-push-action@v6`
   with **both** `push: true` and `load: true` (single-platform build,
   so this combination is supported — it is *not* supported for
   multi-platform builds, don't add a `platforms:` list). Then smoke-test
   the exact pushed/loaded image: `docker run -d`, hit `/health`, tear
   down. Needs job-level `permissions: { contents: read, packages:
   write }`.
3. **`security-scan`** — `if: inputs.deploy`, needs `package`.
   `aquasecurity/trivy-action` — **verify the version tag actually exists
   before pinning it** (check `gh api repos/aquasecurity/trivy-action/tags`
   or the repo's releases; don't guess a version number, a
   non-existent tag fails the whole run at startup with zero jobs run and
   a confusing error). `severity: HIGH,CRITICAL`, `exit-code: '1'`.
4. **`deploy-dev`** — `if: inputs.deploy`, needs `package`. `environment:
   dev` (no protection rules needed — auto, matches the CI/CD flow diagram
   this demo follows). OIDC auth (see Section 5) → `aws eks
   update-kubeconfig` → the
   composite action from Section 2. Needs `permissions: { id-token:
   write, contents: read }`.
5. **`verify-dev`** — needs `[package, deploy-dev]`. OIDC auth again (each
   job gets a fresh runner, fresh auth). Smoke test:
   `kubectl port-forward -n dev svc/<app-name> 8080:80 &` then **`curl
   --retry 10 --retry-delay 1 --retry-connrefused -sf
   http://localhost:8080/health`** — not a fixed `sleep` before curl. A
   fixed sleep races against the port-forward tunnel actually being
   ready and is flaky; `retry-connrefused` polls until the tunnel is
   actually up instead of guessing a delay.
6. **`deploy-staging`** — needs `[package, verify-dev, security-scan]`.
   `environment: staging` — this is the real gate (see Section 5 for the
   GitHub-side setup this depends on). Same auth + composite-action
   pattern as `deploy-dev`.
7. **`deploy-prod`** — needs `[package, deploy-staging]`. `environment:
   prod`, same pattern. This is Continuous **Delivery** (gated), not
   Continuous Deployment — say so explicitly if narrating this on camera.

## Section 4 — The thin caller workflow

**File:** `.github/workflows/<service-name>.yml` (e.g.
`ai-devops-demo-app.yml`) — one per service, no pipeline logic in it.

**Trigger paths: `<app-path>/**` only — do not also watch `<k8s-path>/**`.**
Watching the k8s-path too is the theoretically "more correct" choice (a
manifest-only change is a real deployable change), but it has a fatal
bootstrapping problem the first time this brief is executed: Part 1's own
deliverable is the first-ever commit of `<k8s-path>/**` to `main`, so a
k8s-path trigger fires on Part 1's own merge — the exact merge that's
supposed to land quietly with "nothing yet triggering it." This isn't
hypothetical; it happened on the first attempt at building this brief and
ran the pipeline mid-build. This demo never exercises a manifest-only
change triggering a deploy anyway, so the trade-off isn't worth it here —
app-path only.

```yaml
on:
  pull_request:
    branches: [main]
    paths: ['<app-path>/**']
  push:
    branches: [main]
    paths: ['<app-path>/**']
  workflow_dispatch: {}   # manual re-runs, e.g. to re-test a fix

concurrency:
  group: ci-cd-<service-name>-main
  cancel-in-progress: true

permissions:
  contents: read
  packages: write
  id-token: write
  # ^ This is not optional. The repo's default workflow permissions are
  # read-only. A reusable workflow's jobs (package needs packages:write,
  # the deploy jobs need id-token:write) can NEVER request more than
  # this caller grants — GitHub refuses to even start the run
  # ("Invalid workflow file", zero jobs created) if this block is
  # missing. Do not skip it.

jobs:
  ci-cd:
    uses: ./.github/workflows/_reusable-ci-cd.yml
    with:
      app-name: <service-name>
      app-path: <app-path>
      k8s-path: <k8s-path>
      image: ghcr.io/${{ github.repository_owner }}/<service-name>
      deploy: ${{ github.event_name == 'push' || github.event_name == 'workflow_dispatch' }}
```

## Section 5 — One-time GitHub setup (not code — repo settings)

These don't travel with the code and must be redone if the repo is ever
recreated.

**Deliberately no required-PR-review on `main`.** This is a solo-operated
repo — GitHub blocks PR self-approval unconditionally (no setting
disables it), so a required-review count of 1 would force a
`bypass_actors` workaround just for the owner to merge their own PRs.
That's real complexity — and a settings-drift-prone one — for a review
that can never genuinely come from a second person anyway. The
`staging`/`prod` environment approval gates already
carry the "a human must approve" story — self-approval *is* allowed
there, since environment-deployment approval is a different GitHub
mechanism from PR review (see Section 6). So: `main`'s PR gate is
**checks-required, no approval-required** — the PR still has to exist
and pass CI before merge, it's just not blocked on a reviewer.

1. **Repo must be public.** GitHub Environment required-reviewers are
   only available on private repos with GitHub Enterprise — Free/Pro/Team
   only get this feature on public repos. (Confirmed nothing sensitive
   needs to stay private here — no committed secrets, AWS account ID
   never hardcoded in any file.)
2. **Branch protection ruleset on `main`** — target `refs/heads/main`,
   rules:
   - `pull_request` with `required_approving_review_count: 0` — still
     requires a PR to exist (no direct pushes), just no reviewer needed.
   - `required_status_checks`, listing the CI job names once they exist
     (`build-lint-test`, `dependency-scan`, `secrets-scan` — exact check
     names only become selectable in the UI/API after the workflow has
     run at least once; add this rule in a follow-up edit after the
     first real PR, not on the very first attempt).
   - No `bypass_actors` needed — with 0 required approvals, there's
     nothing for the owner to need to bypass; a plain `gh pr merge`
     works directly, no `--admin` flag required.
3. **`staging` and `prod` GitHub Environments** — each needs:
   - Required reviewer: the owner's own GitHub username (self-approval
     is allowed for environment deployments — this is the one real "a
     human approves" gate in the whole flow).
   - "Allow administrators to bypass configured protection rules" —
     **unchecked** on both, so the gate is real.
   - Deployment branch policy scoped to `main` (either "Protected
     branches," which follows the ruleset dynamically, or an explicit
     custom policy naming `main`).
   - **Re-verify these three settings via the API after any later change
     to the environment's branch-policy list** — editing `prod`'s
     deployment-branch-policies sub-resource can silently clear its
     required-reviewers rule as a side effect. Cheap to check, expensive
     to discover during a recording:
     `gh api repos/<owner>/<repo>/environments/<name> --jq
     '.protection_rules, .can_admins_bypass'`
   - `dev` needs no protection rules — just needs to exist (it's created
     automatically the first time a workflow deploys to it).
4. **Repository variable** `AWS_ROLE_ARN` — the OIDC IAM role's ARN (from
   `terraform/github-oidc`'s output), set via `gh variable set
   AWS_ROLE_ARN --body "<arn>"`.

## Section 6 — GitHub platform behavior worth knowing before recording

- **PR review self-approval is always blocked**, unconditionally, no
  setting disables it — a PR's author can never approve their own PR,
  even as repo admin. Not a live concern given Section 5's 0-required-
  reviewers setup, but worth knowing if a viewer asks why `main` doesn't
  require review the same way `staging`/`prod` require approval.
- **Environment-deployment self-approval is allowed** — a genuinely
  different GitHub mechanism from PR review, which is why the
  `staging`/`prod` gates work with a solo operator and PR review
  wouldn't have, without the bypass-actor workaround.

---

## Build order

Section 0 (confirm Dockerfile) → Section 1 (Kustomize) → Section 2
(composite action) → Section 5 (GitHub setup — do this *before* Section
3/4 workflows are exercised, since a run will fail confusingly if the
environments/branch/variable don't exist yet) → Section 3 (reusable
workflow) → Section 4 (caller workflow) → commit and merge to `main`.
**Stop here — this is the end of Part 1.** Don't open a feature-branch PR
to exercise it; that's Part 2, and it's `developer`'s request, not this
one.
