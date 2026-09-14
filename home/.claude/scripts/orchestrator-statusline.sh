#!/bin/sh
# Claude Code / Cursor statusLine script.
# Shows normal model/dir info, plus a visible badge when orchestrator mode
# (toggled via the /orchestrator command) is active for the current project.
# The badge only appears in the coordinator pane — not dev/review panes.
set -eu

input="$(cat)"

cwd="$(printf '%s' "$input" | jq -r '.workspace.current_dir // .cwd // "."')"
model="$(printf '%s' "$input" | jq -r '.model.display_name // "Claude"')"
dir_name="$(basename "$cwd")"

state_dir="$HOME/.claude/orchestrator-state"
hash="$(printf '%s' "$cwd" | shasum -a 256 | cut -d' ' -f1)"
state_file="$state_dir/$hash.json"

base="\033[2m${model}\033[0m \033[36m${dir_name}\033[0m"

show_orchestrator_badge() {
  [ -f "$state_file" ] || return 1
  [ "$(jq -r '.active // false' "$state_file" 2>/dev/null)" = "true" ] || return 1

  current_pane="${HERDR_PANE_ID:-}"
  if [ -n "$current_pane" ]; then
    dev_pane="$(jq -r '.panes.dev.pane_id // empty' "$state_file" 2>/dev/null)"
    review_pane="$(jq -r '.panes.review.pane_id // empty' "$state_file" 2>/dev/null)"
    coord_pane="$(jq -r '.panes.coordinator.pane_id // empty' "$state_file" 2>/dev/null)"

    # Coordinator match wins — even if stale state duplicated a pane id.
    if [ -n "$coord_pane" ] && [ "$current_pane" = "$coord_pane" ]; then return 0; fi
    if [ -n "$dev_pane" ] && [ "$current_pane" = "$dev_pane" ]; then return 1; fi
    if [ -n "$review_pane" ] && [ "$current_pane" = "$review_pane" ]; then return 1; fi
    if [ -n "$coord_pane" ]; then return 1; fi
    return 0
  fi

  session_id="$(printf '%s' "$input" | jq -r '.session_id // empty')"
  coord_session="$(jq -r '.panes.coordinator.session_id // empty' "$state_file" 2>/dev/null)"
  if [ -n "$coord_session" ] && [ -n "$session_id" ] && [ "$session_id" != "$coord_session" ]; then
    return 1
  fi

  return 0
}

if show_orchestrator_badge; then
  dev="$(jq -r '.roles.dev // "cursor"' "$state_file")"
  reviewer="$(jq -r '.roles.reviewer // "opencode"' "$state_file")"
  printf '%b\n' "\033[1;35m🎭 ORCHESTRATOR\033[0m \033[2m(dev:${dev} review:${reviewer})\033[0m  ${base}"
else
  printf '%b\n' "${base}"
fi
