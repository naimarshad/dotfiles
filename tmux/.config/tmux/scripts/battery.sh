#!/bin/sh
# Battery status for the tmux status line, read straight from sysfs so it costs
# nothing to poll.
#
#   battery.sh icon
#   battery.sh text

bat=/sys/class/power_supply/BAT0
[ -d "$bat" ] || exit 0

read -r cap <"$bat/capacity" 2>/dev/null || exit 0
read -r state <"$bat/status" 2>/dev/null || state=Unknown

case "$1" in
icon)
	case "$state" in
	Charging) printf '󰂄 ' ;;
	Full) printf '󰚥 ' ;;
	*)
		if [ "$cap" -ge 90 ]; then
			printf '󰁹 '
		elif [ "$cap" -ge 75 ]; then
			printf '󰂁 '
		elif [ "$cap" -ge 60 ]; then
			printf '󰁿 '
		elif [ "$cap" -ge 45 ]; then
			printf '󰁽 '
		elif [ "$cap" -ge 30 ]; then
			printf '󰁻 '
		elif [ "$cap" -ge 15 ]; then
			printf '󰁺 '
		else
			printf '󰂃 '
		fi
		;;
	esac
	;;
text)
	if [ "$state" != "Charging" ] && [ "$state" != "Full" ] && [ "$cap" -le 15 ]; then
		printf '#[fg=%s,bold]%s%%' "$(tmux show -gqv @thm_red)" "$cap"
	else
		printf '%s%%' "$cap"
	fi
	;;
esac
