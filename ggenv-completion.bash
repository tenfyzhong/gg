#!/usr/bin/env bash

_ggenv_complete() {
    local cur opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"

    case "$COMP_CWORD" in
        1)
            opts="-h --help"
            ;;
        *)
            opts=$(gg ls)
            ;;
    esac


    COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
    return 0
}

complete -F _ggenv_complete ggenv
