## Agents — named-agent pattern

Three agents: coordinator, devops, sre. Each is an **in-conversation
agent**, not a spawned subagent — when triggered, *this* session reads a
bootstrap prompt and continues the conversation directly as that agent.
No Task/Agent-tool spawn, no isolated context, no relay.

Trigger works **with or without `@`** — `coordinator {request}` and
`@coordinator {request}` both bootstrap the same way. Both forms are safe
as long as `.claude/agents/` stays empty of any file named `coordinator`,
`devops`, or `sre` — `@name` is also Claude Code's syntax for its native
spawned-subagent feature (a separate mechanism — isolated instance, zero
conversation memory, briefed from scratch each time), and if a file
matching one of these names is ever added under `.claude/agents/`, `@name`
would silently start spawning that instead of bootstrapping
in-conversation. **Do not add a `coordinator`/`devops`/`sre`-named file
under `.claude/agents/`** — that's the one thing that would break this.

| Trigger | Bootstrap file | What happens |
|---------|----------------|--------------|
| `coordinator {request}` or `@coordinator {request}` | `agents/coordinator/SKILL.md` | Classifies the request (change → devops, incident → sre) or reports status by reading `agents/{devops,sre}/tasks/`, then bootstraps into the target agent in the same conversation |
| `devops {request}` or `@devops {request}` | `agents/devops/SKILL.md` | Bootstrap directly as DevOps — generates/applies Terraform for any infrastructure change, anywhere in `terraform/*`. Safe to address directly, skipping the coordinator, when the request is obviously a change. Also the agent SRE hands fixes off to — DevOps is the only agent that writes/applies Terraform |
| `sre {request}` or `@sre {request}` | `agents/sre/SKILL.md` | Bootstrap directly as SRE — diagnoses infrastructure problems and states root cause, then hands off to DevOps to implement the fix. SRE never applies Terraform itself. Safe to address directly when the request is obviously an incident |

Each agent's folder (`agents/{name}/`) also has its own `runbooks/`
(operational reference material, filled in as real usage happens) and
`session.md` (cross-session continuity notes, not yet wired into any
procedure).

Task records live in `agents/{coordinator,devops,sre}/tasks/{planned,in-progress,done}/`
— a plain filesystem convention, not a Claude Code feature. The real
guardrail (Checker hook + interactive approval Gate in `.claude/settings.json`)
is unaffected by any of this — it fires on `terraform apply` regardless of
which agent mode the session is in. A second, equally real checkpoint sits
in front of it: DevOps pushes changes on a branch and opens a PR before
ever touching `plan`/`apply` — merging is either done by a human directly
on GitHub, or by DevOps itself via `gh pr merge`, which is deliberately
left off the allowed-commands list so it always prompts for approval, the
same way `terraform apply` does.

See `README.md` for setup and usage.
