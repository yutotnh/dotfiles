#!/bin/bash

set -eu

# yumやaptだと管理者権限が必要なので、Homebrewをインストールする
# 参考: https://docs.brew.sh/Installation#unattended-installation
NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

test -d ~/.linuxbrew && eval $(~/.linuxbrew/bin/brew shellenv)
test -d /home/linuxbrew/.linuxbrew && eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv)

brew bundle --no-lock

# To install useful key bindings and fuzzy completion:
$(brew --prefix)/opt/fzf/install --all

script_directory="$(dirname "$(realpath "${BASH_SOURCE:-0}")")"

if [[ -r "${HOME}/.bashrc" ]]; then

    if grep -qF "[[ -r \"${script_directory}/bashrc.sh\" ]] && source \"${script_directory}/bashrc.sh\"" "${HOME}/.bashrc"; then
        # 既にbashrcを読む処理が追加されているのでスキップ
        :
    else
        cat <<EOF >>${HOME}/.bashrc
[[ -r "${script_directory}/bashrc.sh" ]] && source "${script_directory}/bashrc.sh"
EOF
    fi

fi
