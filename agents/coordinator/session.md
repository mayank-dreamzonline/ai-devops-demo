# Coordinator — Session Log

Placeholder for now — not wired into the coordinator's procedure yet. Intended
future use: a running record of what this agent did across sessions (routing
decisions made, status questions answered), so a new session can pick up
context without re-reading all of `tasks/`. Extend this once real usage
patterns make clear what's actually worth logging here versus what
`tasks/{planned,in-progress,done}/` already covers.
