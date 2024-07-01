#!/usr/bin/env bash

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
# カレントディレクトリ以下の今日以前で最も今日に近いISO 8601の日付形式のディレクトリ名を返す
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
            break
        fi
    done

    # 今日以前で最も今日に近い日付のディレクトリがない場合は標準出力に何も出力しない
    # 標準エラー出力にエラーメッセージを出力する
    echo "No directory found." >&2
}
