#!/usr/bin/env bash
# Installs the /t3-crew and /t3-crew-default skills for every harness that can
# act as a T3 Code orchestrator: Claude Code, Codex, Cursor, and pi.
# Idempotent: re-running overwrites only the two skill folders per harness.
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

# source dir under home/  ->  destination under $HOME
targets=(
  ".claude/skills"
  ".codex/skills"
  ".cursor/skills"
  ".pi/agent/skills"
)

for target in "${targets[@]}"; do
  for skill in t3-crew t3-crew-default; do
    src="$repo_root/home/$target/$skill"
    dest="$HOME/$target/$skill"
    mkdir -p "$dest"
    cp -R "$src/." "$dest/"
    printf 'Installed %s\n' "$dest"
  done
done

printf '\nInvoke with:\n'
printf '  Claude Code  /t3-crew  /t3-crew-default\n'
printf '  Codex        $t3-crew  $t3-crew-default\n'
printf '  Cursor       /t3-crew  /t3-crew-default\n'
printf '  pi           /skill:t3-crew  /skill:t3-crew-default\n'
