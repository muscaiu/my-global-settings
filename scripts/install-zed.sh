#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
source_dir="$repo_root/home/.config/zed"
target_dir="${XDG_CONFIG_HOME:-$HOME/.config}/zed"

if [ -e "$target_dir" ]; then
  backup_dir=$(mktemp -d "${target_dir}.backup.XXXXXX")
  cp -R "$target_dir/." "$backup_dir/"
  printf 'Existing Zed configuration backed up to: %s\n' "$backup_dir"
fi

mkdir -p "$target_dir/themes"
cp "$source_dir/settings.json" "$target_dir/settings.json"
for theme_file in "$source_dir"/themes/*.json; do
  cp "$theme_file" "$target_dir/themes/"
done

printf 'Installed Zed settings and themes in: %s\n' "$target_dir"
printf '%s\n' 'Restart Zed and sign into your AI providers separately.'
