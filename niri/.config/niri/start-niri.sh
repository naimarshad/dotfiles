#!/usr/bin/env bash
# Launch niri as a proper D-Bus session so screencasting works.
#
# `niri-session` wraps niri with:
#   - dbus-run-session (or reuses the existing D-Bus session)
#   - registers org.gnome.Mutter.ScreenCast on the bus (required by
#     xdg-desktop-portal-gnome for window + monitor capture)
#
# Plain `niri` skips D-Bus registration → ScreenCast portal can't connect
# → browsers get error 3 (kPortalCancelled) and loop the permission dialog.
#
# Usage: call this from ~/.zprofile (or equivalent) instead of `niri`:
#   if [ -z "$WAYLAND_DISPLAY" ] && [ "$XDG_VTNR" = "1" ]; then
#       exec ~/.config/niri/start-niri.sh
#   fi

export XDG_CURRENT_DESKTOP=niri
export XDG_SESSION_DESKTOP=niri
export XDG_SESSION_TYPE=wayland

exec niri-session
