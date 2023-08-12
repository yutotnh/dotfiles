#!/usr/bin/env bash

##
# @brief alias で実行するコマンドが存在するときのみ、 alias に登録する関数
function alias() {
    local command
    command=$(echo "${1}" | grep -o "\=[^[:space:]]*" | sed 's/\=//' | head -1)

    if type "${command}" &>/dev/null; then
        builtin alias "${1}"
    fi
}

alias ..='cd ..'
alias cat='bat --paging never --style plain'
alias cd='z'
alias e='exa --long --all --icons --time-style iso --ignore-glob ".git"'
alias et='exa --long --all --icons --time-style iso --sort newest --ignore-glob ".git"'
alias exit='exit 0'
alias fzf='fzf --preview "bat --color=always --style=numbers --line-range=:500 {}"'
alias icdiff='icdiff -U 1 -N -H'
alias l='ls -Ahg --no-group --color=auto'
alias la='ls -A --color=auto'
alias less='less --LINE-NUMBERS'
alias ll='ls -Al --color=auto'
alias ls='ls -A --color=auto'
alias sl='ls'
alias ssh='ssh -XC'
alias view='vim -RM'

if [ "${OSTYPE}" == "linux-gnu" ]; then
    alias open='xdg-open'
    alias start='xdg-open'
elif [ "${OSTYPE}" == "darwin" ]; then
    alias start='open'
fi

# WSL で実行中に Windows のコマンドを実行するための alias
if uname -r | grep -qi microsoft; then
    builtin alias explorer='/mnt/c/Windows/explorer.exe'
    builtin alias clip='/mnt/c/Windows/System32/clip.exe'
    builtin alias code='/mnt/c/Users/*/AppData/Local/Programs/Microsoft\ VS\ Code/bin/code'
fi

unset alias
