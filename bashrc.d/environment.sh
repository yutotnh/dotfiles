#!/usr/bin/env bash

if type starship &>/dev/null; then
    # VSCodeのシェル統合を利用中に再度`eval "$(starship init bash)"`を行うと、無限ループしてしまう
    # そのため`eval "$(starship init bash)"`の実行は一度だけにしたい
    # `eval "$(starship init bash)"` を実行すると環境変数STARSHIP_CMD_STATUSが定義されるので、それの有無から実行の可否を決める
    if [ ! -v STARSHIP_CMD_STATUS ]; then
        eval "$(starship init bash)"
        export STARSHIP_CONFIG="${DOTFILES_DIRECTORY}/starship.toml"
    fi
else
    # starshipがインストールされていないときは、プロンプトをある程度カスタマイズする
    # モチベーションは直前のコマンドの終了ステータス(成功か失敗か)を常に把握したいため

    _reset="$(tput sgr0)"
    _red="$(tput setaf 1)"
    _green="$(tput setaf 2)"
    _blue="$(tput setaf 4)"

    # 直前のコマンドの終了ステータスを表示する
    # 本当は$の色を変えたいけれど履歴を遡ると表示がおかしくなるため、1行目に終了コードを表示する
    # 0: 緑、それ以外: 赤
    # 出力: "(終了コード)"
    function _prompt_color() {
        local status=${?}
        local color
        if [ ${status} -eq 0 ]; then
            color=${_green}
        else
            color=${_red}
        fi

        echo -n "${color}"
    }

    # 以下のようなプロンプトにする
    #                     # 直前のコマンドとプロンプトの境目がわかりやすいように空行を入れる
    #   user@host 2000-01-01T00:00:00
    #   full_path
    #   $
    export PS1='\n${_green}\u${_reset}@${_green}\h${_reset} \D{%Y-%m-%dT%H:T%M:%S}\n${_blue}\w${_reset}\n$(_prompt_color)\$${_reset} '
fi

if type zoxide &>/dev/null; then
    eval "$(zoxide init bash)"
fi

export HISTFILESIZE=100000
export HISTSIZE=100000
# 履歴に時刻を表示する
export HISTTIMEFORMAT='%F %T '
# 空白から始まるコマンドと連続する重複するコマンドを履歴に追加しない
export HISTCONTROL=ignoreboth
# 本dotfilesを読み込まずHISTSIZEがデフォルト値になったとき、~\/.bash_historyが上書きされて過去の履歴が消えるのを防ぐために、
# 本dotfilesを読み込んだときは別の場所に.bash_historyを作成する
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
    # shellcheck disable=SC2016
    export FZF_HEADER='echo ${USER} in ${HOSTNAME} in ${PWD}'
    if type fd &>/dev/null; then
        export FZF_DEFAULT_COMMAND="${FZF_HEADER}; fd --type f --hidden --exclude .git"
    else
        export FZF_DEFAULT_COMMAND="${FZF_HEADER}; find . -type f -not -path '*/\.git/*'"
    fi
    export FZF_DEFAULT_OPTS='--no-height --border none --preview-window border-left --header-lines 1 --reverse --no-mouse'

    export FZF_CTRL_T_COMMAND="${FZF_DEFAULT_COMMAND}"
    if type bat &>/dev/null; then
        if type lv &>/dev/null; then
            export FZF_CTRL_T_OPTS='--bind "ctrl-/:change-preview-window(hidden|)" --preview "lv {} | bat --style=numbers --color=always --line-range :500 --file-name {}"'
        else
            export FZF_CTRL_T_OPTS='--bind "ctrl-/:change-preview-window(hidden|)" --preview "bat --style=numbers --color=always --line-range :500 {}"'
        fi
    else
        if type lv &>/dev/null; then
            export FZF_CTRL_T_OPTS='--preview "head -n 500 {} | lv"'
        else
            export FZF_CTRL_T_OPTS='--preview "head -n 500"'
        fi
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
        export FZF_DIR_PREVIEW="eza --icons --all --git-ignore --ignore-glob '.git' --long --no-filesize --no-user --no-permissions --tree --level 3 --time-style=iso --color always --group-directories-first"
    elif type tree &>/dev/null; then
        export FZF_DIR_PREVIEW="tree -C -L 3 -a -l --timefmt %F --dirsfirst --gitignore -I .git"
    else
        export FZF_DIR_PREVIEW="ls --almost-all -l --time-style=iso --no-group --color=always --group-directories-first"
    fi
    export FZF_ALT_C_OPTS="--preview '${FZF_DIR_PREVIEW} {}' --bind 'ctrl-/:change-preview-window(hidden|)'"
fi

if type vim &>/dev/null; then
    export MYVIMRC="${DOTFILES_DIRECTORY}/.vimrc"
    export VIMINIT="source ${MYVIMRC}"
fi

if type zoxide &>/dev/null; then
    if type fzf &>/dev/null; then
        export _ZO_FZF_OPTS="--preview-window border-left --reverse --exit-0 --bind 'ctrl-z:ignore,btab:up,tab:down,ctrl-/:change-preview-window(hidden|)' --preview '${FZF_DIR_PREVIEW} {2}'"
    fi
fi

if type git &>/dev/null; then
    export GIT_CONFIG_GLOBAL="${DOTFILES_DIRECTORY}/git/.gitconfig"
fi

# LANG=ja_JP.UTF-8が設定できる環境では、LANG=ja_JP.UTF-8を設定する
# `locale -a`で出てくる物は正規化されているので、UTF-8ではなくutf8になっている
if locale -a 2>/dev/null | grep -qF 'ja_JP.utf8'; then
    export LANG=ja_JP.UTF-8
fi
