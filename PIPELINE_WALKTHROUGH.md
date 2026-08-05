# CI/CD Pipeline — Architecture & Design

This document explains the CI/CD pipeline built in this repository: the
agent roles that build and operate it, the architecture, and a
file-by-file breakdown of the implementation.

The demo is built in two parts:
- **Part 1:** the CI/CD pipeline itself is built — GitHub configuration
  plus all workflow, action, and manifest code — and merged to `main`.
  Nothing triggers it yet.
- **Part 2:** a real application change is made on a feature branch, PR'd
  against `main`, and merged. That merge exercises the whole pipeline for
  the first time, end to end, through to a production deployment.

---

## 1. Agents

Four named, in-conversation agents drive this project: `coordinator`,
`devops`, `sre`, `developer`. Each is bootstrapped directly into the same
conversation from a definition file (not a spawned, isolated subagent),
so the agent has full context of the work rather than starting fresh
each time.

- **coordinator** — entry point. Classifies incoming requests (an
  infrastructure or pipeline change routes to `devops`; a failure routes
  to `sre`; an application-code change routes to `developer`) and reports
  status by reading each agent's own task records. It does not write code
  or touch infrastructure itself.
- **devops** — the only agent that writes and applies Terraform, and also
  owns CI/CD pipeline authoring and deployment tooling. Every change
  follows the same path: branch, pull request, wait for merge, then (for
  Terraform) plan, pass through an automated policy check and a real
  interactive approval, apply, and verify.
- **sre** — diagnoses infrastructure problems and states root cause, then
  hands the fix to `devops`. It never applies a fix itself.
- **developer** — writes application code only: routes, business logic,
  tests. It branches, commits, and opens a pull request, then stops —
  it never merges its own work.

This mirrors a real platform-team split: a platform/DevOps role owns
infrastructure and delivery tooling, SRE diagnoses incidents, and
application developers ship product code — rather than one agent doing
everything. Each agent keeps its own task log
(`agents/{name}/tasks/{planned,in-progress,done}/`), a plain filesystem
convention that gives every action an audit trail.

---

## 2. Pipeline Architecture

### Branching model
The repository uses a single trunk, `main`. Feature branches are opened
directly against it and merged via pull request — no separate,
long-lived integration branch.

### Build once, promote unchanged
The container image is built and tagged with the commit SHA exactly
once, at merge time. Every later stage — `dev`, `staging`, `prod` —
deploys that same tag; none of them rebuild. This is what makes the
pipeline a genuine promotion process rather than three independent
deployments: what passed testing is verifiably what reaches production.

### Stage by stage
The pipeline follows a standard CI/CD shape: build, test, package,
integration test, push to an artifact repository, deploy to a
development environment, run integration and security checks, then
promote through staging and production.

```
PR → main:      build, lint, unit test, dependency scan, secrets scan
                 (required checks before merge)

merge → main:    same checks again, then:
  package         build once, tag with the commit SHA, push to GHCR,
                  smoke-test the built container
  security-scan   container image scan, fails on high/critical findings
  deploy-dev      automatic, no approval gate
  verify-dev      smoke test against the live dev deployment
  deploy-staging  gated — pauses for required-reviewer approval
  deploy-prod     gated the same way, after staging sign-off
```

This is Continuous **Delivery**, not Continuous Deployment: production
requires a real human approval rather than fully automated release.

`main`'s branch protection requires status checks to pass before merge,
but not a reviewer approval — pull request self-approval is blocked
unconditionally by GitHub, so a required-review count would need a
workaround with no genuine second reviewer behind it. The human-approval
step is instead carried by the `staging` and `prod` environment gates,
where self-approval is permitted (a distinct mechanism from pull request
review).

### One reusable workflow, one thin caller per service
- `_reusable-ci-cd.yml` holds the pipeline logic above, written once and
  parameterized (application name, path, Kubernetes manifest path, image,
  and a `deploy` flag that is true only on merge or a manual run, not on
  a pull request).
- `ai-devops-demo-app.yml` is a thin caller: this service's name, paths,
  and image, invoking the reusable workflow.

This is the extensibility mechanism: adding a second service means
adding its own manifest directory and its own thin caller file, invoking
the same reusable workflow — the pipeline logic itself is never
duplicated. This is GitHub's own documented pattern for sharing CI/CD
logic across multiple services in one repository.

Deploying to `dev`, `staging`, and `prod` is functionally identical work
— point the Kustomize overlay at the built tag, apply it, wait for the
rollout — so it is implemented once as a composite action
(`.github/actions/deploy-to-env/`) and called three times, rather than
repeated inline.

### Manifests via Kustomize
`cicd/k8s/ai-devops-demo-app/base/` defines the Deployment and Service;
`overlays/{dev,staging,prod}/` each set the target namespace, and `prod`
additionally sets two replicas. Kustomize was chosen over three
hand-maintained manifest sets, which drift apart over time, and over
Helm, which is unnecessary overhead for a single service and chart.

### Authentication: OIDC, no static credentials
GitHub Actions authenticates to AWS via OpenID Connect: each workflow run
requests a short-lived signed token from GitHub and exchanges it for
temporary AWS credentials by assuming an IAM role trusted only by this
repository. That role's IAM policy grants only `eks:DescribeCluster`.
Kubernetes-level permissions are separate — an EKS access entry grants
the role edit access scoped to the `dev`, `staging`, and `prod`
namespaces only, not cluster-wide access. Two distinct permission
systems, deliberately bridged narrowly.

GitHub Environment required-reviewers are available on private
repositories only with GitHub Enterprise; on other plans the feature
requires the repository to be public. This repository is public as a
result — nothing sensitive is stored in it (no committed credentials,
and the AWS account ID is resolved at plan time rather than hardcoded
anywhere).

### Approval gates
`staging` and `prod` are configured as real GitHub Environments with a
required reviewer and administrator bypass disabled on both, verified
directly against the GitHub API rather than assumed from the settings
UI.

---

## 3. Implementation — File by File

### `app/` — the sample service
- `src/server.js`, `src/app.js`, `src/router.js` — a minimal Express
  application. `/health` returns JSON for Kubernetes probes; `/tip`
  returns plain text.
- `src/lookup.js` — the application's one piece of real logic: given an
  array of `{text, category}` entries and an optional category, returns
  a random match, or a 400 error if the category doesn't exist. The unit
  tests exercise this directly (default selection, valid category,
  invalid category), not just a status-code check.
- `data/tips.js` — the content served by `/tip`.
- `Dockerfile` — multi-stage build (dependencies, then runtime),
  non-root user, and removes `npm`/`npx` from the final image. The
  runtime only ever executes `node src/server.js`; npm's own bundled
  tooling — not this application's single dependency, `express` — was
  the source of vulnerabilities the security scan originally caught.

### `cicd/k8s/ai-devops-demo-app/`
- `base/deployment.yaml` — one replica, readiness and liveness probes on
  `/health`, image pull via `ghcr-pull-secret`, image tag as a
  placeholder set at deploy time.
- `base/service.yaml` — ClusterIP, reachable inside the cluster and via
  `kubectl port-forward` for verification; no public load balancer.
- `overlays/{dev,staging,prod}/kustomization.yaml` — namespace set per
  environment; `prod` additionally patches replica count to 2.

### `.github/actions/deploy-to-env/action.yml`
A composite action with four steps: confirm `kustomize` is available
(GitHub-hosted runners already include it, so installation only runs if
it's genuinely missing), inject the built image tag via `kustomize edit
set image`, apply the manifests with `kubectl apply -k`, and confirm the
rollout completed with `kubectl rollout status`.

### `.github/workflows/_reusable-ci-cd.yml`
The full job graph described in Section 2. `package`'s `packages: write`
permission and the deploy jobs' `id-token: write` permission are both
capped by whatever the calling workflow grants — a reusable workflow's
jobs can never request more than their caller allows. `verify-dev`'s
smoke test polls the port-forward tunnel with `curl
--retry-connrefused` rather than a fixed delay, since a fixed delay
races against the tunnel actually being ready.

### `.github/workflows/ai-devops-demo-app.yml`
The thin caller. Declares the `permissions:` block that sets the ceiling
for everything the reusable workflow can request, defines the triggers
(pull request and push against `main`, plus a manual `workflow_dispatch`
trigger), and passes this service's specific inputs.

---

## 4. Deliverable Boundary

The application code, Kubernetes manifests, and workflow definitions are
the shipped deliverable. GitHub repository settings — branch protection,
environment reviewers, the AWS role variable — are configuration, not
code, and are documented separately as one-time setup steps rather than
shipped as files. The live AWS infrastructure (the EKS cluster, IAM
role, and running workloads) is not shipped either; only the Terraform
that can recreate it is.
