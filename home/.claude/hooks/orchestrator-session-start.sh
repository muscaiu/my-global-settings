#!/bin/sh
# Re-injects the /orchestrator delegation contract at the start of a session
# (resume, clear, compact) for a project where orchestrator mode is active.
# Without this, orchestrator mode's instructions only lived as conversation
# text and were silently lost on /clear even though the statusline badge
# (which reads state independently) kept showing active.
#
# Deliberately does NOT re-arm on a brand-new session ("startup"): orchestrator
# mode must be turned on explicitly with /orchestrator each time you start
# fresh, rather than auto-resurrecting from whatever a previous session left
# on disk. A "startup" source clears the persisted active flag so the
# statusline badge and this hook agree it's off.
set -eu

command -v jq >/dev/null 2>&1 || exit 0

input="$(cat)"
cwd="$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null || printf '')"
[ -n "$cwd" ] || exit 0

source_field="$(printf '%s' "$input" | jq -r '.source // empty' 2>/dev/null || printf '')"

hash="$(printf '%s' "$cwd" | shasum -a 256 | cut -d' ' -f1)"
state_file="$HOME/.claude/orchestrator-state/$hash.json"
[ -f "$state_file" ] || exit 0

if [ "$source_field" = "startup" ]; then
  tmp_file="$(mktemp "${TMPDIR:-/tmp}/orchestrator-state.XXXXXX")"
  jq '.active = false' "$state_file" >"$tmp_file" && mv "$tmp_file" "$state_file"
  exit 0
fi

active="$(jq -r '.active // false' "$state_file" 2>/dev/null || printf 'false')"
[ "$active" = "true" ] || exit 0

ctx="Orchestrator ACTIVE (restored after /clear/compact; 🎭 ORCHESTRATOR). On the first real task, inspect the current Herdr layout once and use existing sibling panes only. Never create, close, split, resize, restart, respawn, or reconfigure panes or agents. If at least two siblings exist, use the leftmost as dev and the next as reviewer; ignore additional panes. If one sibling exists, use it as dev and review locally. If none exist, implement, verify, and review locally. Verify the diff/status and focused checks. Review defect-first plus auth, injection, secrets/data exposure, unsafe file/command/network access, and dependency/config risks. Report actionable findings with severity/file:line, or Security: no findings. Turn off with /orchestrator off."

jq -n --arg ctx "$ctx" '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":$ctx}}'
