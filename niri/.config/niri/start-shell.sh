#!/bin/sh
# Picks which desktop shell niri brings up at startup (called from autostart.kdl).
#
# Noctalia is the default. The "Niri (DankMaterialShell)" greeter session runs
# /usr/local/bin/niri-dms-session, which drops a one-shot marker in
# XDG_RUNTIME_DIR (tmpfs, gone on logout); this script reads and clears it.
# An env var would be simpler but does not reliably survive niri-session's
# login-shell re-exec and the systemd --user unit boundary; the marker does.

marker="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/niri-shell.dms"

if [ -e "$marker" ]; then
    rm -f "$marker"
    exec dms run
fi

exec noctalia
