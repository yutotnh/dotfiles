#!/bin/bash

set -eu

if type brew &>/dev/null && [[ -x $(brew --prefix)/opt/fzf/uninstall ]]; then
    $(brew --prefix)/opt/fzf/uninstall
fi

SCRIPT_DIRECTORY="$(dirname "$(realpath "${BASH_SOURCE:-0}")")"

if [ -r "${HOME}/.bashrc" ]; then
    BASHRC_SH_LINE_NO=$(grep -nF "[[ -r \"${SCRIPT_DIRECTORY}/bashrc.sh\" ]] && source \"${SCRIPT_DIRECTORY}/bashrc.sh\"" "${HOME}/.bashrc" | sed -e 's/:.*//g')
    sed -i "${BASHRC_SH_LINE_NO}d" "${HOME}/.bashrc"
fi

NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"
