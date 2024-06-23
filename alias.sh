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

alias ..='cd .. && pwd'

# 以下のようなエイリアスを作成する
# ..1 => cd ../ && pwd
# ..2 => cd ../../ && pwd
for i in {1..9}; do
    dir=$(printf "%${i}s" | sed "s! !../!g")
    # shellcheck disable=SC2139
    alias "..${i}"="cd ${dir} && pwd"
done

alias cat='bat --paging never --style plain'
alias cd='z'
alias e='eza --long --all --icons --time-style iso --ignore-glob ".git"'
alias et='eza --long --all --icons --time-style iso --sort newest --ignore-glob ".git"'
alias exit='exit 0'
alias g='grep --color=auto'
alias icdiff='icdiff -U 1 -N -H'
alias l='ls -Ahg --no-group --color=auto'
alias la='ls -A --color=auto'
alias less='less --LINE-NUMBERS'
alias ll='ls -Al --color=auto'
alias ls='ls -A --color=auto'
alias lt='ls -trl'
alias mkdir='mkdir -p'
alias mkdir-today='mkdir $(date --iso-8601)'
alias mv='mv -i'
alias sl='ls'
alias ssh='ssh -XC'
alias view='vim -RM'

if [ "${OSTYPE}" == "linux-gnu" ]; then
    alias open='xdg-open'
    alias start='xdg-open'
elif [[ "${OSTYPE}" == *"darwin"* ]]; then
    alias start='open'
    # macOS で GNU の ls を使うための alias
    # Coreutils がインストールされている場合にlsがglsとしてインストールされる
    alias ls='gls -A --color=auto'
fi

# WSL で実行中に Windows のコマンドを実行するための alias
if uname -r | grep -qi microsoft; then
    builtin alias explorer='/mnt/c/Windows/explorer.exe'
    builtin alias clip='/mnt/c/Windows/System32/clip.exe'
    builtin alias code='/mnt/c/Users/*/AppData/Local/Programs/Microsoft\ VS\ Code/bin/code'
fi

unset alias
