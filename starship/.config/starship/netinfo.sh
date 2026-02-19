#!/usr/bin/env bash
set -euo pipefail

# Public IP (fast-ish; still a network call)
IP="$(timeout 0.5 curl -s https://api.ipify.org || true)"

# Battery (Linux: upower; fallback: /sys)
BAT="$(upower -i "$(upower -e | grep -E 'BAT' | head -n1)" 2>/dev/null | awk -F': *' '/percentage/ {print $2}' | head -n1 || true)"
if [[ -z "${BAT}" && -d /sys/class/power_supply/BAT0 ]]; then
  BAT="$(cat /sys/class/power_supply/BAT0/capacity 2>/dev/null || true)%"
fi

IFACE="$(iw dev 2>/dev/null | awk '$1=="Interface"{print $2}' | head -n1 || true)"

SPEED=""
if [[ -n "$IFACE" ]]; then
  SPEED="$(iw dev "$IFACE" link 2>/dev/null |
    awk -F': ' 'tolower($1) ~ /tx bitrate|bitrate|bit rate/ {print $2; exit}' |
    awk '{print $1" "$2}' || true)"
fi

[[ -n "$SPEED" ]] && SPEED=" $SPEED" || SPEED=" N/A"

# Render line
# Example output: " 134.101.188.252  351.0 MBit/s 96%󰁹"
printf "   %s %s %s󰁹\n" "${IP:-?}" "${SPEED:- ?}" "${BAT:-?}"
