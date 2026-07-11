# AI DevOps Demo — Agent-Driven Infrastructure Automation

A reference implementation of an infrastructure-automation agent system
built on Claude Code. Three specialized agents handle infrastructure
requests end to end: routing the request, generating and applying the
Terraform to fulfill it, and diagnosing/recovering from problems — all
through the same guardrail, whether it's a routine change or an incident
fix.

## What this is

- **`coordinator`** — classifies an incoming request (a change vs. an
  incident) and routes it to the right specialist, or reports on work
  already in flight.
- **`devops`** — generates and applies Terraform for any infrastructure
  change: cluster/node configuration, databases, storage, monitoring,
  anything asked for. The only agent that ever writes or applies
  Terraform.
- **`sre`** — investigates live problems, identifies root cause, and
  hands the fix off to `devops` rather than applying anything itself.

Every agent is an **in-conversation agent** — triggered by typing its
name in a normal Claude Code session (`coordinator`, `devops`, or `sre`,
with or without a leading `@`), the same session continues directly as
that agent. No spawning, no separate context, no relayed summaries.

Every infrastructure change goes through the same path regardless of
urgency or which agent originated it: a policy-validation check (the
Checker) before anything applies, then Claude Code's own real interactive
approval prompt (the Gate) — neither of which can be skipped by asking
nicely. Changes are also proposed as a pull request first: `devops`
branches, pushes, and opens a PR, then stops and waits for a human to
merge it (or runs `gh pr merge` itself, which always prompts for
approval) before it ever plans or applies.

## Prerequisites

- [Claude Code](https://claude.com/claude-code) CLI
- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.7
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html),
  configured with a profile that has permissions to create VPCs, EKS
  clusters, RDS instances, S3 buckets, and CloudWatch alarms
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [GitHub CLI (`gh`)](https://cli.github.com/), authenticated
  (`gh auth login`)
- A way to authenticate Claude Code — either a Claude subscription
  (Pro/Max/Team/Enterprise) or an Anthropic API key; see Setup step 2

## Setup

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
```

`requirements.md` is an alternative way to hand `devops` a request — a
structured brief instead of a one-line ask, useful for larger or
multi-part infrastructure changes, or for running several `devops`
sessions in parallel against different sections of the same file.

Task records for each agent live under `agents/{name}/tasks/` — a plain
filesystem convention (`planned/` → `in-progress/` → `done/`), not a
Claude Code feature, that tracks what each agent has worked on.

**Ending a session:** actual infrastructure changes are already
committed and pushed as part of `devops`'s normal procedure (each one
goes through its own branch and PR). For anything else that accumulated
locally during the session — task record updates, session notes — ask
`devops` to commit and push it before you close the session, so nothing
is left uncommitted between sessions:

```
devops commit and push any outstanding changes
```

## Project structure

```
agents/           Agent definitions (SKILL.md), task records, runbooks
terraform/
  vpc/            Network layer
  eks/            Cluster layer
  app/            Sample application layer
  rds/            Database layer
  s3/             Storage layer
requirements.md   Example structured brief for devops
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
