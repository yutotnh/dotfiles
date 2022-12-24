#!/bin/bash -eu

# Set PATH, MANPATH, etc., for Homebrew.
test -d ~/.linuxbrew && eval $(~/.linuxbrew/bin/brew shellenv)
test -d /home/linuxbrew/.linuxbrew && eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv)

[ -f ~/.fzf.bash ] && source ~/.fzf.bash

if type starship &>/dev/null; then
    eval "$(starship init bash)"
fi

if type zoxide &>/dev/null; then
    eval "$(zoxide init bash)"
fi

if type brew &>/dev/null; then
    HOMEBREW_PREFIX="$(brew --prefix)"
    if [[ -r "${HOMEBREW_PREFIX}/etc/profile.d/bash_completion.sh" ]]; then
        source "${HOMEBREW_PREFIX}/etc/profile.d/bash_completion.sh"
    else
        for COMPLETION in "${HOMEBREW_PREFIX}/etc/bash_completion.d/"*; do
            [[ -r "${COMPLETION}" ]] && source "${COMPLETION}"
        done
    fi
fi

export HISTFILESIZE=100000
export HISTSIZE=100000
export HISTTIMEFORMAT='%F %T '
export LESS='--RAW-CONTROL-CHARS --LONG-PROMPT --hilite-search --IGNORE-CASE --no-init' # batで内部的にlessを使うときにless部分の行番号を表示したくないので、--LINE-NUMBERSを指定しない(aliasで設定する)
export LESSOPEN='|src-hilite-lesspipe.sh -n %s'

if [ "${TERM_PROGRAM}" == "vscode" ]; then
    export EDITOR="code --wait"
    export VISUAL="code --wait"
    export LESSEDIT="code --wait --goto %f\:?lm%lm."
fi

if type rg &>/dev/null; then
    export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --glob "!.git"'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND='rg --files-with-matches --hidden --follow --glob "!.git"'
fi

if type bat &>/dev/null; then
    export BAT_STYLE="full"
    export MANPAGER="sh -c 'col -bx | bat -l man -p'"
fi

shopt -s autocd
shopt -s cdable_vars
shopt -s cdspell
shopt -s dirspell
shopt -s dotglob
shopt -s globstar
shopt -u direxpand

stty stop undef  # Ctrl+Rで履歴をさかのぼって進みすぎたときにCtrl+Sで戻れるようにする
stty start undef # 普通はCtrl+Sは端末ロックに割り当てられているので、それを解除

script_directory="$(dirname "$(realpath "${BASH_SOURCE:-0}")")"

if [[ -r "${script_directory}/git-completion.bash" ]]; then
    source git-completion.bash
fi

if [[ -r "${script_directory}/alias.sh" ]]; then
    source alias.sh
fi
