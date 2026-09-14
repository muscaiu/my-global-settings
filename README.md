# My Global Settings

Backup of this Mac's global dev environment settings: Ghostty, Herdr, tmux, opencode, and Claude Code.

## Contents

- `home/.config/ghostty/` - Ghostty config and shaders
- `home/.config/herdr/` - Herdr theme, UI, history, keybindings, and plugin registration
- `home/.config/opencode/` - Global opencode config, custom agents, and notifier plugin setup
- `home/.claude/` - Claude Code global settings, orchestrator mode command/hooks/statusline
- `home/.tmux.conf` - tmux config
- `home/.zshrc` - zsh, oh-my-zsh, Powerlevel10k, and autocomplete setup
- `projects/` - reusable, named project profiles for agent guidance and workflows

## Project Profiles

Project-specific AI instructions live under `projects/<project>/`. Keep product names, repository paths, release checks, deployment targets, and platform IDs inside that project's profile rather than making them global defaults.

For example, ask an agent:

```text
Use the Spend project profile from muscaiu/my-global-settings, especially
projects/spend/RELEASE.md, as the release strategy for this repository.
Adapt repository-specific paths and identifiers; do not copy them blindly.
```

Each profile should contain `AGENTS.md`, the workflow documents it references, and thin command prompts under `commands/`. Add another sibling directory when a project needs different rules.

## Apply On A New Machine

From this repository root on a new machine:

```sh
mkdir -p ~/.config
cp -R home/.config/ghostty ~/.config/
cp -R home/.config/herdr ~/.config/
cp -R home/.config/opencode ~/.config/
cp -R home/.claude/commands ~/.claude/
cp -R home/.claude/hooks ~/.claude/
cp -R home/.claude/scripts ~/.claude/
cp home/.claude/settings.json ~/.claude/
cp home/.tmux.conf ~/
cp home/.zshrc ~/
```

If `~/.claude/settings.json` already exists, merge it manually instead of overwriting it. Preserve any existing hooks, permissions, or other settings the new machine already has.

`home/.config/herdr/plugins.json` contains `manifest_path`/`plugin_root` entries that are absolute paths under this machine's home directory (e.g. `resume-globally` under `~/Applications/plugins/`). On a new machine, either adjust those paths to match the new username/layout or reinstall the plugin there and let Herdr regenerate its own entry.

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

The config sources Catppuccin's `.conf` files directly instead of using `run ~/.config/tmux/plugins/catppuccin/tmux/catppuccin.tmux`. This avoids tmux server PATH issues where the plugin script cannot find the Homebrew `tmux` binary.

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

Ghostty intentionally starts a normal shell. Start tmux manually when wanted:

```sh
tmux new-session -A -s main
```

The Ghostty config keeps only terminal-specific behavior, such as the tmux prefix key helper:

```ini
keybind = super+k=text:\x00
```

AI maintenance notes:

- Do not add a Ghostty `command = tmux ...` auto-start line unless the user explicitly asks for that behavior again.
- Keep tmux theme and behavior in `.tmux.conf`, not in Ghostty config.
- To enter the preferred tmux session manually, use `tmux new-session -A -s main`.

## Herdr

After copying `home/.config/herdr` to `~/.config/herdr`, reload a running Herdr server:

```sh
herdr server reload-config
```

The Herdr config uses the Dracula theme, persists pane history, and uses these keybindings:

- `Ctrl+Space` enters prefix mode.
- `Command+B` toggles the sidebar directly.

## Claude Code

`home/.claude/settings.json` sets:

- `permissions.defaultMode = "bypassPermissions"` and `skipDangerousModePermissionPrompt = true` - Claude Code runs tool calls without an approval prompt on this machine
- A `SessionStart` hook chain (`herdr-agent-state.sh session`, then `orchestrator-session-start.sh`)
- A `statusLine` command (`orchestrator-statusline.sh`) that shows model/dir info plus an orchestrator badge
- `spinnerVerbs`, `autoUpdatesChannel`, `tui`, `theme`, `shiftEnterKeyBindingInstalled` cosmetic/behavior tweaks

`~/.claude/settings.local.json` (allows `Bash(ssh:*)` on this machine) is intentionally not tracked — it's excluded by this machine's global gitignore (`**/.claude/settings.local.json`) since it's meant to stay local, not synced.

### Orchestrator mode

`home/.claude/commands/orchestrator.md` implements the `/orchestrator on|off|status` command. It toggles a per-project state file at `~/.claude/orchestrator-state/<sha256(cwd)>.json` and, once active, delegates implementation/review to existing sibling Herdr panes (leftmost sibling = dev, next = reviewer) without ever creating, closing, or reconfiguring panes or agents.

- `home/.claude/hooks/orchestrator-session-start.sh` - re-injects the orchestrator contract as SessionStart context after `/clear`/compact/resume for a project where orchestrator mode is active; clears the `active` flag on a genuine cold "startup" instead of resurrecting it
- `home/.claude/scripts/orchestrator-statusline.sh` - draws the `🎭 ORCHESTRATOR (dev:x review:y)` statusline badge, but only in the saved coordinator pane

Not backed up: `home/.claude/hooks/herdr-agent-state.sh` (and its opencode counterpart) — these are installed and overwritten by Herdr's own integration on setup, not hand-authored config.

On a new machine, orchestrator mode still needs Herdr running with `HERDR_ENV`, `HERDR_SOCKET_PATH`, and `HERDR_PANE_ID` set in the pane for pane adoption/delegation to work; the command/hooks/statusline alone don't require it just to toggle on/off/status.

## opencode Custom Agents

`home/.config/opencode/agents/` holds custom agent definitions used with opencode:

- `orchestrator.md` - primary agent that delegates implementation/review across existing Herdr panes without creating, closing, or reconfiguring them
- `sysadmin.md` - subagent for shell/service/network/server diagnostics with a safety-first, smallest-safe-change approach
- `local-qwen.md` - agent that runs `lmstudio/qwen3.6-35b-a3b-mlx` through LM Studio for implementation and debugging

Start opencode in orchestrator mode with the `opencode --agents` shell function defined in `.zshrc` (runs `opencode --agent orchestrator`).

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
