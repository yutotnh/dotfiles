#!/usr/bin/env bash

# Update や Uninstall 時に本リポジトリのパスを参照するために定義する
DOTFILES_DIRECTORY="$(dirname "$(realpath "${BASH_SOURCE:-0}")")"
export DOTFILES_DIRECTORY

# Set PATH, MANPATH, etc., for Homebrew.
test -d ~/.linuxbrew && eval $(~/.linuxbrew/bin/brew shellenv)
test -d /home/linuxbrew/.linuxbrew && eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv)
test -d /opt/homebrew/ && eval $(/opt/homebrew/bin/brew shellenv)

[ -f ~/.fzf.bash ] && source ~/.fzf.bash

if type brew &>/dev/null; then
    # LANG=ja_JP.UTF-8の状態で補完するためのファイルを読み込むと、setlocaleのエラーが出る場合がある
    # そのため、ファイルを読み込む前後はLANG=Cとする
    BACKUP_LANG=${LANG}
    LANG=C

    HOMEBREW_PREFIX="$(brew --prefix)"
    if [[ -r "${HOMEBREW_PREFIX}/etc/profile.d/bash_completion.sh" ]]; then
        source "${HOMEBREW_PREFIX}/etc/profile.d/bash_completion.sh"
    fi

    for COMPLETION in "${HOMEBREW_PREFIX}/etc/bash_completion.d/"*; do
        [[ -r "${COMPLETION}" ]] && source "${COMPLETION}"
    done
    unset COMPLETION

    unset HOMEBREW_PREFIX

    LANG=${BACKUP_LANG}
    unset BACKUP_LANG
fi

if type rustc &>/dev/null; then
    source "$(rustc --print sysroot)/etc/bash_completion.d/cargo"
fi

if type git &>/dev/null; then
    # gitの補完はbrewでインストールした場合は他の補完を有効にするときに一緒に有効になる
    # そのため、ここではbrewのgitの補完は有効にしない
    # brewでインストールしていない場合でもUbuntuでは補完が有効になるが、RHEL系では有効にならない
    # そのため、gitの補完が無効のときは有効にする
    # 有効・無効の判定は`__git`が関数として定義されているかどうかとする
    if [ "$(type -t __git)" != "function" ]; then
        if [ -r /usr/share/bash-completion/completions/git ]; then
            source /usr/share/bash-completion/completions/git
        fi
    fi
fi

shopt -s autocd      # cdコマンドに引数がないときに、カレントディレクトリを表示する
shopt -s cdable_vars # cdコマンドに変数名を指定できるようにする
shopt -s cdspell     # cdコマンドの引数が間違っているときに、正しい候補を表示する
shopt -s dirspell    # ディレクトリ名のスペルミスを訂正する
shopt -s globstar    # `**`を使って再帰的にマッチングできるようにする

# Ctrl+Rで履歴をさかのぼって進みすぎたときにCtrl+Sで戻れるようにする
# 普通はCtrl+Sは出力停止に割り当てられているので、それを解除する
# ついでに、Ctrl+Qは出力再開に割り当てられていて出力停止の解除に伴い使わなくなるので、それも解除する
# fzfをインストールしているときは意味がないけど、インストールしていないときのために設定する
if [[ -t 0 ]]; then # 標準入力が端末のときだけ実行する(scpなどで実行されたときにエラーになるのを防ぐ)
    stty stop undef
    stty start undef
fi

if [[ -r "${DOTFILES_DIRECTORY}/bashrc.d" ]]; then
    for FILE in "${DOTFILES_DIRECTORY}/bashrc.d"/*; do
        [[ -r "${FILE}" ]] && source "${FILE}"
    done
    unset FILE
fi

# 標準出力が端末でないときに下記の処理を実行すると`bind: warning: line editing not enabled`が発生するため、
# 標準出力が端末のときだけ実行する
# 多分上で処理している `[[ -t 0 ]]` でもいいけど、参考にしたサイトが`[[ -t 1 ]]`なので念のため同じにしている
if [[ -t 1 ]]; then
    bind -f "${DOTFILES_DIRECTORY}/.inputrc"
fi
