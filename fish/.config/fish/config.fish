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

# kubecolor's real palette is ~/.kube/color.yaml (deployed by `stow zsh`); this
# only keeps the built-in light preset as the fallback before that file exists.
set -x KUBECOLOR_PRESET light

# Gruvbox light for fzf, the same hex Noctalia renders into
# ghostty/themes/noctalia. Set here rather than left to the fzf.fish default,
# which would otherwise fall back to the terminal's ANSI colours only.
set -x FZF_DEFAULT_OPTS (string join ' ' \
    '--height 60% --layout=reverse --border --multi' \
    '--color=bg+:#ebdbb2,bg:#fbf1c7,spinner:#af3a03,hl:#9d0006' \
    '--color=fg:#3c3836,header:#9d0006,info:#8f3f71,pointer:#af3a03' \
    '--color=marker:#076678,fg+:#3c3836,prompt:#8f3f71,hl+:#9d0006' \
    '--color=selected-bg:#d5c4a1' \
    '--color=border:#bdae93,label:#3c3836')

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
