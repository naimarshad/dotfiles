#!/usr/bin/env bash
# Place the main workspaces on the primary monitor for the current location.
#   Home   → HDMI-A-1     Office → the P34w-20, whichever connector it lands on
#
# The config already pins these workspaces to HDMI-A-1 (open-on-output), which
# makes niri auto-return them when you dock back home. This script only handles
# the OFFICE case, where HDMI-A-1 is absent and the workspaces would otherwise
# fall back onto the laptop panel instead of the big ultrawide.
#
# The office monitor is matched by model, not by connector: the dock enumerates
# it as DP-3 or DP-5 depending on port and MST branch, and an earlier version of
# this script hardcoded DP-5 and silently dumped everything onto eDP-1 instead.
#
# Log: ~/.cache/workspace-location.log

LOG="${XDG_CACHE_HOME:-$HOME/.cache}/workspace-location.log"
log() { echo "[$(date '+%H:%M:%S')] $*" >> "$LOG"; }

# social is included so Slack follows the ultrawide at the office; its
# open-on-output pin is DP-1, which only exists at home.
MAIN_WS=(work web code personal files media misc misc2 social)

# Model string of the office ultrawide, from: niri msg --json outputs
OFFICE_MODEL="P34w-20"

# Wait for outputs to settle — an external can take a moment to appear after dock.
outputs=""
for _ in $(seq 1 20); do
    outputs=$(niri msg --json outputs 2>>"$LOG")
    [ -n "$outputs" ] && break
    sleep 0.5
done

log "script start"

if [ -z "$outputs" ]; then
    log "ERROR: niri msg --json outputs returned nothing after 10s, giving up"
    exit 1
fi

# Log every connector actually present, not just the ones this script knows about.
log "outputs seen: $(printf '%s' "$outputs" | jq -r 'keys | join(" ")')"

has() { printf '%s' "$outputs" | jq -e --arg n "$1" 'has($n)' >/dev/null; }

# Resolve the connector currently carrying a given monitor model.
connector_for_model() {
    printf '%s' "$outputs" | jq -r --arg m "$1" \
        'to_entries[] | select(.value.model == $m) | .key' | head -n1
}

# At home the open-on-output pin already places everything correctly.
if has "HDMI-A-1"; then
    log "home layout — open-on-output already places everything, nothing to do"
    exit 0
fi

primary=$(connector_for_model "$OFFICE_MODEL")
if [ -z "$primary" ]; then
    log "ERROR: no HDMI-A-1 and no $OFFICE_MODEL found — leaving workspaces alone"
    exit 1
fi
log "office layout — primary: $primary ($OFFICE_MODEL)"

for ws in "${MAIN_WS[@]}"; do
    out=$(niri msg action focus-workspace "$ws" 2>&1); rc=$?
    log "focus-workspace $ws → rc=$rc ${out:+| $out}"
    out=$(niri msg action move-workspace-to-monitor "$primary" 2>&1); rc=$?
    log "move-workspace-to-monitor $primary (ws=$ws) → rc=$rc ${out:+| $out}"
done

# Land on the work workspace when done.
niri msg action focus-workspace work >/dev/null 2>&1
log "done"
