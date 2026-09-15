#!/bin/sh
# Git branch and dirty state for the tmux status line.
#
# The pane's directory is passed in as $1. The tmux server's own working
# directory is wherever it was started and is almost never the repo you are
# looking at, so reading $PWD here would report the wrong branch.
#
# Dirtiness uses `git status --porcelain -uno`: skipping untracked files keeps
# this off the status-interval critical path in large working trees.
#
# Emits a complete styled segment, or nothing outside a repository.

dir=${1:-}
[ -n "$dir" ] || exit 0
command -v git >/dev/null 2>&1 || exit 0
cd "$dir" 2>/dev/null || exit 0
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

branch=$(git branch --show-current 2>/dev/null)
# Detached HEAD has no branch name; fall back to the short SHA.
[ -n "$branch" ] || branch=$(git rev-parse --short HEAD 2>/dev/null) || exit 0
[ -n "$branch" ] || exit 0

bg0=$(tmux show -gqv @gb_bg0)

if [ -n "$(git status --porcelain -uno 2>/dev/null)" ]; then
	printf '#[fg=%s,bg=%s]  %s* #[default]' \
		"$bg0" "$(tmux show -gqv @gb_yellow)" "$branch"
else
	printf '#[fg=%s,bg=%s]  %s #[default]' \
		"$bg0" "$(tmux show -gqv @gb_green)" "$branch"
fi
