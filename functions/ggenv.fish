function ggenv
    argparse -X 1 'h/help' -- $argv 2>/dev/null
    if test $status -ne 0
        _ggenv_help >&2
        return 1
    end

    if set -q _flag_help
        _ggenv_help
        return 0
    end

    if test (count $argv) -ne 1
        _ggenv_help >&2
        return 2
    end

    set -l v $argv[1]

    if test ! -d $HOME/sdk/go$v
        echo "ggenv: go version $v not exist, please install it first" >&2
        return 3
    end

    gg use -b $v > .envrc && direnv allow
end

function _ggenv_help
    printf %s\n \
        'ggenv: set go version to .envrc and direnv allow' \
        'Usage: ggenv [version]' \
        '' \
        'Options:' \
        '  -h/--help                print this help message'
end
