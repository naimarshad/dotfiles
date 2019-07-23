# If you come from bash you might have to change your $PATH.
 export PATH=$HOME/scripts:$HOME/bin:/usr/local/bin:$PATH
# export PATH=/home/naeem/.gem/ruby/2.5.0/bin:$PATH
# source $(dirname $(gem which colorls))/tab_complete.sh
 export EDITOR=/usr/bin/vim
# Path to your oh-my-zsh installation.
 export ZSH=/home/naeem/.oh-my-zsh
 export VAGRANT_HOME=/mnt/data/vagrant
 export TERM="xterm-256color"
 export HISTSIZE="-1"
# Set name of the theme to load. Optionally, if you set this to "random"
# it'll load a random theme each time that oh-my-zsh is loaded.
# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes

ZSH_THEME="jonathan"
plugins=(git fedora virtualenv python anaconda pyenv colorize) 

# Syntax highlighting and tab completion
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /usr/share/zsh/scripts/zplug/init.zsh
#source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
autoload -Uz compinit

##### Zplug related information #####
# Check if zplug is installed


if [[ ! -d ~/.zplug ]]; then
  git clone https://github.com/zplug/zplug ~/.zplug
  source ~/.zplug/init.zsh && zplug update --self
fi

# Essential
source ~/.zplug/init.zsh

# Make sure to use double quotes to prevent shell expansion
zplug "zsh-users/zsh-syntax-highlighting"

# Add a bunch more of your favorite packages!

# Install packages that have not been installed yet
if ! zplug check --verbose; then
    printf "Install? [y/N]: "
    if read -q; then
        echo; zplug install
    else
        echo
    fi
fi

zplug load


# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> Power Level 9k custom
POWERLEVEL9K_MODE="nerdfont-complete"
#POWERLEVEL9K_MODE='awesome-patched'
POWERLEVEL9K_TIME_BACKGROUND='32'
POWERLEVEL9K_TIME_FOREGROUND='0'
#POWERLEVEL9K_PROMPT_ON_NEWLINE=true
#POWERLEVEL9K_RPROMPT_ON_NEWLINE=false
#POWERLEVEL9K_MULTILINE_FIRST_PROMPT_PREFIX="%F{014}╭%F{white}"
#POWERLEVEL9K_MULTILINE_LAST_PROMPT_PREFIX="%F{014}\u2570%F{white}\uF460%F{073}\uF460%F{109}\uF460%f "
POWERLEVEL9K_CONTEXT_DEFAULT_BACKGROUND='black'
POWERLEVEL9K_CONTEXT_DEFAULT_FOREGROUND='009'
POWERLEVEL9K_DIR_HOME_BACKGROUND='009'
POWERLEVEL9K_DIR_HOME_FOREGROUND='black'
POWERLEVEL9K_DIR_DEFAULT_BACKGROUND='196'
POWERLEVEL9K_DIR_DEFAULT_FOREGROUND='232'
#POWERLEVEL9K_VCS_CLEAN_FOREGROUND='099'

#Icon config
POWERLEVEL9K_HOME_ICON='\UF015'
POWERLEVEL9K_SUB_ICON='\UF07C'
POWERLEVEL9K_FOLDER_ICON='\UF07B'
POWERLEVEL9K_STATUS_OK_ICON='\UF2B0'
POWERLEVEL9K_LEFT_SEGMENT_SEPARATOR='\UE0BC'
POWERLEVEL9K_RIGHT_SEGMENT_SEPARATOR='\UE0BA'

# Anaconda
POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(anaconda battery)
POWERLEVEL9K_ANACONDA_RIGHT_DELIMITER='>'
POWERLEVEL9K_ANACONDA_LEFT_DELIMITER='<'
POWERLEVEL9K_ANACONDA_BACKGROUND='24'
POWERLEVEL9K_ANACONDA_FOREGROUND='111'
# POWERLEVEL9K_ANACONDA_ICON=''

# Misc
POWERLEVEL9K_BATTERY_CHARGING='yellow'
POWERLEVEL9K_BATTERY_CHARGED='blue'
POWERLEVEL9K_BATTERY_LOW_THRESHOLD='20'
POWERLEVEL9K_BATTERY_LOW_COLOR='red'
POWERLEVEL9K_BATTERY_CHARGED_BACKGROUND='46'
POWERLEVEL9K_BATTERY_CHARGED_FOREGROUND='235'
POWERLEVEL9K_BATTERY_CHARGING_BACKGROUND='178'
POWERLEVEL9K_BATTERY_CHARGING_FOREGROUND='235'
POWERLEVEL9K_BATTERY_LOW_BACKGROUND='88'
POWERLEVEL9K_BATTERY_LOW_FOREGROUND='235'
POWERLEVEL9K_BATTERY_CHARGED_ICON='/UF240'
POWERLEVEL9K_BATTERY_LOW_ICON='/UF240'
POWERLEVEL9K_BATTERY_CHARGING_ICON='/UF1E6'
POWERLEVEL9K_BATTERY_DISCONNECTED_FOREGROUND='195'
POWERLEVEL9K_BATTERY_DISCONNECTED_BACKGROUND='009'
POWERLEVEL9K_BATTERY_ICON='\UF1E6'
POWERLEVEL9K_STATUS_OK_BACKGROUND="black"
POWERLEVEL9K_STATUS_OK_FOREGROUND="green"
POWERLEVEL9K_STATUS_ERROR_BACKGROUND="black"
POWERLEVEL9K_STATUS_ERROR_FOREGROUND="red"
POWERLEVEL9K_NVM_BACKGROUND="black"
POWERLEVEL9K_NVM_FOREGROUND="249"
POWERLEVEL9K_NVM_VISUAL_IDENTIFIER_COLOR="green"
POWERLEVEL9K_RVM_BACKGROUND="black"
POWERLEVEL9K_RVM_FOREGROUND="249"
POWERLEVEL9K_RVM_VISUAL_IDENTIFIER_COLOR="red"
POWERLEVEL9K_LOAD_CRITICAL_BACKGROUND="black"
POWERLEVEL9K_LOAD_WARNING_BACKGROUND="black"
POWERLEVEL9K_LOAD_NORMAL_BACKGROUND="black"
POWERLEVEL9K_LOAD_CRITICAL_FOREGROUND="249"
POWERLEVEL9K_LOAD_WARNING_FOREGROUND="249"
POWERLEVEL9K_LOAD_NORMAL_FOREGROUND="249"
POWERLEVEL9K_LOAD_CRITICAL_VISUAL_IDENTIFIER_COLOR="red"
POWERLEVEL9K_LOAD_WARNING_VISUAL_IDENTIFIER_COLOR="yellow"
POWERLEVEL9K_LOAD_NORMAL_VISUAL_IDENTIFIER_COLOR="green"
POWERLEVEL9K_RAM_BACKGROUND="black"
POWERLEVEL9K_RAM_FOREGROUND="249"
POWERLEVEL9K_RAM_ELEMENTS=(ram_free)
POWERLEVEL9K_TIME_BACKGROUND="black"
POWERLEVEL9K_TIME_FOREGROUND="249"
POWERLEVEL9K_TIME_FORMAT="%D{%H:%M:%S}"
#POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=('status' 'os_icon' 'todo' 'context' 'dir' 'vcs')
#POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=('nvm' 'rvm' 'load' 'ram_joined' 'battery' 'time')


#plugins=(git fedora virtualenv python pyenv colorize) 

source $ZSH/oh-my-zsh.sh

# User configuration
# export MANPATH="/usr/local/man:$MANPATH"
# You may need to manually set your language environment

export LANG=en_US.UTF-8
export EDITOR='/usr/bin/vim'
export VISUAL='/usr/bin/vim'


# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='mvim'
fi

alias cudaMiner="zsh ./CCminer"
alias vimfix="zsh ~/dos2unixloop"
alias lc="colorls -A --sd"
alias yao="yaourt --noconfirm"
alias clear="clear && screenfetch"
alias aurman="aurman --noconfirm"
alias yay="yay --noconfirm"
alias i3config='vim ~/.config/i3/config'
alias polybarconfig='vim ~/.config/polybar/config'
alias autoscript=/$HOME/scripts/createscript.sh

# source /usr/share/zsh-theme-powerlevel9k/powerlevel9k.zsh-theme

if [ $TILIX_ID ] || [ $VTE_VERSION ]; then
        source /etc/profile.d/vte.sh
fi
