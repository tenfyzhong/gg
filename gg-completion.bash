#! /bin/bash

_gg_complete_submodule() {
    if [[ $# -ne 1 ]]; then
        return
    fi

    case $1 in
        ls)
            echo '-h --help'
            ;;
        ls-remote)
            echo '-h --help'
            ;;
        install)
            output=$(gg ls-remote)
            echo "$output"
            ;;
        remove)
            output=$(gg ls)
            echo "$output"
            ;;
        use)
            output=$(gg ls)
            echo "$output"
            ;;
        -h|--help)
            return
            ;;
    esac
}

_gg_complete() {
    local opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"

    case "$COMP_CWORD" in
        1)
            opts="ls ls-remote install remove use -h --help"
            ;;
        2)
            opts=$(_gg_complete_submodule "${COMP_WORDS[1]}")
            ;;
    esac

    COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
    return 0
}

complete -F _gg_complete gg
