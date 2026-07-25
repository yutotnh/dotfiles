#!/usr/bin/env bash

#
# @brief mkdir と cd を同時に行う関数
#
# 例:
# $ pwd
# /home/user
# $ ls
# $ mkcd test
# $ pwd
# /home/user/test
function mkcd() {
    # cdするので受け取る引数は1つだけ
    if [ $# -ne 1 ]; then
        echo "Usage: mkcd DIRECTORY"
        return 1
    fi
    mkdir -p "${1}" && cd "${1}" || return
}

#
# @brief 与えられたパスがファイルならその親ディレクトリに移動する
#                        ディレクトリならそのディレクトリに移動する
#
# @param $1 パス
#
# 例
# $ pwd
# /home/user
# $ ls
# $ cd-foolish test
# $ pwd
# /home/user/test
# $ cd -
# $ pwd
# /home/user
# $ cd-foolish test/test.txt
# $ pwd
# /home/user/test
function cd-foolish() {
    # 引数が1つでない場合はエラーメッセージを出力して終了
    if [ $# -ne 1 ]; then
        echo "Usage: cd-foolish PATH"
        return 1
    fi

    # 引数がファイルならそのファイルの親ディレクトリに移動
    if [ -f "$1" ]; then
        cd "$(dirname "$1")" || return
    # それ以外の場合は単に引数のディレクトリに移動
    # elseにすることで、ファイルでもディレクトリでもない場合などのエラーハンドリングもcdに任せる
    else
        cd "$1" || return
    fi
}

#
# @brief OSC 52 escape sequenceを使って標準入力をクリップボードにコピーする
#
# ローカルにクリップボード操作コマンド(xclip/wl-copy/pbcopy等)が無い環境や、
# SSHで接続している場合(WSLの`clip.exe`のようにサーバー側のクリップボードにコピーする
# 手段では、接続元のクリップボードに届かない)でも、OSC 52に対応した端末であれば
# 接続元のクリップボードにコピーできる
#
# 例:
# $ echo -n "hello" | clip
function clip() {
    if ! type base64 &>/dev/null; then
        echo "clip: base64 command not found" >&2
        return 1
    fi

    local data
    data=$(base64 | tr -d '\n')

    if [ -n "${TMUX:-}" ]; then
        # tmux配下だとOSC 52がtmux自身に消費されてしまうため、DCSでパススルーする
        # 参考: https://github.com/tmux/tmux/wiki/Clipboard
        # shellcheck disable=SC1003 # 末尾の\\は printf に渡すエスケープシーケンス(ST)の一部であり、シングルクォートのエスケープではない
        printf '\033Ptmux;\033\033]52;c;%s\a\033\\' "${data}" >/dev/tty
    else
        printf '\033]52;c;%s\a' "${data}" >/dev/tty
    fi
}

#
# @brief EUC-JPのテキストをUTF-8に変換して標準出力に出力する
#
# VS Codeの統合ターミナル(xterm.js)はUTF-8デコード固定で、端末側のエンコーディングを
# 変更する設定が存在しない。そのためEUC-JPのファイルをそのまま`cat`すると文字化けする
#
# 変換にnkfではなくiconvを使うのは、`nkf -w`が半角カナを勝手に全角化してしまい
# (`ﾃﾞｰﾀ`が`データ`になる)、元のテキストに忠実な変換にならないため
#
# @param $@ EUC-JPのファイル(省略した場合は標準入力を変換する)
#
# 例:
# $ euc-cat euc.txt
# $ cat euc.txt | euc-cat
function euc-cat() {
    if ! type iconv &>/dev/null; then
        echo "euc-cat: iconv command not found" >&2
        return 1
    fi

    # 引数が無い場合は標準入力をそのままiconvに処理させる
    if [ $# -eq 0 ]; then
        iconv -f EUC-JP -t UTF-8
        return
    fi

    local file
    for file in "$@"; do
        # `-`始まりのファイル名をオプションと解釈させないため`--`で区切る
        iconv -f EUC-JP -t UTF-8 -- "${file}" || return
    done
}

#
# @brief EUC-JPで入出力する対話型アプリをluitで包んで実行する
#
# luitは擬似端末を挟んでアプリの入出力をUTF-8と指定エンコーディングの間で双方向に変換する。
# そのため`euc-cat`のような一方向の変換では扱えない対話型アプリ(エディタやページャなど)でも
# 文字化けせずに使える
#
# @param $1 実行するコマンド
# @param $@ コマンドに渡す引数
#
# 例:
# $ euc-run vim euc.txt
# $ euc-run less euc.txt
function euc-run() {
    if [ $# -eq 0 ]; then
        echo "Usage: euc-run CMD [ARGS...]"
        return 1
    fi

    if ! type luit &>/dev/null; then
        echo "euc-run: luit command not found" >&2
        echo "euc-run: luit is included in nix/flake.nix of this dotfiles. Run ./install.sh to install it" >&2
        return 1
    fi

    luit -encoding EUC-JP -- "$@"
}

#
# @brief カレントディレクトリ以下の今日以前で最も今日に近いISO 8601の日付形式のディレクトリ名を返す
#
# 例1: 今日の日付のディレクトリがない場合
# $ ls
# 2024-03-04  2024-06-03  2024-07-03
# $ date --iso-8601
# 2024-07-01
# $ _find_previous_near_date_directory
# 2024-06-03
#
# 例2: 今日の日付のディレクトリがある場合
# $ ls
# 2024-03-04  2024-06-03  2024-07-03  2024-07-01
# $ date --iso-8601
# 2024-07-01
# $ _find_previous_near_date_directory
# 2024-07-01
function _find_previous_near_date_directory() {
    # 本関数で使用する全ての変数のスコープを関数内に限定する
    local today
    local date_dir_list=()
    local date_dir
    local sorted_date_dir_list

    today=$(date --iso-8601)

    # 日付形式のディレクトリのみを取得する
    for date_dir in *; do
        if [[ ! -d "${date_dir}" ]]; then
            continue
        fi

        if [[ ! "${date_dir}" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
            continue
        fi

        date_dir_list+=("${date_dir}")
    done

    # 日付の大きい順にソートする
    mapfile -t sorted_date_dir_list < <(echo "${date_dir_list[@]}" | tr ' ' '\n' | sort -r)

    for date_dir in "${sorted_date_dir_list[@]}"; do
        # 比較するために、日付のフォーマットを変換する
        local normalized_date_dir=${date_dir//-/}
        local normalized_today=${today//-/}
        # 日付の大きい順にソートしているので、数値の大小で比較し、同じか小さい場合にそのディレクトリを返す
        if [[ "${normalized_date_dir}" -le "${normalized_today}" ]]; then
            echo "${date_dir}"
            return
        fi
    done

    # 今日以前で最も今日に近い日付のディレクトリがない場合は標準出力に何も出力しない
    # 標準エラー出力にエラーメッセージを出力する
    echo "No directory found." >&2
}
