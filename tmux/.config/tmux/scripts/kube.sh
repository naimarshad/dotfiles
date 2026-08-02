#!/bin/sh
# Current kubernetes context:namespace for the tmux status line.
#
# `kubectl config view --minify` is used instead of parsing ~/.kube/config so a
# multi-file KUBECONFIG merges correctly. It is an offline, local-only call
# (~50ms) and never talks to the cluster.
#
# The tmux server has its own environment, so this shows the context selected in
# the kubeconfig, not a per-shell override (e.g. a kubie subshell's KUBECONFIG).

command -v kubectl >/dev/null 2>&1 || exit 0

out=$(kubectl config view --minify \
	-o 'jsonpath={.contexts[0].name}{"|"}{.contexts[0].context.namespace}' \
	2>/dev/null) || exit 0

ctx=${out%%|*}
ns=${out#*|}

[ -n "$ctx" ] || exit 0
[ -n "$ns" ] || ns=default

# Same guard rail as the kubectl/helm wrappers in ~/.zshrc: production contexts
# get shouted about, here in red.
if printf '%s' "$ctx" | grep -qiE 'prod|prd|production'; then
	printf '#[fg=%s,bold]%s:%s' "$(tmux show -gqv @thm_red)" "$ctx" "$ns"
else
	printf '%s:%s' "$ctx" "$ns"
fi
