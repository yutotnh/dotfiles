#!/usr/bin/env bash

set -eu

if ! type curl &>/dev/null; then
    echo "cURL is required for installation."
    echo "Please make cURL available."
    exit 1
fi

SCRIPT_DIRECTORY="$(dirname "$(realpath "${BASH_SOURCE:-0}")")"

# nix.confをdotfiles内で管理する
# rootで実行しているとき、bashの${HOME}(例: コンテナだと/github/home)と、
# nixが設定ファイルの検索に使うホームディレクトリ(passwdの/root)がずれることがあるため、
# ${HOME}を経由しないNIX_USER_CONF_FILESで直接ファイルを指定する
export NIX_USER_CONF_FILES="${SCRIPT_DIRECTORY}/nix/nix.conf"

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
        if [[ "$(id -u)" -eq 0 ]] && [[ ! -e /nix ]]; then
            mkdir -m 0755 /nix
            chown root /nix
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
# @brief nix/flake.nix に記載しているコマンド一式をインストールする(既にインストール済みなら最新化する)
# Nix 2.34 では nix profile の各サブコマンドの位置引数が正規表現ではなく「要素名」として
# 解釈されるようになったため、要素名とflake URLを nix profile list から取り出して扱う
# nix profile list はパイプに繋いでも(NIX_USER_CONF_FILESやNO_COLORに関わらず)色を付けるため、
# ANSIエスケープを除去してから解析する
DOTFILES_PROFILE_ELEMENTS="$(nix profile list 2>/dev/null | awk -v dir="${SCRIPT_DIRECTORY}" '
    { gsub(/\033\[[0-9;]*m/, "") }
    /^Name:/ { name = $2 }
    /^Original flake URL:/ && index($0, dir) { print name, $4 }
')"

# 更新すべき要素と、入れ直しが必要な古いプロファイルを仕分ける
CURRENT_ELEMENTS=""
LEGACY_ELEMENTS=""
while read -r ELEMENT_NAME ELEMENT_URL; do
    [[ -z "${ELEMENT_NAME}" ]] && continue

    if [[ "${ELEMENT_URL}" == *"?dir=nix"* ]]; then
        CURRENT_ELEMENTS+="${ELEMENT_NAME} "
    else
        # flake.nix をリポジトリルートから nix/ へ移動する前にインストールしたプロファイルは
        # 現存しないルートの flake.nix を参照しており upgrade できないため、削除して入れ直す
        LEGACY_ELEMENTS+="${ELEMENT_NAME} "
    fi
done <<<"${DOTFILES_PROFILE_ELEMENTS}"

if [[ -n "${LEGACY_ELEMENTS}" ]]; then
    # 要素名は空白を含まないため、意図的に単語分割させて複数要素を渡す
    # shellcheck disable=SC2086
    nix profile remove ${LEGACY_ELEMENTS}
fi

if [[ -n "${CURRENT_ELEMENTS}" ]]; then
    # --all では利用者が自分で `nix profile install` した無関係なパッケージまで更新して
    # しまうため、このdotfilesが入れた要素だけを名前で指定して更新する
    # shellcheck disable=SC2086
    nix profile upgrade ${CURRENT_ELEMENTS}
else
    nix profile install "${SCRIPT_DIRECTORY}/nix#default"
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
