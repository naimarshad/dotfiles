#!/bin/sh
# Current kubernetes context:namespace for the tmux status line.
#
# `kubectl config view --minify` is used instead of parsing ~/.kube/config so a
# multi-file KUBECONFIG merges correctly. It is an offline, local-only call
# (~50ms) and never talks to the cluster.
#
# The tmux server has its own environment, so this shows the context selected in
# the kubeconfig, not a per-shell override such as a kubie subshell's KUBECONFIG.
#
# Emits a complete styled segment, or nothing when kubectl is absent or no
# context is set.

command -v kubectl >/dev/null 2>&1 || exit 0

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
