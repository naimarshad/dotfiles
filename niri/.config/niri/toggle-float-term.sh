#!/usr/bin/env bash
# Toggle the floating tmux terminal: close it if it is focused, else open it.
# Closing only drops the tmux client, so the "float" session survives.
app_id="com.naeem.float"

focused=$(niri msg --json focused-window | jq -r '.app_id // empty')

if [ "$focused" = "$app_id" ]; then
    niri msg action close-window
else
    exec ghostty --class="$app_id" -e tmux new-session -A -s float
fi
