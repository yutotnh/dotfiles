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

# 本当はHomebrewでGitをインストールして、そこの`git-completion.bash`を使いたい
# だけど、2022/12現在bash-completionとGit両方をbrewでインストールしようとしたらエラーが発生する
# そのため、解決するまでは `git-completion.bash`を直接ダウンロードして利用する
wget https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash
