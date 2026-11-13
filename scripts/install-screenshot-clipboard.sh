#!/bin/zsh
# Screenshots -> ~/Documents/Screenshots (iCloud-synced), and every new screenshot is put on
# the clipboard as an image (paste anywhere). Idempotent: safe to re-run.
#
# - Sets the macOS screenshot folder and turns off the floating thumbnail (the thumbnail delays
#   saving the file by ~5s, which delays the clipboard copy).
# - Builds a tiny helper (needs Xcode Command Line Tools: `xcode-select --install`).
#   A dedicated binary is used instead of a shell script because macOS blocks background shell
#   scripts from reading ~/Documents; the helper gets its own narrow permission instead of
#   giving /bin/zsh Full Disk Access.
# - Installs a LaunchAgent that runs the helper whenever the screenshots folder changes.
set -euo pipefail

REPO_DIR="${0:A:h:h}"
SHOTS="$HOME/Documents/Screenshots"
BIN="$HOME/bin/copyshotpath-bin"
LABEL="com.local.screenshot-clipboard"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"

command -v clang >/dev/null || { echo "clang not found: run xcode-select --install"; exit 1; }

mkdir -p "$SHOTS" "$HOME/bin/src" "$HOME/Library/LaunchAgents"
defaults write com.apple.screencapture location "$SHOTS"
defaults write com.apple.screencapture show-thumbnail -bool false
killall SystemUIServer 2>/dev/null || true

cp "$REPO_DIR/home/bin/src/copyshotimage.m" "$HOME/bin/src/copyshotimage.m"
clang -O2 -fobjc-arc -framework AppKit -o "$BIN" "$HOME/bin/src/copyshotimage.m"
codesign -s - -f "$BIN" 2>/dev/null || true

cat > "$PLIST" <<PLIST_EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>$LABEL</string>
  <key>ProgramArguments</key><array><string>$BIN</string></array>
  <key>WatchPaths</key><array><string>$SHOTS</string></array>
  <key>ThrottleInterval</key><integer>1</integer>
</dict></plist>
PLIST_EOF

launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$PLIST"
echo "Installed. Take a screenshot and paste (Cmd+V)."
echo "If macOS asks to let copyshotpath-bin access Documents, click Allow."
echo "Uninstall: launchctl bootout gui/\$(id -u)/$LABEL; rm \"$PLIST\" \"$BIN\""
