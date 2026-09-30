if status is-interactive
    # Commands to run in interactive sessions can go here
    starship init fish | source
end

# adds alias for "kubectl" to "kubecolor" with completions
function kubectl --wraps kubectl
    command kubecolor $argv
end

# adds alias for "k" to "kubecolor" with completions
function k --wraps kubectl
    command kubecolor $argv
end
# reuse "kubectl" completions on "kubecolor"
function kubecolor --wraps kubectl
    command kubecolor $argv
end
# This needs to be added before "function ... --wraps kubectl"
kubectl completion fish | source

# ----------------------------------------
# Environment & PATH
# ----------------------------------------
set -x PATH $HOME/.krew/bin $PATH
set -x TERM xterm-256color
set -x LANG en_US.UTF-8
set -x KUBECTL_KYAML true

# kubecolor's palette is ~/.kube/color.yaml, pointed at color-light.yaml or
# color-dark.yaml by theme-sync.sh. No KUBECOLOR_PRESET here: it would override
# the preset each file sets.

# fzf colours come from ~/.config/fzf/colors (`stow fzf`), a symlink to
# gruvbox-light or gruvbox-dark that theme-sync.sh flips with Noctalia's theme
# mode. Set here rather than left to the fzf.fish default, which would otherwise
# fall back to the terminal's ANSI colours only. Needs fzf >= 0.47.
set -x FZF_DEFAULT_OPTS_FILE $HOME/.config/fzf/colors
set -x FZF_DEFAULT_OPTS '--height 60% --layout=reverse --border --multi'

# Preferred editor
if test -n "$SSH_CONNECTION"
    set -x EDITOR vim
else
    set -x EDITOR nvim
end
set -x VISUAL nvima

# ----------------------------------------
# SSH helpers (replacing aliases)
# ----------------------------------------

alias osbox='ssh opnsense'
alias qnap='ssh qnap'
alias pvelab='ssh pvelab'
alias sh01='ssh selfhost01'
alias jellyfinpc='ssh jellyfinpc'
alias ri-worklap='ssh ri-worklap'
alias wifirouter='ssh wifirouter'
alias pv01='ssh pv01'
alias mm='ssh mattermost'
alias jellyfinstation='ssh jellyfinstation'

alias wolpve='wol 64:00:6a:8a:db:d5'

# Equivalent of “go to git project root”
function gro
    cd (git -C . rev-parse --show-toplevel)
end
