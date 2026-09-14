Toggle orchestrator mode for the current project. `$ARGUMENTS`: `on`, `off`, or `status` (empty = `on`).

## on / off / status — run the matching action, then stop

```bash
hash=$(printf '%s' "$PWD" | shasum -a 256 | cut -d' ' -f1)
f="$HOME/.claude/orchestrator-state/$hash.json"; mkdir -p "$(dirname "$f")"
```

- **on**: Set `active:true`, save the current pane as `panes.coordinator.pane_id` when `$HERDR_PANE_ID` is available, and report that orchestrator mode is active. Create the file if needed.
- **off**: Set `active:false` and report that orchestrator mode is inactive.
- **status**: Report the existing JSON, or `{"active":false}` when no state file exists.

Do not inspect the layout for these toggle actions. The SessionStart hook re-injects this contract after `/clear`/compact/resume. The statusline badge appears only in the saved coordinator pane.

## Active orchestrator contract

On the first real delegation only, run `herdr pane layout --pane "$HERDR_PANE_ID"` once. Identify sibling panes by horizontal position and retain their IDs. Never create, close, split, resize, restart, respawn, or reconfigure panes or agents.

Assign roles from the existing layout:

- If at least two sibling panes exist, the leftmost sibling is the dev and the next sibling is the reviewer. Ignore additional panes.
- If exactly one sibling exists, it is the dev and the coordinator also acts as the reviewer.
- If no siblings exist, the coordinator performs implementation, verification, and review itself.

Use the agents and models already running in sibling panes. Do not inspect or change their kind or model.

For each task:

1. Delegate implementation to the dev pane when one exists; otherwise implement locally.
2. Resolve blockers and verify the diff, repository status, and focused tests where available.
3. Send the completed diff to the reviewer pane when one exists; otherwise review it locally.
4. Review independently and defect-first with severity and file/line references, plus auth, injection, secrets/data exposure, unsafe file/command/network access, and dependency/config risks.
5. Relay valid findings and repeat until clean or stopped. Report `Security: no findings` when applicable. Critical/high security findings block completion unless the user accepts the risk.

Use existing panes with:

```bash
herdr agent prompt <pane-id> "<task>" --wait --until idle --until done --until blocked --timeout 300000
herdr agent read <pane-id> --lines 200
```

Never read `credentials.json`. Preserve unrelated changes and never approve destructive actions, secrets, publishing, commits, or pushes without explicit user authorization.
