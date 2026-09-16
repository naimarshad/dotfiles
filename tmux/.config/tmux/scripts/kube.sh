#!/bin/sh
# Current kubernetes context:namespace for the tmux status line.
#
# Usage: kube.sh [pane_tty]
#
# `kubectl config view --minify` is used instead of parsing ~/.kube/config so a
# multi-file KUBECONFIG merges correctly. It is an offline, local-only call
# (~50ms) and never talks to the cluster.
#
# The tmux server has its own environment, so a plain kubectl call here shows
# the context selected in ~/.kube/config and never sees a kubie subshell, which
# switches context by exporting a private KUBECONFIG into a child shell rather
# than by editing the file. To follow that, the active pane's tty is passed in
# and the script reads KUBECONFIG out of /proc/<pid>/environ for the processes
# on it. Kubie sets KUBIE_DEPTH alongside, which picks the innermost subshell
# when kubie sessions are nested; a plain pid order is the tie-break, since a
# child pid is (barring wrap) higher than its parent's.
#
# Emits a complete styled segment, or nothing when kubectl is absent or no
# context is set.

command -v kubectl >/dev/null 2>&1 || exit 0

tty=${1#/dev/}
if [ -n "$tty" ]; then
	best_depth=-1
	for pid in $(ps -o pid= -t "$tty" 2>/dev/null); do
		env=$(tr '\0' '\n' < "/proc/$pid/environ" 2>/dev/null) || continue
		cfg=$(printf '%s\n' "$env" | sed -n 's/^KUBECONFIG=//p')
		[ -n "$cfg" ] || continue
		depth=$(printf '%s\n' "$env" | sed -n 's/^KUBIE_DEPTH=//p')
		: "${depth:=0}"
		if [ "$depth" -ge "$best_depth" ]; then
			best_depth=$depth
			KUBECONFIG=$cfg
		fi
	done
	[ "$best_depth" -ge 0 ] && export KUBECONFIG
fi

out=$(kubectl config view --minify \
	-o 'jsonpath={.contexts[0].name}{"|"}{.contexts[0].context.namespace}' \
	2>/dev/null) || exit 0

ctx=${out%%|*}
ns=${out#*|}

[ -n "$ctx" ] || exit 0
[ -n "$ns" ] || ns=default

bg0=$(tmux show -gqv @gb_bg0)

# Same guard rail as the kubectl/helm wrappers in ~/.zshrc: a production context
# turns the whole segment red rather than only its text, so it is hard to miss.
if printf '%s' "$ctx" | grep -qiE 'prod|prd|production'; then
	printf '#[fg=%s,bg=%s,bold] 󱃾 %s:%s #[default]' \
		"$bg0" "$(tmux show -gqv @gb_red)" "$ctx" "$ns"
else
	printf '#[fg=%s,bg=%s] 󱃾 %s:%s #[default]' \
		"$bg0" "$(tmux show -gqv @gb_blue)" "$ctx" "$ns"
fi
