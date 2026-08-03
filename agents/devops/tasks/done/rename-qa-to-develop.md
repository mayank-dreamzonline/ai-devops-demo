# rename-qa-to-develop

**Request:** Rename the CI/CD demo's integration branch from `QA` to
`develop` throughout code/docs, and rename the actual git branch + GitHub
ruleset/environment branch policies to match (Mayank, in-conversation
request — clearer naming, no relation to the repo's own `main` trunk).

**Done:** branch `QA` deleted, `develop` created from `main`. Ruleset
retargeted to `develop` + fixed required_approving_review_count 0→1 (was
silently non-functional). `staging`/`prod` environments: required reviewer
(mayank-dreamzonline) set via API on both after the UI picker failed to
persist it twice; branch policies both point at `develop`. Still open:
"allow administrators to bypass" needs unchecking on both environments
(UI checkbox, not exposed via the environments API).
