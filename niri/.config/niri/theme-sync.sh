#!/usr/bin/env bash
# Follow Noctalia's theme mode (Auto = sunrise/sunset) in the tools it has no
# template for: tmux, k9s, kubecolor and fzf. Each has a committed light and dark
# file; this flips a gitignored relative symlink next to them. The mode is read
# from the Ghostty render's background, so everything matches what Noctalia
# actually rendered. Also rebuilds bat's theme cache and sets the freedesktop
# color-scheme that GTK4/libadwaita, Electron and browsers read.
#
# Triggered by theme-sync.path when the render changes, and once at login with
# --now from autostart.kdl.
set -u

exec >>"$HOME/.cache/theme-sync.log" 2>&1
log() { echo "$(date -Is) $*"; }

render="$HOME/.config/ghostty/themes/noctalia"

# Noctalia writes its templates one after another; let the rest land (bat's
# tmTheme in particular) before acting on the first one.
[ "${1:-}" = "--now" ] || sleep 2

bg=$(sed -n 's/^background *= *#\([0-9a-fA-F]\{6\}\).*/\1/p' "$render" 2>/dev/null | head -n1)
if [ -z "$bg" ]; then
	log "no background line in $render"
	exit 1
fi
r=$((16#${bg:0:2})) g=$((16#${bg:2:2})) b=$((16#${bg:4:2}))
if ((299 * r + 587 * g + 114 * b < 128000)); then mode=dark; else mode=light; fi
log "background #$bg -> $mode"

# flip <dir> <link> <target>: skipped with a log line when the package that
# provides <target> has not been stowed.
flip() {
	if [ -e "$1/$3" ]; then
		ln -sfn "$3" "$1/$2"
	else
		log "skip $1/$2: $3 missing (package not stowed?)"
	fi
}

flip "$HOME/.config/tmux" palette.conf "palettes/gruvbox-$mode.conf"
flip "$HOME/.config/k9s/skins" gruvbox-auto.yaml "gruvbox-$mode.yaml"
flip "$HOME/.kube" color.yaml "color-$mode.yaml"
flip "$HOME/.config/fzf" colors "gruvbox-$mode"

# A running tmux server keeps the -F styles it expanded at startup.
if tmux info >/dev/null 2>&1; then
	tmux source-file "$HOME/.config/tmux/theme.conf" || log "tmux re-source failed"
fi

if command -v bat >/dev/null; then
	bat cache --build >/dev/null || log "bat cache --build failed"
fi

if command -v gsettings >/dev/null; then
	gsettings set org.gnome.desktop.interface color-scheme "prefer-$mode" ||
		log "gsettings color-scheme failed"
fi
