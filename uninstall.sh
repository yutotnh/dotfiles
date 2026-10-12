#!/usr/bin/env bash

# 注意: Linuxでは/nix以下を、macOSではNixのdaemonとボリュームを丸ごと削除する
#       本dotfiles以外の用途でNixを使っている環境では実行しないこと
SCRIPT_DIRECTORY="$(dirname "$(realpath "${BASH_SOURCE:-0}")")"

# nix.confをdotfiles内で管理する
export NIX_USER_CONF_FILES="${SCRIPT_DIRECTORY}/nix/nix.conf"

# Nix の PATH を通す(非ログインシェルでは~/.bashrcを経由しないため必要)
#   single-user
[[ -r "${HOME}/.nix-profile/etc/profile.d/nix.sh" ]] && source "${HOME}/.nix-profile/etc/profile.d/nix.sh"
#   multi-user(daemon)
[[ -r /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]] && source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh

if type nix &>/dev/null; then
    if nix profile list 2>/dev/null | grep -qF "${SCRIPT_DIRECTORY}"; then
        nix profile remove "${SCRIPT_DIRECTORY}/nix#default" || true
    fi
fi

if [ -r "${HOME}/.bashrc" ]; then
    BASHRC_HOOK="[[ -r \"${SCRIPT_DIRECTORY}/bashrc.sh\" ]] && source \"${SCRIPT_DIRECTORY}/bashrc.sh\""

    # GNU sedとBSD sedで`sed -i`の引数の渡し方が異なり、macOSでは失敗するため、sedを使わずにgrepで該当行を除く
    # grepは出力が0行のときに終了コード1を返すが、これは正常(.bashrcがフックのみだった場合)なので許容する
    # 終了コード2以上のときは.bashrcを上書きしない(読み込みエラーで.bashrcを空にしないため)
    BASHRC_TMP="$(mktemp)"
    GREP_STATUS=0
    grep -vxF "${BASHRC_HOOK}" "${HOME}/.bashrc" >"${BASHRC_TMP}" || GREP_STATUS=$?
    if [[ "${GREP_STATUS}" -le 1 ]]; then
        # mvではなくcatで上書きすることで、.bashrcがシンボリックリンクでもリンクを壊さない
        cat "${BASHRC_TMP}" >"${HOME}/.bashrc"
    fi
    rm -f "${BASHRC_TMP}"
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
