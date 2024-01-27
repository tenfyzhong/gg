#!/usr/bin/env bash

_gg_complete_seen() {
    if [[ $# -lt 1 ]]; then
        return 0
    fi
    for v in "${COMP_WORDS[@]}"; do
        for a in "$@"; do
            if [ "$v" = "$a" ]; then
                return 0
            fi
        done
    done
    return 1
}

_gg_complete_submodule() {
    if [[ $# -ne 2 ]]; then
        return
    fi

    subcommand="$1"
    cur="$2"

    if _gg_complete_seen -h --help; then
        return
    fi

    case $subcommand in
        ls)
            echo '-h --help'
            ;;
        ls-remote)
            if _gg_complete_seen -f --force; then
                return
            else
                echo '-f --force -h --help'
            fi
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
            if _gg_complete_seen -b --bash -z --zsh -f --fish; then
                output=$(gg ls)
                echo "$output"
            elif [[ "$cur" = "-"* ]]; then
                echo '-b --bash -z --zsh -f --fish'
            else
                output=$(gg ls)
                echo "$output"
            fi
            ;;
        *)
            return
            ;;
    esac
}

_gg_complete() {
    local cur opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"

    case "$COMP_CWORD" in
        1)
            opts="ls ls-remote install remove use -h --help"
            ;;
        *)
            opts=$(_gg_complete_submodule "${COMP_WORDS[1]}" "$cur")
            ;;
    esac


    COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
    return 0
}

complete -F _gg_complete gg
