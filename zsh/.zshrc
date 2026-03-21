# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

CASE_SENSITIVE="true"
COMPLETION_WAITING_DOTS="true"

# If you come from bash you might have to change your $PATH.
export PATH=$HOME/scripts:$HOME/bin:/usr/local/bin:/home/naeem/.local/bin:/home/naeem/go/bin:$PATH
export PATH="$HOME/.krew/bin:$PATH"
export VAGRANT_DEFAULT_PROVIDER=libvirt
# export DOCKER_HOST=tcp://192.168.1.10:2375
#
#export KUBECOLOR_PRESET="light"
#export BAT_THEME=GitHub

# Path to your oh-my-zsh installation.
export ZSH=/home/naeem/.oh-my-zsh
export TERM="xterm-256color"
export HISTSIZE="-1"
export KUBECTL_KYAML=true

# Set name of the theme to load. Optionally, if you set this to "random"
# it'll load a random theme each time that oh-my-zsh is loaded.
# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes

ZSH_THEME="powerlevel10k/powerlevel10k"
#ZSH_THEME="robbyrussell"
fpath+=${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions/src

plugins=(alias-finder aliases direnv git docker docker-compose colorize kubectl kubectx vscode common-aliases command-not-found zsh-syntax-highlighting \
  fzf zsh-completions zsh-autosuggestions zsh-history-substring-search 1password ansible archlinux you-should-use zsh-bat cp gh dotenv git-auto-fetch \
  git-commit git-lfs history helm opentofu ssh ssh-agent sudo systemd tmux virtualenv eza kind minikube)


zstyle ':omz:plugins:alias-finder' autoload yes # disabled by default
zstyle ':omz:plugins:alias-finder' exact yes # disabled by default
zstyle ':omz:plugins:alias-finder' cheaper yes # disabled by default
zstyle ':omz:plugins:eza' 'dirs-first' yes
zstyle ':omz:plugins:eza' 'git-status' yes
zstyle ':omz:plugins:eza' 'show-group' yes
zstyle ':omz:plugins:eza' 'icons' yes
#zstyle ':omz:plugins:eza' 'color-scale' all
#zstyle ':omz:plugins:eza' 'color-scale-mode' gradient

autoload -Uz compinit && compinit -i

source $ZSH/oh-my-zsh.sh
# source ~/.zsh/catppuccin_macchiato-zsh-syntax-highlighting.zsh
# User configuration
# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
export LANG=en_US.UTF-8
export EDITOR='/usr/bin/nvim'
export VISUAL='/usr/bin/nvim'

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='nvim'
fi

alias vim="nvim"
alias fvim='nvim $(fzf --preview="bat --color=always {}")'
alias kcx='kubie ctx'
alias kns='kubie ns'
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
alias pik8s='export KUBECONFIG=/home/naeem/projects/private/pik8s/kubeconfig'
alias sh01k8s='export KUBECONFIG=/home/naeem/projects/private/k0s/kubeconfig-sh01.yaml'
alias bat='/usr/bin/batcat'
alias pro='cd ~/projects/'

if [ $TILIX_ID ] || [ $VTE_VERSION ]; then
        source /etc/profile.d/vte.sh
fi

### Fuzzy search configurations ###


export FZF_DEFAULT_OPTS="--height 60% --layout=reverse --border --multi" # \
# --color=bg+:#313244,bg:#1E1E2E,spinner:#F5E0DC,hl:#F38BA8 \
# --color=fg:#CDD6F4,header:#F38BA8,info:#CBA6F7,pointer:#F5E0DC \
# --color=marker:#B4BEFE,fg+:#CDD6F4,prompt:#CBA6F7,hl+:#F38BA8 \
# --color=selected-bg:#45475A \
# --color=border:#6C7086,label:#CDD6F4 \
# --multi"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
# [[ /usr/local/bin/kubectl ]] && source <(kubectl completion zsh)


# RI Sepcfic aliases & environment variables
alias dialin="sudo openfortivpn dialin.risk-ident.com:8443 -u naeem.tipu --trusted-cert 9e8cd6c7a1fb2df59bdd56f29dea1fb2777c201ea1b8505e92e0cd9346fa73b5"
alias gro='cd $(git rev-parse --show-toplevel)'

zle -N kube-toggle
bindkey '^]' kube-toggle  # ctrl-] to toggle kubecontext in powerlevel10k prompt

. "$HOME/.cargo/env"

# Destructive verbs that require confirmation
_PROD_PATTERN="prod|prd|production"
_DANGEROUS="^(delete|scale|drain|cordon|taint|patch|apply|exec|edit|cp|replace)"

kubectl() {
  # KUBIE_CTX is set by kubie in its subshell — reliable indicator
  local ctx="${KUBIE_CTX:-$(command kubectl config current-context 2>/dev/null)}"

  if echo "$ctx" | grep -qiE "$_PROD_PATTERN"; then
    if echo "$*" | grep -qE "$_DANGEROUS"; then

      # Hard visual break — hard to overlook
      echo ""
      echo "  ╔══════════════════════════════════════╗"
      echo "  ║   PRODUCTION CONTEXT: $ctx"
      echo "  ╚══════════════════════════════════════╝"
      echo ""
      echo "  Namespace : ${KUBIE_NS:-$(command kubectl config view --minify -o jsonpath='{..namespace}')}"
      echo "  Command   : kubectl $*"
      echo ""
      printf "  Type context name to confirm (%s): " "$ctx"
      read -r _confirm

      if [ "$_confirm" != "$ctx" ]; then
        echo ""
        echo "  ✓ Aborted — no changes made."
        echo ""
        return 1
      fi
      echo ""
    fi
  fi

  command kubecolor "$@"
}

# Helm destructive verbs
_HELM_DANGEROUS="^(upgrade|uninstall|rollback|delete)"

helm() {
  local ctx="${KUBIE_CTX:-$(command kubectl config current-context 2>/dev/null)}"

  if echo "$ctx" | grep -qiE "$_PROD_PATTERN"; then
    if echo "$*" | grep -qE "$_HELM_DANGEROUS"; then
      echo ""
      echo "  ╔══════════════════════════════════════╗"
      echo "  ║   PRODUCTION HELM: $ctx"
      echo "  ╚══════════════════════════════════════╝"
      echo ""
      echo "  Command : helm $*"
      echo ""
      printf "  Type context name to confirm (%s): " "$ctx"
      read -r _confirm

      if [ "$_confirm" != "$ctx" ]; then
        echo "  ✓ Aborted."
        return 1
      fi
    fi
  fi

  command helm "$@"
}

compdef kubecolor=kubectl
