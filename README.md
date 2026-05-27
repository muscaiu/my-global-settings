# Terminal Settings

Backup of Ghostty and tmux settings.

## Contents

- `home/.config/ghostty/` - Ghostty config and shaders
- `home/.tmux.conf` - tmux config
- `home/.config/tmux/` - tmux support files and plugins

## Restore

From this repository root on a new machine:

```sh
cp home/.tmux.conf ~/
mkdir -p ~/.config
cp -R home/.config/ghostty ~/.config/
cp -R home/.config/tmux ~/.config/
```

If tmux plugins need updating later, reinstall or update them from their upstream repositories.
