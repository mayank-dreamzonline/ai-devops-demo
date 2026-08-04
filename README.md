# AI DevOps Demo — Agent-Driven Infrastructure Automation

A reference implementation of an infrastructure-automation agent system
built on Claude Code. Four specialized agents handle both infrastructure
and application-code requests end to end: routing the request,
generating and applying the Terraform or CI/CD pipeline to fulfill it,
writing the application code that flows through that pipeline, and
diagnosing/recovering from problems — all through the same guardrail,
whether it's a routine change or an incident fix.

## What this is

- **`coordinator`** — classifies an incoming request (a change, an
  incident, or an app-code task) and routes it to the right specialist,
  or reports on work already in flight.
- **`devops`** — generates and applies Terraform for any infrastructure
  change (cluster/node configuration, databases, storage, monitoring,
  anything asked for), and authors/maintains the CI/CD pipeline itself
  (GitHub Actions workflows, Kubernetes manifests, deployment tooling).
  The only agent that ever writes or applies Terraform.
- **`sre`** — investigates live problems, identifies root cause, and
  hands the fix off to `devops` rather than applying anything itself.
- **`developer`** — writes application code (routes, business logic,
  unit tests) on its own feature branch and opens a PR. Never touches
  Terraform, pipeline definitions, or Kubernetes manifests, and never
  merges its own work.

Every agent is an **in-conversation agent** — triggered by typing its
name in a normal Claude Code session (`coordinator`, `devops`, `sre`, or
`developer`, with or without a leading `@`), the same session continues
directly as that agent. No spawning, no separate context, no relayed
summaries.

Every infrastructure change goes through the same path regardless of
urgency or which agent originated it: a policy-validation check (the
Checker) before anything applies, then Claude Code's own real interactive
approval prompt (the Gate) — neither of which can be skipped by asking
nicely. Changes are also proposed as a pull request first: `devops`
branches, pushes, and opens a PR, then stops and waits for a human to
merge it (or runs `gh pr merge` itself, which always prompts for
approval) before it ever plans or applies. `developer` follows the same
branch-then-PR shape for app code, but never merges its own PR at
all — a human (or `devops`, for infra PRs) always does that part.

## Prerequisites

- [Claude Code](https://claude.com/claude-code) CLI
- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.7
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html),
  configured with a profile that has permissions to create VPCs, EKS
  clusters, RDS instances, S3 buckets, and CloudWatch alarms
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [GitHub CLI (`gh`)](https://cli.github.com/), authenticated
  (`gh auth login`)
- [Node.js](https://nodejs.org/) 22.x and [Docker](https://docs.docker.com/get-docker/)
  — only needed for the CI/CD pipeline demo (`app/`); `developer` runs
  `npm test`/`npm run lint` locally as a sanity check, and the pipeline
  itself builds `app/Dockerfile`
- A way to authenticate Claude Code — either a Claude subscription
  (Pro/Max/Team/Enterprise) or an Anthropic API key; see Setup step 2

## Setup

> Some files here (`.claude/`, `.gitignore`, `.env.example`) start with a
> dot and won't show up in a plain `ls` or file browser — use `ls -la`
> (or "show hidden files" in Finder/Explorer) to see them.

1. Clone this repo.
2. Authenticate Claude Code, whichever applies to you:
   - **Claude subscription** (simplest, no key needed): run `claude` in
     this directory and log in when prompted, or run `claude login`
     directly.
   - **API key instead**: copy `.env.example` to `.env` and set your own
     `ANTHROPIC_API_KEY`.
3. Set your AWS profile name and region in each `terraform/*/variables.tf`
   (default profile name is `ai-devops-demo` — change it to match your
   own AWS CLI profile, or create a profile with that name).
4. Push this repo to your own GitHub remote — `devops`'s apply path
   depends on being able to open real pull requests against it.
5. Provision the foundation layer once, before doing anything else:
   ```
   terraform -chdir=terraform/vpc init && terraform -chdir=terraform/vpc apply
   terraform -chdir=terraform/eks init && terraform -chdir=terraform/eks apply
   ```
   The EKS cluster takes roughly 10-15 minutes to provision.
6. Point `kubectl` at the new cluster:
   ```
   aws eks update-kubeconfig --name ai-devops-demo --region <your-region> --profile <your-profile>
   ```

## Usage

Start a Claude Code session in this directory, then address an agent
directly:

```
coordinator deploy a Postgres database with monitoring
devops create an S3 bucket for application logs
sre pods keep getting stuck in Pending, investigate
developer add a new category to the /tip endpoint
```

`inbox/*.md` files are an alternative way to hand an agent a request — a
structured, human-written brief instead of a one-line ask, useful for
larger or multi-part changes, or for running several sessions in
parallel against different sections of the same file. `devops` and
`developer` both read from `inbox/`; the agent reads whichever
section(s) it's pointed at and treats that as its request.

Task records for each agent live under `agents/{name}/tasks/` — a plain
filesystem convention (`planned/` → `in-progress/` → `done/`), not a
Claude Code feature, that tracks what each agent has worked on.

## CI/CD pipeline demo

Beyond the Terraform/infrastructure story above, this repo also
demonstrates a full application CI/CD pipeline, built and exercised
entirely by the agents — a two-part demo:

**Part 1 — `devops` builds the pipeline** (`inbox/requirement_pipeline.md`):
Kustomize manifests per environment (`cicd/k8s/<service>/`), a composite
GitHub Action that promotes an image to one environment, a reusable
workflow holding all the pipeline logic, and a thin per-service caller
workflow. This lands on `main` on its own PR, with nothing yet
triggering it — the pipeline exists, but hasn't run for real yet.

**Part 2 — `developer` ships a real change** that exercises it for the
first time (`inbox/requirement_app.md`, Section 3): a small, deliberately
low-risk app change (adding a new category to an existing endpoint) on
its own feature branch, PR'd and merged against `main`. That merge is
what actually fires the pipeline:

```
build-lint-test ─┐
dependency-scan  ├─► package ─► security-scan ─► deploy-dev ─► verify-dev ─► deploy-staging ─► deploy-prod
secrets-scan    ─┘                                              (auto)      (needs approval)  (needs approval)
```

- `build-lint-test` / `dependency-scan` / `secrets-scan` run on every PR
  and every merge — plain CI, no deployment.
- `package` builds and pushes the image to GHCR, then smoke-tests the
  exact image it just pushed.
- `security-scan` runs Trivy against that image, failing the run on any
  HIGH/CRITICAL finding.
- `deploy-dev` / `verify-dev` deploy and then live-verify `dev` — no
  approval gate, this is the "keep moving" stage.
- `deploy-staging` and `deploy-prod` are each a real GitHub Environment
  approval gate — a human has to click approve before either runs. This
  is Continuous **Delivery** (gated), not Continuous Deployment.

Every job authenticates to AWS via OIDC (no static keys anywhere in this
repo — see `terraform/github-oidc/`), and both `devops` and `developer`
verify the result the same way: `kubectl port-forward` into the target
namespace and `curl` the endpoint directly, at every stage of the
promotion, so the same command proves the same thing in `dev`, `staging`,
and `prod` in turn.

**Ending a session:** actual code/infrastructure changes are already
committed and pushed as part of `devops`'s and `developer`'s normal
procedure (each one goes through its own branch and PR). For anything
else that accumulated locally during the session — task record updates,
session notes — ask whichever agent is active to commit and push it
before you close the session, so nothing is left uncommitted between
sessions:

```
devops commit and push any outstanding changes
developer commit and push any outstanding changes
```

## Project structure

```
agents/                Agent definitions (SKILL.md), task records, runbooks
terraform/
  vpc/                 Network layer
  eks/                 Cluster layer
  namespaces/          dev/staging/prod Kubernetes namespaces
  github-oidc/         GitHub Actions OIDC provider + IAM role (no static AWS keys)
  app/                 Sample "whoami" app for the Terraform/infra demo
  rds/                 Database layer
  s3/                  Storage layer
app/                   The Node.js app the CI/CD pipeline demo builds and ships
  src/                 Express routes, shared lookup() helper
  data/                Content the app's routes serve (e.g. tips.js)
  __tests__/           Jest unit tests
cicd/k8s/<service>/    Kustomize manifests (base + dev/staging/prod overlays)
.github/
  workflows/           Reusable + caller GitHub Actions workflows
  actions/deploy-to-env/  Composite action: promote an image to one environment
inbox/                 Human-written requirement briefs handed to devops/developer
scripts/
  inject_fault.sh       Manually simulates an infrastructure fault (for
                         testing the sre/devops recovery path)
  hooks/terraform-checker.sh   The Checker — validates a Terraform plan's
                                actual content before any apply is allowed
.claude/settings.json         Permissions and hook wiring for the guardrail
```

## Notes

- **This provisions real cloud infrastructure and incurs real cost.**
  Nothing here is simulated — every `apply` creates or changes actual AWS
  resources.
- **`terraform destroy` is permanently denied to every agent**, by
  design — tearing anything down is always a manual, human-run action.
  See `agents/devops/runbooks/teardown-and-reset.md` for the correct
  order to destroy each layer.
- The Checker (`scripts/hooks/terraform-checker.sh`) enforces two policies
  out of the box: no `LoadBalancer`-type Kubernetes services, and no
  deleting the cluster/VPC through a routine change. Extend it directly
  for your own policies — it only ever makes an apply *more* restrictive,
  never bypasses the human approval step that follows it.
- Never commit a real `.env` or hardcode credentials anywhere in
  `terraform/*` — every example here reads secrets from generated values
  (e.g. `random_password`) or the environment, never from committed files.
