# branch-protection-ruleset-main

**Request:** Add the branch-protection ruleset on `main` (Mayank,
in-conversation request), per `inbox/requirement_pipeline.md` Section 5
item 2.

Scope: a ruleset targeting `refs/heads/main` with a `pull_request` rule
(`required_approving_review_count: 0` — requires a PR to exist, no
reviewer needed), no bypass actors. `required_status_checks` is
deliberately deferred to a follow-up edit once the pipeline has run at
least once and check names are selectable.

This is a repo-settings change via the GitHub API, not Terraform or
code — no branch/PR needed for this piece.

**Outcome:** Created via `POST /repos/:owner/:repo/rulesets` (ruleset id
`20360917`, name `main-branch-protection`, target `refs/heads/main`,
`pull_request` rule with `required_approving_review_count: 0`, no bypass
actors — `current_user_can_bypass: "never"`). Verified live: 1 ruleset
present, and `GET /repos/:owner/:repo/branches/main` now reports
`"protected": true`, which also un-blocks the `staging` environment's
"protected branches" deployment policy that depended on this. No PR
needed — pure repo-settings change via `gh api`.

`required_status_checks` intentionally not added yet — deferred until
after the pipeline runs once and check names become selectable.
