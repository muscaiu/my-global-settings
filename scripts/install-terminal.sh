#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
install_dependencies=true
case "${1:-}" in
  --config-only) install_dependencies=false ;;
  '') ;;
  *) printf 'Usage: %s [--config-only]\n' "$0" >&2; exit 1 ;;
esac

if "$install_dependencies"; then
  if ! command -v brew >/dev/null 2>&1; then
    printf '%s\n' 'Install Homebrew from https://brew.sh, then rerun this installer.' >&2
    exit 1
  fi
  brew install zsh-autosuggestions fzf-tab starship font-meslo-lg-nerd-font
  if [ ! -e "$HOME/.oh-my-zsh" ]; then
    git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh"
  fi
  if [ ! -e "$HOME/powerlevel10k" ]; then
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$HOME/powerlevel10k"
  fi
  test -r "$HOME/.oh-my-zsh/oh-my-zsh.sh"
  test -r "$HOME/powerlevel10k/powerlevel10k.zsh-theme"
fi

backup_dir=$(mktemp -d "$HOME/terminal-settings-backup.XXXXXX")
for config_file in .zshrc .zprofile .p10k.zsh; do
  if [ -e "$HOME/$config_file" ]; then
    cp -p "$HOME/$config_file" "$backup_dir/$config_file"
  fi
done
if [ -e "$HOME/.config/starship.toml" ]; then
  cp -p "$HOME/.config/starship.toml" "$backup_dir/starship.toml"
fi
mkdir -p "$HOME/.config"
for config_file in .zshrc .zprofile .p10k.zsh; do
  cp "$repo_root/home/$config_file" "$HOME/$config_file"
done
cp "$repo_root/home/.config/starship.toml" "$HOME/.config/starship.toml"
printf 'Previous shell settings backed up to: %s\n' "$backup_dir"
printf '%s\n' 'Shell settings installed. Open a new Terminal window.'
printf '%s\n' 'Import terminal/Homebrew.terminal in Terminal Settings > Profiles, then choose it as Default.'
printf '%s\n' 'If prompt symbols look wrong, select MesloLGS Nerd Font in that profile.'
