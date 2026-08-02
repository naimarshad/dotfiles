#!/bin/sh
# Network status for the tmux status line.
#
#   net.sh icon   nerd-font glyph for the active connection
#   net.sh text   SSID + signal strength, wired device name, or "offline"
#
# `nmcli connection show --active` is ~15ms; `nmcli device wifi` is ~1.4s
# because it waits on a scan, so signal strength comes from /proc/net/wireless
# (link quality out of 70) instead.

active=$(nmcli -t -f TYPE,NAME,DEVICE connection show --active 2>/dev/null)

wifi=$(printf '%s\n' "$active" | grep -m1 '^802-11-wireless:')
wired=$(printf '%s\n' "$active" | grep -m1 '^802-3-ethernet:')

# Link quality for an interface, as a percentage.
signal_pct() {
	awk -v dev="$1:" '$1 == dev { q = $3; sub(/\.$/, "", q); printf "%d", (q * 100) / 70; exit }' \
		/proc/net/wireless 2>/dev/null
}

case "$1" in
icon)
	if [ -n "$wifi" ]; then
		pct=$(signal_pct "${wifi##*:}")
		[ -n "$pct" ] || pct=0
		if [ "$pct" -ge 75 ]; then
			printf '󰤨 '
		elif [ "$pct" -ge 50 ]; then
			printf '󰤥 '
		elif [ "$pct" -ge 25 ]; then
			printf '󰤢 '
		else
			printf '󰤟 '
		fi
	elif [ -n "$wired" ]; then
		printf '󰈀 '
	else
		printf '󰤭 '
	fi
	;;
text)
	if [ -n "$wifi" ]; then
		ssid=${wifi#*:}
		dev=${ssid#*:}
		ssid=${ssid%%:*}
		pct=$(signal_pct "$dev")
		if [ -n "$pct" ]; then
			printf '%s %s%%' "$ssid" "$pct"
		else
			printf '%s' "$ssid"
		fi
	elif [ -n "$wired" ]; then
		printf '%s' "${wired##*:}"
	else
		printf '#[fg=%s]offline' "$(tmux show -gqv @thm_red)"
	fi
	;;
esac
