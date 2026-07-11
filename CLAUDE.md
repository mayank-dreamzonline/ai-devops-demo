# TechWorld with Nana (nnSoftware GmbH) — AI/DevOps Knowledge Transfer Demo

This is a standalone freelance client project. It has no dependency on Code2Capital —
a fresh `claude` session started in this folder should have everything it needs from
this file and `PROGRESS.md`.

## Engagement

- **Client:** TechWorld with Nana / nnSoftware GmbH (contact: Olga, chat under Upwork account "Nana Janashia")
- **Platform:** Upwork
- **Rate:** $85/hr, paid as 2hrs (1hr prep + 1hr recording) = ~$153 net after 10% fee
- **Deadline:** 2026-07-11 (flagged tight — offer accepted 2026-07-09, watch if this needs a follow-up date-push with Olga)
- **Deliverable:** One 1hr recorded demo video of a real infrastructure-automation agent, plus a fresh, non-proprietary reference-implementation code handover.

## Scope / Requirements

Content confirmed with the client (scope-clarification note sent 2026-07-07):
- Use-case category: infrastructure automation (not incident-detection) — an agent that
  generates code for infrastructure changes, applies it, and fixes/iterates on the
  outcome, with a human-in-the-loop guardrail.
- Client's stated requirement: "already built and used at work," not a proof-of-concept.
  The real work story satisfies this — a freshly-built demo with simulated traffic would
  not honestly satisfy it and should not be presented as such.
- Code handover: a clean reference implementation, decoupled from the employer's actual
  environment — not the employer's real repo.

## Decisions Made

- Tell the real infra-automation-agent story from work (satisfies "already built and
  used"), but hand over freshly-written, non-proprietary reference-implementation code
  (satisfies the IP boundary below). These are two separate goals — don't blur them.
- Checked TechWorld with Nana's own published YouTube content before assuming what "code
  handover" means: they also don't expose real client/production code in their own
  demos. Reference-implementation-style handover is the platform's actual norm.
- Two prior Loom videos exist from the original bid (background: dc290caf, ~6 min;
  use-case + terminal demo: 8c4025a5, ~3:54 min) — useful raw material / precedent for
  pacing and structure, not a substitute for the new recording.

## Confidentiality / IP Boundary

- Never hand over real Rezolve.ai proprietary code — not even renamed/relabeled.
  Renaming to obscure origin was explicitly considered and rejected: it reads as
  premeditated concealment if ever recognized, and makes the problem worse, not better.
- Build a fresh, honestly-labeled reference implementation instead. This applies to
  every artifact in this folder without exception.
- No real company names, internal architecture details, or production data in the video
  or the code.

## Secrets / API Keys

- Never commit real keys. `.env.example` holds a placeholder only; real `.env` is gitignored.
- Never hand a live key to Nana/Olga. The reference-implementation code reads
  `ANTHROPIC_API_KEY` from the environment — the client sets her own.
- Recording discipline: no `echo $ANTHROPIC_API_KEY`, no key visible in terminal output,
  prompts, or error messages during the screen recording.

## Client Communication Tone Rules

- No em-dashes.
- No blockquote (`>`) or pipe (`|`) formatting in any text meant to be copy-pasted
  (e.g. messages to Olga).
- No "thank you for the opportunity" / no mentioning this is a first Upwork job —
  professional warmth, not gratitude for being selected.
- Full worked example and formatting rules: see
  `agents/drona/data/bid-writing-patterns.md` in Code2Capital if further client notes
  need drafting (that file stays in Code2Capital, not duplicated here).

## Agents — named-agent pattern

Three agents: coordinator, devops, sre. Each is an **in-conversation
agent**, not a spawned subagent — when triggered, *this* session reads a
bootstrap prompt and continues the conversation directly as that agent.
No Task/Agent-tool spawn, no isolated context, no relay. This is the same
pattern used in the real production ai-ops system this demo's design is
modeled on (pattern only — nothing proprietary reused).

Trigger works **with or without `@`** — `coordinator {request}` and
`@coordinator {request}` both bootstrap the same way. Both forms are safe
today because `.claude/agents/` doesn't exist in this repo, so there's no
native subagent definition for Claude Code's own `@agent-name` feature (a
separate, real mechanism — isolated instance, zero conversation memory,
briefed from scratch each time) to collide with. `@name` only becomes
dangerous *if* a file matching that exact name is ever added under
`.claude/agents/` — that's what happened once during this project's build
(see `PROGRESS.md`): `@coordinator` got intercepted and spawned instead of
bootstrapping in-conversation, because `.claude/agents/coordinator/*.md`
existed at that moment. **Do not add a `coordinator`/`devops`/`sre`-named
file under `.claude/agents/`** — that's the one thing that would silently
break the `@` form here.

| Trigger | Bootstrap file | What happens |
|---------|----------------|--------------|
| `coordinator {request}` or `@coordinator {request}` | `agents/coordinator/SKILL.md` | Classifies the request (change → devops, incident → sre) or reports status by reading `agents/{devops,sre}/tasks/`, then bootstraps into the target agent in the same conversation |
| `devops {request}` or `@devops {request}` | `agents/devops/SKILL.md` | Bootstrap directly as DevOps — generates/applies Terraform for any infrastructure change, anywhere in `terraform/*`. Safe to address directly, skipping the coordinator, when the request is obviously a change. Also the agent SRE hands fixes off to — DevOps is the only agent that writes/applies Terraform |
| `sre {request}` or `@sre {request}` | `agents/sre/SKILL.md` | Bootstrap directly as SRE — diagnoses infrastructure problems and states root cause, then hands off to DevOps to implement the fix. SRE never applies Terraform itself. Safe to address directly when the request is obviously an incident |

Each agent's folder (`agents/{name}/`) also has its own `runbooks/`
(operational reference material, empty for now — filled in as real usage
happens) and `session.md` (placeholder, not yet wired into any procedure —
intended for cross-session continuity once there's enough real usage to
know what's worth logging there).

Task records live in `agents/{coordinator,devops,sre}/tasks/{planned,in-progress,done}/`
— a plain filesystem convention, not a Claude Code feature. The real
guardrail (Checker hook + interactive approval Gate in `.claude/settings.json`)
is unaffected by any of this — it fires on `terraform apply` regardless of
which agent mode the session is in. A second, equally real checkpoint now
sits in front of it: DevOps pushes changes on a branch and opens a PR
before ever touching `plan`/`apply` — merging is either done by a human
directly on GitHub, or by DevOps itself via `gh pr merge`, which is
deliberately left off the allowed-commands list so it always prompts for
approval, the same way `terraform apply` does.

**Handover note:** since this mechanism depends on `CLAUDE.md` being
loaded (that's the only way Claude Code learns what `devops` means as a
trigger word), the Phase 7 packaging plan of excluding `CLAUDE.md` from
the client handover needs revisiting — split this file's operational
agent-trigger content from the engagement-only content (client name, rate,
deadline, IP notes) before shipping, so the reference implementation
actually works out of the box for Olga.

## Progress Tracking

See `PROGRESS.md` — read it fresh at the start of every session in this folder, update
it at the end. This file rarely changes once the brief is settled; `PROGRESS.md` is
where session-to-session state actually lives.
