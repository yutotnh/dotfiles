#!/usr/bin/env bash

SCRIPT_DIRECTORY="$(dirname "$(realpath "${BASH_SOURCE:-0}")")"

# nix.confをdotfiles内で管理する
export NIX_USER_CONF_FILES="${SCRIPT_DIRECTORY}/nix/nix.conf"

# Nix の PATH を通す(非ログインシェルでは~/.bashrcを経由しないため必要)
#   single-user
[[ -r "${HOME}/.nix-profile/etc/profile.d/nix.sh" ]] && source "${HOME}/.nix-profile/etc/profile.d/nix.sh"
#   multi-user(daemon)
[[ -r /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]] && source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh

if type nix &>/dev/null; then
    # Nix 2.34 では nix profile remove の位置引数が flake URL ではなく「要素名」として
    # 解釈されるようになったため、要素名を nix profile list から取り出して渡す
    # nix profile list はパイプに繋いでも色を付けるため、ANSIエスケープを除去してから解析する
    DOTFILES_PROFILE_ELEMENTS="$(nix profile list 2>/dev/null | awk -v dir="${SCRIPT_DIRECTORY}" '
        { gsub(/\033\[[0-9;]*m/, "") }
        /^Name:/ { name = $2 }
        /^Original flake URL:/ && index($0, dir) { print name }
    ')"

    if [[ -n "${DOTFILES_PROFILE_ELEMENTS}" ]]; then
        # 要素名は空白を含まないため、意図的に単語分割させて複数要素を渡す
        # shellcheck disable=SC2086
        nix profile remove ${DOTFILES_PROFILE_ELEMENTS} || true
    fi
fi

if [ -r "${HOME}/.bashrc" ]; then
    BASHRC_SH_LINE_NO=$(grep -nF "[[ -r \"${SCRIPT_DIRECTORY}/bashrc.sh\" ]] && source \"${SCRIPT_DIRECTORY}/bashrc.sh\"" "${HOME}/.bashrc" | sed -e 's/:.*//g')
    if [[ "${BASHRC_SH_LINE_NO}" =~ ^[0-9]+$ ]] && [[ "${BASHRC_SH_LINE_NO}" -gt 0 ]]; then
        sed -i "${BASHRC_SH_LINE_NO}d" "${HOME}/.bashrc"
    fi
fi

##
# @brief Nix 本体をアンインストールする
# install.sh は macOS は multi-user(daemon)、それ以外(Linux)はsingle-userでインストールするため、
# それぞれに対応したアンインストール手順を実行する
# 参考: https://nix.dev/manual/nix/stable/installation/uninstall
if [[ "$(uname)" == "Darwin" ]]; then
    if [[ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
        sudo launchctl unload /Library/LaunchDaemons/org.nixos.nix-daemon.plist 2>/dev/null || true
        sudo rm -f /Library/LaunchDaemons/org.nixos.nix-daemon.plist
        sudo launchctl unload /Library/LaunchDaemons/org.nixos.darwin-store.plist 2>/dev/null || true
        sudo rm -f /Library/LaunchDaemons/org.nixos.darwin-store.plist

        sudo dscl . -delete /Groups/nixbld 2>/dev/null || true
        dscl . -list /Users 2>/dev/null | grep '_nixbld' | while read -r NIXBLD_USER; do
            sudo dscl . -delete "/Users/${NIXBLD_USER}"
        done

        sudo sed -i '' '/\/nix apfs/d' /etc/fstab 2>/dev/null || true
        sudo diskutil apfs deleteVolume /nix 2>/dev/null || true

        [[ -e /etc/zshrc.backup-before-nix ]] && sudo mv /etc/zshrc.backup-before-nix /etc/zshrc
        [[ -e /etc/bashrc.backup-before-nix ]] && sudo mv /etc/bashrc.backup-before-nix /etc/bashrc
        [[ -e /etc/bash.bashrc.backup-before-nix ]] && sudo mv /etc/bash.bashrc.backup-before-nix /etc/bash.bashrc

        sudo rm -rf /etc/nix /nix
    fi
else
    # CIのコンテナ環境ではrootユーザーで実行しており、sudoコマンドが存在しない場合があるため、
    # rootユーザーで実行しているときはsudoを使わないようにする
    SUDO=()
    if [[ "$(id -u)" -ne 0 ]]; then
        SUDO=(sudo)
    fi

    "${SUDO[@]}" rm -rf /nix

    # /nix以下にあるNix自身が提供するrm等のコマンドをsudo無しで直接実行していた場合、
    # bashがコマンドのパスを覚えて(hashして)いるため、/nixを削除した直後に同じコマンドを
    # 実行すると「No such file or directory」になることがある
    # そのため、hashをクリアしてPATHから再解決させる
    hash -r
fi

rm -rf "${HOME}/.nix-profile" "${HOME}/.nix-defexpr" "${HOME}/.nix-channels" "${HOME}/.config/nix" "${HOME}/.cache/nix" "${HOME}/.local/state/nix" "${HOME}/.local/share/nix"
