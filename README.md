# Terminal Settings

Backup of Ghostty, tmux, and opencode terminal-adjacent settings.

## Contents

- `home/.config/ghostty/` - Ghostty config and shaders
- `home/.config/opencode/` - Global opencode config, including notifier plugin setup
- `home/.tmux.conf` - tmux config
- `home/.zshrc` - zsh, oh-my-zsh, Powerlevel10k, and autocomplete setup

## Apply On A New Machine

From this repository root on a new machine:

```sh
mkdir -p ~/.config
cp -R home/.config/ghostty ~/.config/
cp -R home/.config/opencode ~/.config/
cp home/.tmux.conf ~/
cp home/.zshrc ~/
```

If `~/.config/opencode/opencode.json` already exists, merge it manually instead of overwriting it. Preserve existing providers, agents, permissions, and MCP servers, then add the notifier plugin entry if missing.

If `~/.zshrc` already exists, merge it manually instead of overwriting it. Preserve local PATH entries, language/runtime managers, aliases, and machine-specific CLI setup.

## zsh Autocomplete

The zsh config keeps the existing Ghostty -> tmux -> zsh stack and adds lightweight autocomplete without switching shells.

Install dependencies on a new machine:

```sh
brew install zsh-autosuggestions fzf-tab
```

Required `~/.zshrc` lines, loaded after `source $ZSH/oh-my-zsh.sh`:

```zsh
# Autocomplete enhancements for zsh/tmux/Ghostty.
source /opt/homebrew/opt/fzf-tab/share/fzf-tab/fzf-tab.zsh
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
```

Behavior:

- `zsh-autosuggestions` shows gray inline suggestions from shell history.
- `fzf-tab` replaces plain tab completion with an interactive fuzzy completion menu.

After applying changes, reload zsh or restart tmux:

```sh
source ~/.zshrc
tmux kill-server
```

AI maintenance notes:

- Keep the autocomplete source lines after oh-my-zsh loads.
- Do not replace an existing `~/.zshrc` blindly on another machine; merge the autocomplete block and Homebrew PATH setup only if needed.
- On Apple Silicon Homebrew, the paths above use `/opt/homebrew`. On Intel Homebrew, adjust paths to `/usr/local` or prefer `$(brew --prefix)` when editing manually.

## tmux Plugin

The tmux config uses the Catppuccin theme from this path:

```sh
~/.config/tmux/plugins/catppuccin/tmux/catppuccin.tmux
```

Install it on the new machine with:

```sh
mkdir -p ~/.config/tmux/plugins/catppuccin
git clone https://github.com/catppuccin/tmux ~/.config/tmux/plugins/catppuccin/tmux
```

Then reload tmux:

```sh
tmux source-file ~/.tmux.conf
```

Or fully restart tmux if it is already running.

## Ghostty

After copying `home/.config/ghostty` to `~/.config/ghostty`, restart Ghostty so it loads the config.

Ghostty is configured to start or attach to the main tmux session automatically:

```ini
command = /opt/homebrew/bin/tmux new-session -A -s main
```

This uses the Apple Silicon Homebrew tmux path. On another machine, verify the path with:

```sh
which tmux
```

If needed, update the `command` line in `~/.config/ghostty/config` before launching Ghostty. The intended behavior is: opening Ghostty attaches to an existing `main` tmux session, or creates it if it does not exist.

AI maintenance notes:

- Preserve the Ghostty `command` line when restoring terminal settings on a new machine.
- If `tmux` is installed somewhere other than `/opt/homebrew/bin/tmux`, replace only the path and keep `new-session -A -s main`.
- Do not duplicate this behavior in `.zshrc` unless the user explicitly wants every Ghostty shell to force tmux from the shell layer.

## opencode Notifier

The opencode config installs `@mohak34/opencode-notifier@latest` globally. It plays a sound and shows a macOS notification when opencode needs attention or finishes work.

Important files:

- `home/.config/opencode/opencode.json` - registers the opencode plugin and LM Studio provider
- `home/.config/opencode/opencode-notifier.json` - enables sound/notifications for `permission`, `complete`, `question`, `error`, and `plan_exit`

This setup intentionally does not use Ghostty OSC notifications. It relies on the notifier plugin's default macOS notification path, which is simpler and works when opencode is running inside tmux from Ghostty.

After copying these files, restart opencode. opencode loads config and plugins only on startup.

Test prompts inside opencode:

```text
say hello and stop
```

```text
ask me which color I prefer using the question tool
```

AI maintenance notes:

- Do not remove existing `provider`, `agent`, `permission`, `mcp`, or `plugin` entries when restoring on another machine.
- If another `plugin` array already exists, append `@mohak34/opencode-notifier@latest` rather than replacing the array.
- If using Ghostty OSC notifications later, add `"notificationSystem": "ghostty"` to `opencode-notifier.json` and enable tmux passthrough with `set -g allow-passthrough on`.
