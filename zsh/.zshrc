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

# Path to your oh-my-zsh installation.
export ZSH=/home/naeem/.oh-my-zsh
export TERM="xterm-256color"
export HISTSIZE="-1"
export KUBECTL_KYAML=true

# Set name of the theme to load. Optionally, if you set this to "random"
# it'll load a random theme each time that oh-my-zsh is loaded.
# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes

ZSH_THEME="powerlevel10k/powerlevel10k"
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
# source ~/.zsh/catppuccin_latte-zsh-syntax-highlighting.zsh
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

# Colours come from ~/.config/fzf/colors (`stow fzf`), a symlink to
# gruvbox-light or gruvbox-dark that niri/.config/niri/theme-sync.sh flips with
# Noctalia's theme mode. fzf reads the file on every run, before
# FZF_DEFAULT_OPTS, so open shells follow the switch too. Needs fzf >= 0.47.
export FZF_DEFAULT_OPTS_FILE="$HOME/.config/fzf/colors"
export FZF_DEFAULT_OPTS="--height 60% --layout=reverse --border --multi"

# kubecolor's palette is ~/.kube/color.yaml, pointed at color-light.yaml or
# color-dark.yaml by theme-sync.sh. No KUBECOLOR_PRESET here: it would override
# the preset each file sets.

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
# [[ /usr/local/bin/kubectl ]] && source <(kubectl completion zsh)

# RI Sepcfic aliases & environment variables
#alias dialin="sudo openfortivpn dialin.risk-ident.com:8443 -u naeem.tipu --trusted-cert 9e8cd6c7a1fb2df59bdd56f29dea1fb2777c201ea1b8505e92e0cd9346fa73b5"
alias dialin='(sudo /usr/bin/cat /root/.vpn-creds; /usr/bin/cat) | sudo openconnect --protocol=fortinet -u naeem.tipu --passwd-on-stdin --servercert pin-sha256:d9Cj+U8nIqWq1jT/PR7rVEwdImWHroELqpdmn/M3yek= dialin.risk-ident.com:8443'
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
alias kubectl=kubecolor

export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

export JIRA_USERMAIL=naeem.tipu@riskident.com
export ANSIBLE_REMOTE_USER=naeemtipu
#export ANSIBLE_BECOME=True

zle -N kube-toggle
bindkey '^]' kube-toggle  # ctrl-] to toggle kubecontext in powerlevel10k prompt

eval "$(cd /home/naeem/ri-work/git-repos/platform/iac/ && /home/naeem/.local/bin/mise activate zsh)"

### Openrouter Configs
# export ANTHROPIC_BASE_URL="https://openrouter.ai/api"
# export ANTHROPIC_AUTH_TOKEN="$OPENROUTER_API_KEY"
# export ANTHROPIC_API_KEY="" # Important: Must be explicitly empty
# export CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY=1 # Optional: enables the gateway model picker

# Openrouter Claude model
#
# export ANTHROPIC_DEFAULT_OPUS_MODEL="deepseek/deepseek-v4.1-flash"
# export ANTHROPIC_DEFAULT_HAIKU_MODEL="deepseek/deepseek-v4.1-flash"

compdef kubecolor=kubectl
