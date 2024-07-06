#!/usr/bin/env bash

#
# @brief lsのオプションを補完する関数
function _comp_complete_longopt_ls() {
    # 本当はlsと"$@"を組み合わせた形で補完を行いたいが、
    # completeの引数の仕様がよくわからないため、とりあえずlsのオプションのみを指定する
    # 不都合があれば、しっかりと調査して修正する
    _comp_complete_longopt ls
}

#
# @brief grepのオプションを補完する関数
function _comp_complete_longopt_grep() {
    # 本当はlsと"$@"を組み合わせた形で補完を行いたいが、
    # completeの引数の仕様がよくわからないため、とりあえずlsのオプションのみを指定する
    # 不都合があれば、しっかりと調査して修正する
    _comp_complete_longopt grep
}

#
# @brief 補完対象のエイリアスが存在する場合に補完を設定する関数
function complete() {
    local alias="${*: -1}"
    if ! type -t "${alias}" 2>/dev/null | grep -q '^alias$'; then
        return
    fi

    builtin complete "${@}"
}

# lsにエイリアスを設定しているエイリアスを補完する
complete -F _comp_complete_longopt_ls l
complete -F _comp_complete_longopt_ls la
complete -F _comp_complete_longopt_ls ll
complete -F _comp_complete_longopt_ls lt
complete -F _comp_complete_longopt_ls sl

# ezaにエイリアスを設定しているエイリアスを補完する
complete -o bashdefault -o filenames -F _eza e
complete -o bashdefault -o filenames -F _eza et

# grepにエイリアスを設定しているエイリアスを補完する
complete -F _comp_complete_longopt_grep g

unset -f complete
