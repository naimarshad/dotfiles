#!/usr/bin/env bash
# Place the main workspaces on the primary monitor for the current location.
#   Home   → HDMI-A-1     Office → DP-5     Fallback → eDP-1
#
# The config already pins these workspaces to HDMI-A-1 (open-on-output), which
# makes niri auto-return them when you dock back home. This script only handles
# the OFFICE case, where HDMI-A-1 is absent and the workspaces would otherwise
# fall back onto the laptop panel instead of the big DP-5 ultrawide.
#
# Log: ~/.cache/workspace-location.log

LOG="${XDG_CACHE_HOME:-$HOME/.cache}/workspace-location.log"
log() { echo "[$(date '+%H:%M:%S')] $*" >> "$LOG"; }

MAIN_WS=(work web code personal files media misc misc2)

# Wait for outputs to settle — an external can take a moment to appear after dock.
outputs=""
for _ in $(seq 1 20); do
    outputs=$(niri msg --json outputs 2>>"$LOG")
    [ -n "$outputs" ] && break
    sleep 0.5
done

log "script start"
log "outputs seen: $(printf '%s' "$outputs" | grep -oE '"(HDMI-A-1|DP-5|eDP-1)"' | tr '\n' ' ')"

has() { printf '%s' "$outputs" | grep -q "\"$1\""; }

if has "HDMI-A-1"; then
    primary="HDMI-A-1"
elif has "DP-5"; then
    primary="DP-5"
else
    primary="eDP-1"
fi
log "chosen primary: $primary"

# At home the open-on-output pin already places everything correctly.
if [ "$primary" = "HDMI-A-1" ]; then
    log "home layout — nothing to do"
    exit 0
fi

for ws in "${MAIN_WS[@]}"; do
    out=$(niri msg action focus-workspace "$ws" 2>&1); rc=$?
    log "focus-workspace $ws → rc=$rc ${out:+| $out}"
    out=$(niri msg action move-workspace-to-monitor "$primary" 2>&1); rc=$?
    log "move-workspace-to-monitor $primary (ws=$ws) → rc=$rc ${out:+| $out}"
done

# Land on the work workspace when done.
niri msg action focus-workspace work >/dev/null 2>&1
log "done"
