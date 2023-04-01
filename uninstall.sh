#!/usr/bin/env bash

if type brew &>/dev/null && [[ -x $(brew --prefix)/opt/fzf/uninstall ]]; then
    $(brew --prefix)/opt/fzf/uninstall
fi

SCRIPT_DIRECTORY="$(dirname "$(realpath "${BASH_SOURCE:-0}")")"

if [ -r "${HOME}/.bashrc" ]; then
    BASHRC_SH_LINE_NO=$(grep -nF "[[ -r \"${SCRIPT_DIRECTORY}/bashrc.sh\" ]] && source \"${SCRIPT_DIRECTORY}/bashrc.sh\"" "${HOME}/.bashrc" | sed -e 's/:.*//g')
    if [[ "${BASHRC_SH_LINE_NO}" =~ ^[0-9]+$ ]] && [[ "${BASHRC_SH_LINE_NO}" -gt 0 ]]; then
        sed -i "${BASHRC_SH_LINE_NO}d" "${HOME}/.bashrc"
    fi
fi

if type brew &>/dev/null; then
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"
fi
