#!/bin/sh
# Routes a desktop-shell action to whichever shell is running: Noctalia in the
# "Niri" session, DankMaterialShell in the "Niri (DankMaterialShell)" session.
# binds.kdl calls this so one keymap works in both (see start-shell.sh).
#
# Usage: shell.sh <action>
#   launcher clipboard settings control calendar media session lock dnd
#   emoji windows

action="$1"

if pgrep -x noctalia >/dev/null 2>&1; then
    case "$action" in
        launcher)  exec noctalia msg panel-toggle launcher ;;
        emoji)     exec noctalia msg panel-toggle launcher /emo ;;
        windows)   exec noctalia msg window-switcher ;;
        clipboard) exec noctalia msg panel-toggle clipboard ;;
        settings)  exec noctalia msg settings-toggle ;;
        calendar)  exec noctalia msg panel-toggle control-center calendar ;;
        control)   exec noctalia msg panel-toggle control-center ;;
        media)     exec noctalia msg panel-toggle control-center media ;;
        session)   exec noctalia msg panel-toggle session ;;
        lock)      exec noctalia msg session lock ;;
        dnd)       exec noctalia msg notification-dnd-toggle ;;
    esac
elif pgrep -x dms >/dev/null 2>&1; then
    case "$action" in
        launcher)  exec dms ipc call spotlight toggle ;;
        emoji)     exec dms ipc call spotlight toggle ;;
        windows)   exec niri msg action toggle-overview ;;
        clipboard) exec dms ipc call clipboard toggle ;;
        settings)  exec dms ipc call settings toggle ;;
        calendar)  exec dms ipc call control-center toggle ;;
        control)   exec dms ipc call control-center toggle ;;
        media)     exec dms ipc call control-center toggle ;;
        session)   exec dms ipc call powermenu toggle ;;
        lock)      exec dms ipc call lock lock ;;
        dnd)       exec dms ipc call notifications toggleDoNotDisturb ;;
    esac
fi
