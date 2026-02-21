## Core kubectl
#alias k='kubectl'
#alias kc='kubectl config'
#alias kg='kubectl get'
#alias kga='kubectl get all'
#alias kgno='kubectl get nodes'
#alias kgp='kubectl get pods'
#alias kgpw='kubectl get pods --watch'
#alias kgpa='kubectl get pods --all-namespaces'
#alias kgs='kubectl get svc'
#alias kgsw='kubectl get svc --watch'
#alias kgns='kubectl get namespaces'
#alias kgi='kubectl get ingress'
#alias kgcm='kubectl get configmaps'
#alias kgpvc='kubectl get pvc'
alias kcx='kubectl ctx'
alias kns='kubectl ns'
#
## Kubectl Descriptions
#alias kd='kubectl describe'
#alias kdp='kubectl describe pods'
#alias kds='kubectl describe svc'
#alias kdd='kubectl describe deployment'
#alias kdno='kubectl describe node'
#alias kdelns='kubectl delete namespace'
#
## Kubectl Edit shortcuts
#alias kep='kubectl edit pods'
#alias kes='kubectl edit svc'
#alias ked='kubectl edit deployment'
#alias kens='kubectl edit namespace'
#
## Kubectl Delete shortcuts
#alias kdelp='kubectl delete pods'
#alias kdels='kubectl delete svc'
#alias kdeld='kubectl delete deployment'
#
## Kubectl Logs & rollouts
#alias kl='kubectl logs'
#alias klf='kubectl logs -f'
#alias kl1h='kubectl logs --since 1h'
#alias klf1h='kubectl logs --since 1h -f'
#alias krsd='kubectl rollout status deployment'
#alias kru='kubectl rollout undo'
#
## Kubectl Port-forward
#alias kpf='kubectl port-forward'
#
## Kubectl Misc helpful
#alias kgd='kubectl get deployment'
#alias kgdw='kubectl get deployment --watch'
#alias kgswide='kubectl get svc -o wide'

# helm
alias h='helm'
alias hl='helm list'
alias hu='helm upgrade --install'

# terraform
alias t='tofu'
alias tti='tofu init'
alias ttp='tofu plan'
alias tta='tofu apply'
alias ttd='tofu destroy'

# --- Docker / Container tools ---
alias d='docker'
alias dps='docker ps'
alias di='docker images'
alias drm='docker rm'
alias drmi='docker rmi'
alias dcu='docker compose up -d'
alias dcd='docker compose down'

alias p='podman'
alias pps='podman ps'
alias pcup='podman compose up -d'
alias pcd='podman compose down'

# --- Git ---
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gca='git commit -a'
alias gp='git push'
alias gpl='git pull'
alias gco='git checkout'
alias gb='git branch'
alias gcb='git checkout -b'
alias gl='git log --oneline --graph --decorate'

# Common Aliases
alias vim='nvim'
