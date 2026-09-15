#!/bin/sh
# Battery status for the tmux status line, read straight from sysfs so it costs
# nothing to poll. Replaces the tmux-battery plugin.
#
# Emits a complete styled segment, or nothing on a machine with no battery.

bat=/sys/class/power_supply/BAT0
[ -d "$bat" ] || exit 0

read -r cap <"$bat/capacity" 2>/dev/null || exit 0
read -r state <"$bat/status" 2>/dev/null || state=Unknown

# "Not charging" is a real ACPI state: on AC but holding at a charge limit.
# Treat it as plugged in rather than draining, or the icon lies.
online=0
[ -r /sys/class/power_supply/AC/online ] && read -r online </sys/class/power_supply/AC/online 2>/dev/null

case "$state" in
Charging) icon='󰂄' ;;
Full) icon='󰚥' ;;
*)
	if [ "$online" = 1 ]; then
		icon='󰚥'
	elif [ "$cap" -ge 90 ]; then icon='󰁹'
	elif [ "$cap" -ge 75 ]; then icon='󰂁'
	elif [ "$cap" -ge 60 ]; then icon='󰁿'
	elif [ "$cap" -ge 45 ]; then icon='󰁽'
	elif [ "$cap" -ge 30 ]; then icon='󰁻'
	elif [ "$cap" -ge 15 ]; then icon='󰁺'
	else icon='󰂃'
	fi
	;;
esac

bg0=$(tmux show -gqv @gb_bg0)

# Low and actually draining: shout. On AC at any level it is not a problem.
if [ "$online" != 1 ] && [ "$state" != "Charging" ] && [ "$state" != "Full" ] && [ "$cap" -le 15 ]; then
	printf '#[fg=%s,bg=%s,bold] %s %s%% #[default]' \
		"$bg0" "$(tmux show -gqv @gb_red)" "$icon" "$cap"
else
	printf '#[fg=%s,bg=%s] %s %s%% #[default]' \
		"$bg0" "$(tmux show -gqv @gb_orange)" "$icon" "$cap"
fi
