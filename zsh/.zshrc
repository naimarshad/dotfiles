# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

CASE_SENSITIVE="true"
COMPLETION_WAITING_DOTS="true"

# If you come from bash you might have to change your $PATH.
export PATH=$HOME/scripts:$HOME/bin:/usr/local/bin:/home/naeem/.local/bin:/home/naeem/go/bin:/home/naeem/.docker/sbx/bin:$PATH
export PATH="$HOME/.krew/bin:$PATH"
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
export PATH="$HOME/.npm-global/bin:$PATH"
export VAGRANT_DEFAULT_PROVIDER=libvirt
# export KUBECOLOR_PRESET="dark"
export BAT_THEME="Catppuccin Latte"
# export DOCKER_HOST=tcp://192.168.1.10:2375
export KUBECOLOR_LIGHT_BACKGROUND=true
export KUBECOLOR_PRESET="light"
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

plugins=(alias-finder aliases direnv git docker docker-compose colorize kubectl vscode common-aliases command-not-found zsh-syntax-highlighting \
  fzf zsh-completions zsh-autosuggestions zsh-history-substring-search 1password ansible archlinux you-should-use zsh-bat cp gh dotenv git-auto-fetch \
  git-commit git-lfs history helm opentofu ssh ssh-agent sudo systemd virtualenv eza kind minikube)

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
#source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source ~/.zsh/catppuccin_latte-zsh-syntax-highlighting.zsh
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

###### General Use Alaises #####
alias vim="nvim"
alias fvim='vim $(fzf --preview="bat --color=always {}")'
alias yayin="yay -S --noconfirm"
alias play="cd ~/ri-work/playground"
alias kk="kubectl-klock"
alias kvs="kubectl-view_secret"
alias szero="kubectl-szero"
alias kgir="kubectl get ingressroutes"
alias mc="/usr/bin/mcli"
alias dim="docker images"
alias pro="cd /home/naeem/projects/"

## Personal Aliases
alias vim="nvim"
alias fvim='nvim $(fzf --preview="bat --color=always {}")'
alias kcx='kubectl-ctx'
alias kns='kubectl-ns'
alias osbox='ssh opnsense'
alias qnap='ssh qnap'
alias pvelab='ssh pvelab'
alias sh01='ssh selfhost01'
alias jellyfinpc='ssh jellyfinpc'
alias ri-worklap='ssh ri-worklap'
alias wifirouter='ssh wifirouter'
alias mm='ssh mattermost'
alias jellyfinstation='ssh jellyfinstation'
alias jellyfinpc='ssh jellyfinpc'
alias pvewol='wol 64:00:6a:8a:db:d5'
alias pro='cd ~/projects/'
alias rnotes='cd ~/Obsidian/ri-runbooks/'
alias pnotes='cd ~/Obsidian/personal-runbooks/'

if [ $TILIX_ID ] || [ $VTE_VERSION ]; then
        source /etc/profile.d/vte.sh
fi

### Fuzzy search configurations ###
export FZF_DEFAULT_OPTS="--height 60% --layout=reverse --border --multi \
--color=bg+:#CCD0DA,bg:#EFF1F5,spinner:#DC8A78,hl:#D20F39 \
--color=fg:#4C4F69,header:#D20F39,info:#8839EF,pointer:#DC8A78 \
--color=marker:#7287FD,fg+:#4C4F69,prompt:#8839EF,hl+:#D20F39 \
--color=selected-bg:#BCC0CC \
--color=border:#9CA0B0,label:#4C4F69"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
# [[ /usr/local/bin/kubectl ]] && source <(kubectl completion zsh)

# RI Sepcfic aliases & environment variables
alias dialin="sudo openfortivpn dialin.risk-ident.com:8443 -u naeem.tipu --trusted-cert 9e8cd6c7a1fb2df59bdd56f29dea1fb2777c201ea1b8505e92e0cd9346fa73b5"
alias gro='cd $(git rev-parse --show-toplevel)'
alias review="gh search prs --review-requested naeem-tipu --state open --review required"
alias merge="gh search prs --author naeem-tipu --state open --review approved"
alias changes="gh search prs --author naeem-tipu --state open --review changes_requested"
alias iacdel="cd /home/naeem/ri-work/git-repos/platform/iac/ && gco main && rm -rf .claude/hooks && rm -rf .claude/settings.json && rm -rf AGENTS.md"
alias iacrest="cd /home/naeem/ri-work/git-repos/platform/iac/ && gco main && git restore .claude/hooks && git restore .claude/settings.json && git restore AGENTS.md"
alias iac="cd /home/naeem/ri-work/git-repos/platform/iac"
alias aiac="cd /home/naeem/ri-work/git-repos/platform/iac/ansible"
alias tiac="cd /home/naeem/ri-work/git-repos/platform/iac/terraform"
alias hc="cd /home/naeem/ri-work/git-repos/platform/iac/helm_charts/"
alias hv="cd /home/naeem/ri-work/git-repos/platform/iac/helm_values/"
alias dev_platform="cd /home/naeem/ri-work/git-repos/platform/iac/terraform/non-prod/pks/natwork/dev-platform/"
# sops finds the age private key here; it is mode 600 and never committed.
# Losing it makes every .sops.* file in the dotfiles repo unrecoverable.
export SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"

alias spsd='sops decrypt'
alias spse='sops edit'

# IaC path navigation related aliases
alias tprod-paymenthubb2c='cd /home/naeem/ri-work/git-repos/platform/iac/terraform/prod/pks/iphh/prod-paymenthubb2c'
alias tprod-deviceident='cd /home/naeem/ri-work/git-repos/platform/iac/terraform/prod/pks/iphh/prod-deviceident/'
alias tprod-skreditpartner='cd /home/naeem/ri-work/git-repos/platform/iac/terraform/prod/pks/iphh/prod-skreditpartner/'
alias tprod-frida2='cd /home/naeem/ri-work/git-repos/platform/iac/terraform/prod/pks/iphh/prod-frida2/'
alias tprod-database='cd /home/naeem/ri-work/git-repos/platform/iac/terraform/prod/pks/iphh/prod-database/'

export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

export JIRA_USERMAIL=naeem.tipu@riskident.com
export ANSIBLE_REMOTE_USER=naeemtipu
#export ANSIBLE_BECOME=True

zle -N kube-toggle
bindkey '^]' kube-toggle  # ctrl-] to toggle kubecontext in powerlevel10k prompt

# Destructive verbs that require confirmation. Exported because the shell
# snapshot used by external tooling captures functions but not plain variables.
# Matched against the subcommand alone, so no anchors here.
export _PROD_PATTERN="prod|prd|production"
export _DANGEROUS="delete|scale|drain|cordon|uncordon|taint|patch|apply|create|replace|edit|exec|cp|rollout|annotate|label|set"
export _READONLY="get|describe|logs|top|explain|api-resources|api-versions|config|version|cluster-info|auth|wait|port-forward|proxy|events|diff"

kubectl() {
  # KUBIE_CTX is set by kubie in its subshell — reliable indicator
  local ctx="${KUBIE_CTX:-$(command kubectl config current-context 2>/dev/null)}"

  # An unset pattern would leave grep testing an empty regex, which matches
  # everything, so never rely on the values above being in scope.
  : "${_PROD_PATTERN:=prod|prd|production}"
  : "${_DANGEROUS:=delete|scale|drain|cordon|uncordon|taint|patch|apply|create|replace|edit|exec|cp|rollout|annotate|label|set}"
  : "${_READONLY:=get|describe|logs|top|explain|api-resources|api-versions|config|version|cluster-info|auth|wait|port-forward|proxy|events|diff}"

  # Decide on the first argument that names a subcommand, whichever list it
  # lands in. Taking the first non-flag token instead lets
  # "kubectl -n default delete pod" through, because "default" is neither a
  # flag nor a verb.
  local a _verdict="safe"
  for a in "$@"; do
    [[ $a == -* ]] && continue
    if echo "$a" | grep -qxE "$_READONLY"; then _verdict="safe"; break; fi
    if echo "$a" | grep -qxE "$_DANGEROUS"; then _verdict="danger"; break; fi
  done  

  if echo "$ctx" | grep -qiE "$_PROD_PATTERN"; then
    if [ "$_verdict" = danger ]; then

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

# Helm destructive verbs. Exported because the shell snapshot used by external
# tooling captures functions but not plain variables. Matched against the
# subcommand alone, so no anchors here.
export _HELM_DANGEROUS="install|upgrade|uninstall|rollback|delete"
export _HELM_READONLY="diff|template|lint|show|get|list|ls|history|status|search|repo|version|env|plugin|dependency|dep|package|pull|inspect|completion"

helm() {
  # An unset pattern would leave grep testing an empty regex, which matches
  # everything, so never rely on the values above being in scope.
  : "${_PROD_PATTERN:=prod|prd|production}"
  : "${_HELM_DANGEROUS:=install|upgrade|uninstall|rollback|delete}"
  : "${_HELM_READONLY:=diff|template|lint|show|get|list|ls|history|status|search|repo|version|env|plugin|dependency|dep|package|pull|inspect|completion}"

  # Decide on the first argument that names a subcommand, whichever list it
  # lands in. Taking the first non-flag token instead lets
  # "helm --namespace x upgrade" through, because "x" is neither a flag nor a
  # verb. Checking read-only first is what keeps "helm diff upgrade" quiet.
  local a _verdict="safe"
  for a in "$@"; do
    [[ $a == -* ]] && continue
    if echo "$a" | grep -qxE "$_HELM_READONLY"; then _verdict="safe"; break; fi
    if echo "$a" | grep -qxE "$_HELM_DANGEROUS"; then _verdict="danger"; break; fi
  done
  local ctx="${KUBIE_CTX:-$(command kubectl config current-context 2>/dev/null)}"

  if echo "$ctx" | grep -qiE "$_PROD_PATTERN"; then
    if [ "$_verdict" = danger ]; then
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

eval "$(/home/naeem/.local/bin/mise activate zsh)"


export KUBECOLOR_LIGHT_BACKGROUND=true
compdef kubecolor=kubectl
