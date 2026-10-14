# My Global Settings

Backup of this Mac's global dev environment settings: Ghostty, Herdr, tmux, Hermes, opencode, and Claude Code.

## Contents

- `home/.config/ghostty/` - Ghostty config and shaders
- `home/.config/herdr/` - Herdr theme, UI, history, keybindings, and plugin registration
- `home/.config/opencode/` - Global opencode config, custom agents, and notifier plugin setup
- `home/.hermes/` - Portable Hermes personality prompts and custom skills
- `home/.claude/` - Claude Code global settings, orchestrator mode command/hooks/statusline
- `home/.pi/` - pi coding agent `/orchestrator` extension (orchestrator mode only)
- `home/.config/zed/` - Zed settings and custom themes (secrets and machine-specific entries removed)
- `home/.tmux.conf` - tmux config
- `home/.zshrc` - zsh, oh-my-zsh, Powerlevel10k, and autocomplete setup
- `projects/` - reusable, named project profiles for agent guidance and workflows

## Project Profiles

Project-specific AI instructions live under `projects/<project>/`. Keep product names, repository paths, release checks, deployment targets, and platform IDs inside that project's profile rather than making them global defaults.

Current profiles:

- `projects/spend/` - Costility/Spend, a pnpm monorepo where mobile is an Expo WebView shell around the deployed web app; release includes App Store/Play Store reconciliation against a `MOBILE_RELEASES` registry.
- `projects/memodesk/` - memodesk, a pnpm monorepo where mobile is a separate native Expo app (not a WebView) sharing sync/storage logic with web via `packages/shared`; release skips store reconciliation since there's no App Store Connect/Play Console listing yet.

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
mkdir -p ~/.pi/agent/extensions
cp -n home/.pi/agent/extensions/orchestrator.ts ~/.pi/agent/extensions/
cp home/.tmux.conf ~/
cp home/.zshrc ~/
./scripts/install-hermes-orchestrator.sh
```

If `~/.claude/settings.json` already exists, merge it manually instead of overwriting it. Preserve any existing hooks, permissions, or other settings the new machine already has.

`home/.config/herdr/plugins.json` contains `manifest_path`/`plugin_root` entries that are absolute paths under this machine's home directory (e.g. `resume-globally` under `~/Applications/plugins/`). On a new machine, either adjust those paths to match the new username/layout or reinstall the plugin there and let Herdr regenerate its own entry.

If `~/.config/opencode/opencode.json` already exists, merge it manually instead of overwriting it. Preserve existing providers, agents, permissions, and MCP servers, then add the notifier plugin entry if missing.

If `~/.zshrc` already exists, merge it manually instead of overwriting it. Preserve local PATH entries, language/runtime managers, aliases, and machine-specific CLI setup.

## Zed

Backed up from a macOS machine: `home/.config/zed/settings.json` and `home/.config/zed/themes/`. There is no custom keymap or snippets file, so none is stored.

> **Security warning:** these copied settings permit unsandboxed commands. `agent.sandbox_permissions.allow_unsandboxed` is `true`, and the agent `terminal` tool defaults to `allow` (with `git` commands also always allowed), so the Zed agent can run shell commands without prompting. Review these values before applying, and tighten them on machines or projects you do not fully trust.

Apply on a new machine without overwriting anything (`cp -n` skips existing files):

```sh
mkdir -p ~/.config/zed/themes
cp -n home/.config/zed/themes/*.json ~/.config/zed/themes/
# Only if ~/.config/zed/settings.json does not exist yet:
cp -n home/.config/zed/settings.json ~/.config/zed/settings.json
```

If `~/.config/zed/settings.json` already exists, merge it manually instead of overwriting it. Zed reloads settings automatically.

Not included on purpose, add these per machine:

- `context_servers` GitHub MCP server: its `github_personal_access_token` was removed. Create a new token on the new machine and add the `mcp-server-github` entry through Zed's agent panel settings.
- `ssh_connections`: LAN hosts, usernames, and remote project paths are machine-specific.
- `language_models.openai_compatible` "LM Studio": the `api_url` points to a LAN IP. Re-add with the new machine's LM Studio address.
- `settings_backup.json`, `prompts/` database, extensions, and caches: runtime/machine state.

Per-machine setup that this repo does not provide:

- External agent binaries and auth: `agent_servers` lists `pi-acp`, `opencode`, `codex-acp`, and `claude-acp` as registry agents, which Zed downloads itself, but the tools behind them (opencode, Codex, Claude Code, pi) and their logins or API keys must be installed and signed in on each machine. `agent.default_model` uses the `openai-subscribed` provider, which needs its own sign-in.
- Fonts: no font files are stored here. Zed uses its defaults unless the settings name a font; install any custom font on the new machine.

Extensions installed on the source machine (from `~/Library/Application Support/Zed/extensions/installed`, IDs only):

`catppuccin-icons`, `dockerfile`, `html`, `ktrz-monokai`, `log`, `mcp-server-github`, `monokai-og`, `monokai-pro-ce`

`settings.json` declares them in `auto_install_extensions`, so Zed installs them on first launch. Extension code itself is not stored here. The icon theme "Catppuccin Macchiato" needs `catppuccin-icons`. The files in `themes/` are plain theme files that need no extension; the active dark theme is "One Dark Pro". `mcp-server-github` also needs a new GitHub token (see above).

AI maintenance notes:

- Never copy `~/.config/zed/settings.json` into this repo without removing tokens, API keys, `ssh_connections`, and LAN URLs first.
- Zed settings are JSONC (comments and trailing commas allowed).

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

## Hermes

`scripts/install-hermes-orchestrator.sh` installs a selectable Hermes personality plus the `hermes-herdr-orchestrator` skill without replacing the rest of `~/.hermes/config.yaml`.

```sh
./scripts/install-hermes-orchestrator.sh
```

To install it into a named Hermes profile instead of the default profile:

```sh
./scripts/install-hermes-orchestrator.sh profile-name
```

Inside Hermes, toggle the mode with:

```text
/personality orchestrator
/personality none
```

When active, Hermes stays in the coordinator pane and uses existing visible Herdr sibling panes as developer and reviewer. It does not create, close, resize, restart, or reconfigure panes or their agents.

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

## pi Orchestrator

`home/.pi/agent/extensions/orchestrator.ts` adds a `/orchestrator on|off|status` command to the [pi](https://github.com/earendil-works/pi) coding agent. It is a single-file pi extension, so there is no separate skill: pi loads `~/.pi/agent/extensions/*.ts` on startup, and `/reload` picks up changes in a running session.

What it loads and does:

- Registers the `/orchestrator` command (no argument means `on`).
- Reads and writes the same per-project state file as Claude Code and opencode: `~/.claude/orchestrator-state/<sha256(cwd)>.json`. `/orchestrator status` therefore agrees across all three harnesses.
- While active, on every turn it appends the delegation contract (leftmost sibling Herdr pane = dev, next = reviewer, never create/close/resize panes or agents) plus the live Herdr layout to pi's system prompt, and shows a `🎭 ORCHESTRATOR` badge in the coordinator pane.
- The live layout comes from `home/.claude/scripts/herdr-layout-context.py`, which the extension runs with `python3` at `~/.claude/scripts/herdr-layout-context.py`. It is only invoked when `HERDR_ENV=1`.

Install on a new machine (the generic apply steps above already copy `home/.claude/scripts/`):

```sh
mkdir -p ~/.pi/agent/extensions
cp -n home/.pi/agent/extensions/orchestrator.ts ~/.pi/agent/extensions/
cp -n home/.claude/scripts/herdr-layout-context.py ~/.claude/scripts/
```

Then start pi inside a Herdr pane and run `/orchestrator on`. Dependencies: pi itself, Herdr (`herdr` on `PATH`; `HERDR_ENV`, `HERDR_PANE_ID` set in the pane), `python3`, and a writable `~/.claude/`. The extension only uses Node built-ins and a type-only import, so it needs no `npm install`. The paths use `os.homedir()`, so nothing is machine-specific.

Not backed up on purpose (machine-specific, credentials, or runtime state): `~/.pi/agent/auth.json`, `models.json`, `models-store.json`, `settings.json` (contains a device id, package list, and project trust choices), `trust.json`, `sessions/`, `npm/`, `bin/`, and the other local extensions (`herdr-boss`, `subagent`, `herdr-agent-state`, `compact-via-openai`). Configure provider login and models on each machine with `/login` and `/model`.

Security notes:

- pi extensions run inside the pi process with your full user permissions and pi has no built-in sandbox or per-tool approval. Read `orchestrator.ts` before installing it; it only spawns `python3` on a fixed path (no shell, 5 s timeout, output ignored on failure) and writes the state JSON under `~/.claude/orchestrator-state/`.
- The injected text is the static contract plus pane IDs and agent names/status from Herdr. It does not include pane contents or terminal titles. Delegation goes through `herdr agent prompt`, so each dev/reviewer pane keeps whatever permissions its own agent has.
- The state file is plain JSON keyed by a hash of the project path; anyone who can write it can turn orchestrator mode on or off for that project. `/orchestrator status` prints its contents.
- The author's pi runs with `defaultProjectTrust: "always"`, which loads project `.pi` extensions, skills, and settings without prompting. That is deliberately not copied here. Keep pi's default (`ask`) on machines or folders you do not fully trust.
- The contract tells the coordinator not to read `credentials.json`, commit, push, or approve destructive actions without explicit authorization. It is an instruction to the model, not an enforced boundary.

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
