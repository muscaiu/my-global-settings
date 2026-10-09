---
name: hermes-herdr-orchestrator
description: "Use when Hermes orchestrator mode is active. Use Herdr."
version: 1.0.0
metadata:
  hermes:
    tags: [hermes, herdr, orchestrator, cursor, claude, opencode, coding]
---

# Hermes Herdr Orchestrator

Coordinate external coding agents that cannot run as native Hermes subagents. Keep Hermes in the coordinator pane and use the agents already visible in sibling Herdr panes.

## Preconditions

1. Verify `HERDR_ENV=1`. If it is not, explain that visible orchestration requires launching Hermes inside Herdr; do not control an unrelated Herdr session.
2. Read the live layout for every new user task:
   `herdr pane layout --pane "$HERDR_PANE_ID"`
3. Use only pane IDs returned by that live layout. Never reuse stale IDs from an earlier turn.

## Role assignment

Assign sibling panes by horizontal position, excluding the Hermes coordinator pane:

- Two or more siblings: leftmost sibling is developer; next sibling is reviewer; ignore extras.
- One sibling: it is developer; Hermes performs independent review.
- No siblings: Hermes performs implementation and review itself and states briefly that no external worker pane was available.

Use whichever agent and model are already running. Never replace, restart, reconfigure, split, resize, move, or close panes. The user owns the visible layout.

## Workflow

1. Inspect repository status and relevant files before delegation.
2. Send the developer a bounded prompt containing the outcome, acceptance criteria, relevant paths, project constraints, allowed scope, and required checks.
3. Submit and wait with:
   `herdr agent prompt <pane-id> "<task>" --wait --timeout 300000`
4. If blocked or unclear, inspect with:
   `herdr agent get <pane-id>`
   `herdr agent read <pane-id> --source recent-unwrapped --lines 200`
5. Inspect the actual diff and run or confirm focused tests yourself. Do not accept the developer's report as verification.
6. When a reviewer pane exists, send it a read-only review request covering the completed diff, correctness, regressions, missing tests, security, and repository conventions. Ask for actionable findings with severity and file/line references.
7. Validate review findings yourself. Relay valid fixes to the developer and repeat until clean or explicitly stopped.
8. Give the user a short final report: changes, verification, review result, and anything left.

## Safety

- Preserve unrelated changes.
- Do not read or transmit secrets or credential files.
- Do not approve destructive actions, publishing, commits, pushes, deployments, or broad unrelated edits without explicit user authorization.
- Native `delegate_task` may still be used for small internal research, but external implementation/review should remain in visible Herdr panes while this mode is active.
