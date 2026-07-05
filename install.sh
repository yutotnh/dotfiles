#!/usr/bin/env bash

set -eu

if ! type curl &>/dev/null; then
    echo "cURL is required for installation."
    echo "Please make cURL available."
    exit 1
fi

SCRIPT_DIRECTORY="$(dirname "$(realpath "${BASH_SOURCE:-0}")")"

# rootで実行しているとき、bashの${HOME}(例: コンテナだと/github/home)と、
# nixがnix.confの検索に使うホームディレクトリ(passwdの/root)がずれることがあるため、
# rootのときはユーザーごとの設定ではなく、システム全体の設定ファイルを使う
if [[ "$(id -u)" -eq 0 ]]; then
    NIX_CONF_FILE=/etc/nix/nix.conf
else
    NIX_CONF_FILE="${HOME}/.config/nix/nix.conf"
fi

# Nix の PATH を通す(既にインストール済みの場合、非ログインシェルでは~/.bashrcを経由しないため必要)
#   single-user
[[ -r "${HOME}/.nix-profile/etc/profile.d/nix.sh" ]] && source "${HOME}/.nix-profile/etc/profile.d/nix.sh"
#   multi-user(daemon)
[[ -r /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]] && source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh

##
# @brief Nix をインストールする
# 参考: https://nixos.org/download/
if ! type nix &>/dev/null; then
    if [[ "$(uname)" == "Darwin" ]]; then
        # macOSはAPFSの制約により、multi-user(daemon)インストールのみサポートされている
        sh <(curl -L https://nixos.org/nix/install) --daemon --yes
    else
        # コンテナやWSLではsystemdが無い場合があり、daemonを起動できないことがある
        # そのため、root権限だけで完結するsingle-userインストールを使う
        # CIのコンテナ環境ではrootユーザーで実行しており、sudoコマンドが存在しないことがある
        # single-userインストーラーはrootで実行していても/nixの作成にsudoを使おうとするため、
        # 事前にrootのまま/nixを作成しておくことでsudoを不要にする
        # また、rootでのsingle-userインストールは公式にはサポートされておらず、
        # 存在しないnixbldグループを要求してインストールに失敗するため、
        # build-users-groupを空にすることでnixbldグループを不要にする
        # 参考: https://github.com/NixOS/nix/issues/1559
        if [[ "$(id -u)" -eq 0 ]]; then
            if [[ ! -e /nix ]]; then
                mkdir -m 0755 /nix
                chown root /nix
            fi
            mkdir -p "$(dirname "${NIX_CONF_FILE}")"
            if ! grep -qF "build-users-group" "${NIX_CONF_FILE}" 2>/dev/null; then
                echo "build-users-group =" >>"${NIX_CONF_FILE}"
            fi
        fi
        sh <(curl -L https://nixos.org/nix/install) --no-daemon --yes
    fi

    # Nix の PATH を通す
    #   single-user
    [[ -r "${HOME}/.nix-profile/etc/profile.d/nix.sh" ]] && source "${HOME}/.nix-profile/etc/profile.d/nix.sh"
    #   multi-user(daemon)
    [[ -r /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]] && source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

##
# @brief flakes を有効化する
mkdir -p "$(dirname "${NIX_CONF_FILE}")"
if ! grep -qF "experimental-features = nix-command flakes" "${NIX_CONF_FILE}" 2>/dev/null; then
    echo "experimental-features = nix-command flakes" >>"${NIX_CONF_FILE}"
fi

##
# @brief flake.nix に記載しているコマンド一式をインストールする(既にインストール済みなら最新化する)
if nix profile list 2>/dev/null | grep -qF "${SCRIPT_DIRECTORY}"; then
    nix profile upgrade '.*'
else
    nix profile install "${SCRIPT_DIRECTORY}#default"
fi

##
# @brief Rust の環境をセットアップする
if type rustup-init &>/dev/null; then
    rustup-init -y
else
    echo "Can not setup Rust environment." >&2
fi

##
# @brief ~/.bashrcにbashrc.sh を読み込む処理を追加する
if [[ -r "${HOME}/.bashrc" ]]; then

    if grep -qF "[[ -r \"${SCRIPT_DIRECTORY}/bashrc.sh\" ]] && source \"${SCRIPT_DIRECTORY}/bashrc.sh\"" "${HOME}/.bashrc"; then
        # 既にbashrcを読む処理が追加されているのでスキップ
        :
    else
        cat <<EOF >>"${HOME}/.bashrc"
[[ -r "${SCRIPT_DIRECTORY}/bashrc.sh" ]] && source "${SCRIPT_DIRECTORY}/bashrc.sh"
EOF
    fi

fi
