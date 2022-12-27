#!/bin/bash -eu

# Set PATH, MANPATH, etc., for Homebrew.
test -d ~/.linuxbrew && eval $(~/.linuxbrew/bin/brew shellenv)
test -d /home/linuxbrew/.linuxbrew && eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv)

[ -f ~/.fzf.bash ] && source ~/.fzf.bash

# VSCodeのシェル統合を利用中に再度`eval "$(starship init bash)"`を行うと、無限ループしてしまう
# そのため`eval "$(starship init bash)"`の実行は一度だけにしたい
# `eval "$(starship init bash)"` を実行すると環境変数STARSHIP_CMD_STATUSが定義されるので、それの有無から実行の可否を決める
if type starship &>/dev/null && [[ ! -v STARSHIP_CMD_STATUS ]]; then
    eval "$(starship init bash)"
fi

if type zoxide &>/dev/null; then
    eval "$(zoxide init bash)"
fi

if type brew &>/dev/null; then
    HOMEBREW_PREFIX="$(brew --prefix)"
    if [[ -r "${HOMEBREW_PREFIX}/etc/profile.d/bash_completion.sh" ]]; then
        source "${HOMEBREW_PREFIX}/etc/profile.d/bash_completion.sh"
    fi

    for COMPLETION in "${HOMEBREW_PREFIX}/etc/bash_completion.d/"*; do
        [[ -r "${COMPLETION}" ]] && source "${COMPLETION}"
    done
fi

export HISTFILESIZE=100000
export HISTSIZE=100000
export HISTTIMEFORMAT='%F %T '
# batで内部的にlessを使うときにless部分の行番号を表示したくないので、--LINE-NUMBERSを指定しない(aliasで設定する)
export LESS='--RAW-CONTROL-CHARS --LONG-PROMPT --hilite-search --IGNORE-CASE --no-init'
export LESSOPEN='|src-hilite-lesspipe.sh -n %s'

if [ "${TERM_PROGRAM}" == "vscode" ]; then
    export EDITOR="code --wait"
    export VISUAL="code --wait"
    export LESSEDIT="code --wait --goto %f\:?lm%lm."
else
    export EDITOR="vim"
    export VISUAL="vim"
    # unset LESSEDIT でもいいけど、とりあえずデフォルト値を指定しておく
    export LESSEDIT="%E ?lm+%lm. %f"
fi

if type bat &>/dev/null; then
    export BAT_STYLE="full"
    export MANPAGER="sh -c 'col -bx | bat -l man -p'" # manコマンドの出力をbatでハイライトする
fi

if type delta &>/dev/null; then
    export GIT_PAGER="delta"
    export DELTA_FEATURES="side-by-side"
fi

if type rg &>/dev/null; then
    export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --glob "!.git"'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND='rg --files-with-matches --hidden --follow --glob "!.git"'
fi

shopt -s autocd      # cdコマンドに引数がないときに、カレントディレクトリを表示する
shopt -s cdable_vars # cdコマンドに変数名を指定できるようにする
shopt -s cdspell     # cdコマンドの引数が間違っているときに、正しい候補を表示する
shopt -s dirspell    # ディレクトリ名のスペルミスを訂正する
shopt -s dotglob     # ドットファイルを含む
shopt -s globstar    # **を使って再帰的にマッチングできるようにする

# Ctrl+Rで履歴をさかのぼって進みすぎたときにCtrl+Sで戻れるようにする
# 普通はCtrl+Sは出力停止に割り当てられているので、それを解除する
# ついでに、Ctrl+Qは出力再開に割り当てられていて出力停止の解除に伴い使わなくなるので、それも解除する
if [[ -t 0 ]]; then # 標準入力が端末のときだけ実行する(scpなどで実行されたときにエラーになるのを防ぐ)
    stty stop undef
    stty start undef
fi

SCRIPT_DIRECTORY="$(dirname "$(realpath "${BASH_SOURCE:-0}")")"

if [[ -r "${SCRIPT_DIRECTORY}/alias.sh" ]]; then
    source "${SCRIPT_DIRECTORY}/alias.sh"
fi

bind -f "${SCRIPT_DIRECTORY}/inputrc"

export STARSHIP_CONFIG="${SCRIPT_DIRECTORY}/starship.toml"
