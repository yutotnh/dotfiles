#!/usr/bin/env bash

# Update や Uninstall 時に本リポジトリのパスを参照するために定義する
DOTFILES_DIRECTORY="$(dirname "$(realpath "${BASH_SOURCE:-0}")")"
export DOTFILES_DIRECTORY

# Set PATH, MANPATH, etc., for Homebrew.
test -d ~/.linuxbrew && eval $(~/.linuxbrew/bin/brew shellenv)
test -d /home/linuxbrew/.linuxbrew && eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv)
test -d /opt/homebrew/ && eval $(/opt/homebrew/bin/brew shellenv)

[ -f ~/.fzf.bash ] && source ~/.fzf.bash

# VSCodeのシェル統合を利用中に再度`eval "$(starship init bash)"`を行うと、無限ループしてしまう
# そのため`eval "$(starship init bash)"`の実行は一度だけにしたい
# `eval "$(starship init bash)"` を実行すると環境変数STARSHIP_CMD_STATUSが定義されるので、それの有無から実行の可否を決める
if type starship &>/dev/null && [[ ! -v STARSHIP_CMD_STATUS ]]; then
    eval "$(starship init bash)"
    export STARSHIP_CONFIG="${DOTFILES_DIRECTORY}/starship.toml"
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

    unset HOMEBREW_PREFIX
fi

if type rustc &>/dev/null; then
    source "$(rustc --print sysroot)/etc/bash_completion.d/cargo"
fi

export HISTFILESIZE=100000
export HISTSIZE=100000
export HISTTIMEFORMAT='%F %T '
export HISTCONTROL=ignoreboth
export HISTIGNORE='cd:e:et:exit:l:la:less:less *:ll:ls:ls *:lt:lv:lv *:sl:date:pwd:* --help'
export HISTFILE="${DOTFILES_DIRECTORY}/.bash_history"

if type less &>/dev/null; then
    # batで内部的にlessを使うときにless部分の行番号を表示したくないので、--LINE-NUMBERSを指定しない(aliasで設定する)
    export LESS='--RAW-CONTROL-CHARS --LONG-PROMPT --hilite-search --IGNORE-CASE --no-init'

    if type src-hilite-lesspipe.sh &>/dev/null; then
        export LESSOPEN='|src-hilite-lesspipe.sh %s'
        if type lv &>/dev/null; then
            # 文字コードがUTF-8でないときに備えて、lvを使って文字コードを変換する
            export LESSOPEN="${LESSOPEN} | lv"
        fi
    fi
fi

# よく誤入力するので、Ctrl+Dを一回打っただけでログアウトされるとつらい
# そのため、Ctrl+Dを4回押すとbashを終了するようにする
export IGNOREEOF=3

# 編集は基本VS Codeを使った方が速いので、
# VS Codeの統合ターミナルを利用している時はVS Codeを利用する
if [ "${TERM_PROGRAM}" == "vscode" ]; then
    export EDITOR="code --wait"
    export VISUAL="code --wait"
    export LESSEDIT="code --wait --goto %f\:?lm%lm."
else
    if type vim &>/dev/null; then
        export EDITOR="vim"
        export VISUAL="vim"
    fi
    # unset LESSEDIT でもいいけど、とりあえずデフォルト値を指定しておく
    export LESSEDIT="%E ?lm+%lm. %f"
fi

if type bat &>/dev/null; then
    export BAT_STYLE="full"
    export MANPAGER="sh -c 'col -bx | bat -l man -p'" # manコマンドの出力をbatでハイライトする
    export MANROFFOPT="-c"                            # manコマンドのフォーマットがおかしくなるのを防ぐ
fi

if type delta &>/dev/null; then
    export GIT_PAGER="delta"
    export DELTA_FEATURES="side-by-side"
    if type lv &>/dev/null; then
        export GIT_PAGER="lv | ${GIT_PAGER}"
    fi
fi

if type lv &>/dev/null; then
    export LV="-c"
fi

if type fzf &>/dev/null; then
    export FZF_HEADER="whoami | sed -z 's/\n/ in /g'; hostname | sed -z 's/\n/ in /g '; pwd"
    if type fd &>/dev/null; then
        export FZF_DEFAULT_COMMAND="${FZF_HEADER}; fd --type f --hidden --exclude .git"
    else
        export FZF_DEFAULT_COMMAND="${FZF_HEADER}; find . -type f -not -path '*/\.git/*'"
    fi
    export FZF_DEFAULT_OPTS='--no-height --border none --preview-window border-left --header-lines 1 --reverse --no-mouse'

    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    if type bat &>/dev/null; then
        export FZF_CTRL_T_OPTS='--preview "bat --style=numbers --color=always --line-range :500 {}"'
    else
        export FZF_CTRL_T_OPTS='--preview "head -n 500 {}"'
    fi

    # FZF_CTRL_R_COMMAND は存在しないので、FZF_DEFAULT_OPTSからヘッダーを除き、ヘッダーを別途指定する
    # 実行毎にヘッダーを構成できないので、ユーザー名とホスト名をヘッダーに含め、カレントディレクトリの表示は諦める
    export FZF_CTRL_R_OPTS="--no-header-lines --header ${USER}\ in\ ${HOSTNAME}"

    if type fd &>/dev/null; then
        export FZF_ALT_C_COMMAND="${FZF_HEADER}; fd --type d --hidden --exclude .git"
    else
        export FZF_ALT_C_COMMAND="${FZF_HEADER}; find . -type d -not -path '*/\.git/*'"
    fi

    if type eza &>/dev/null; then
        export FZF_ALT_C_OPTS='--preview "eza --all --long --tree --level 3 --time-style=iso {}"'
    elif type tree &>/dev/null; then
        export FZF_ALT_C_OPTS='--preview "tree -C -L 3 -a -l --timefmt %F {}"'
    else
        export FZF_ALT_C_OPTS='--preview "ls -l --time-style=iso {}"'
    fi
fi

if type vim &>/dev/null; then
    export VIMINIT="source ${DOTFILES_DIRECTORY}/.vimrc"
fi

shopt -s autocd      # cdコマンドに引数がないときに、カレントディレクトリを表示する
shopt -s cdable_vars # cdコマンドに変数名を指定できるようにする
shopt -s cdspell     # cdコマンドの引数が間違っているときに、正しい候補を表示する
shopt -s dirspell    # ディレクトリ名のスペルミスを訂正する
shopt -s globstar    # **を使って再帰的にマッチングできるようにする

# Ctrl+Rで履歴をさかのぼって進みすぎたときにCtrl+Sで戻れるようにする
# 普通はCtrl+Sは出力停止に割り当てられているので、それを解除する
# ついでに、Ctrl+Qは出力再開に割り当てられていて出力停止の解除に伴い使わなくなるので、それも解除する
# fzfをインストールしているときは意味がないけど、インストールしていないときのために設定する
if [[ -t 0 ]]; then # 標準入力が端末のときだけ実行する(scpなどで実行されたときにエラーになるのを防ぐ)
    stty stop undef
    stty start undef
fi

if [[ -r "${DOTFILES_DIRECTORY}/alias.sh" ]]; then
    source "${DOTFILES_DIRECTORY}/alias.sh"
fi

# 標準出力が端末でないときに下記の処理を実行すると`bind: warning: line editing not enabled`が発生するため、
# 標準出力が端末のときだけ実行する
# 多分上で処理している `[[ -t 0 ]]` でもいいけど、参考にしたサイトが`[[ -t 1 ]]`なので念のため同じにしている
if [[ -t 1 ]]; then
    bind -f "${DOTFILES_DIRECTORY}/.inputrc"
fi

# LANG=ja_JP.UTF-8が設定できる環境では、LANG=ja_JP.UTF-8を設定する
# `locale -a`で出てくる物は正規化されているので、UTF-8ではなくutf8になっている
if locale -a 2>/dev/null | grep -qF 'ja_JP.utf8'; then
    export LANG=ja_JP.UTF-8
fi
