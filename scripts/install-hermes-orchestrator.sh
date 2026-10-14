#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
profile=${1:-}

if [[ $# -gt 1 ]]; then
  printf 'Usage: %s [hermes-profile]\n' "$0" >&2
  exit 2
fi

command -v hermes >/dev/null || {
  printf 'Hermes is not installed.\n' >&2
  exit 1
}

if [[ -n "$profile" ]]; then
  config_path=$(hermes -p "$profile" config path)
else
  config_path=$(hermes config path)
fi
hermes_home=$(dirname "$config_path")
skill_dir="$hermes_home/skills/autonomous-ai-agents/hermes-herdr-orchestrator"
prompt_file="$repo_root/home/.hermes/personalities/orchestrator.txt"

mkdir -p "$skill_dir"
cp "$repo_root/home/.hermes/skills/autonomous-ai-agents/hermes-herdr-orchestrator/SKILL.md" "$skill_dir/SKILL.md"
if [[ -n "$profile" ]]; then
  hermes -p "$profile" config set personalities.orchestrator "$(<"$prompt_file")"
else
  hermes config set personalities.orchestrator "$(<"$prompt_file")"
fi

printf 'Installed Hermes orchestrator personality and Herdr skill into %s\n' "$hermes_home"
printf 'Enable with /personality orchestrator; disable with /personality none.\n'
