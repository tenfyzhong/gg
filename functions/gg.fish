function gg -d 'golang version manager'
    argparse -s 'h/help' -- $argv 2>/dev/null

    if set -q _flag_help 
        _gg_help
        return 0
    end

    if test -z "$argv"
        _gg_help
        return 1
    end

    set -l subcommand $argv[1]
    set -l rest $argv[2..-1]
    switch $subcommand
        case ls
            __gg-ls $rest
        case ls-remote
            __gg-ls-remote $rest
        case install
            __gg-install $rest
        case remove
            __gg-remove $rest
        case use
            __gg-use $rest
    end
end

function __gg-ls -d 'list local version'
    argparse 'h/help' -- $argv 2>/dev/null

    if set -q _flag_help 
        _gg-ls_help
        return 0
    end

    if test ! -d (__gg_rootdir)
        return
    end
    set -l ds (ls (__gg_rootdir) | sort -V)
    __gg_helper_print $ds
end

function __gg-ls-remote -d 'list remote version'
    argparse 'h/help' 'f/force' -- $argv 2>/dev/null

    if set -q _flag_help 
        _gg-ls-remote_help
        return 0
    end

    set -l rootdir (__gg_rootdir)
    set cachefile $rootdir/.remote-cache
    if test ! -d $rootdir
        mkdir -p $rootdir
    end

    if set -q _flag_force; or test ! -f "$cachefile"; or test (math (date +%s)-(date +%s -r "$cachefile")) -gt 86400
        curl -sL go.dev/dl | sed -n -E 's/.*toggle(Visible)?" id="(go.*)">/\2/p' | sort -V | uniq > "$cachefile"
        echo "gotip" >> "$cachefile"
    end

    set -l ds (cat "$cachefile")
    __gg_helper_print $ds
end

function __gg-install -d 'install a specified version'
    argparse 'h/help' -- $argv 2>/dev/null

    if set -q _flag_help 
        _gg-install_help
        return 0
    end

    if test -z "$argv"
        _gg-install_help
        return 1
    end

    set -l rootdir (__gg_rootdir)
    for v in $argv
        echo "installing go$v ..."
        if test -d "$rootdir/go$v"
            continue
        end

        go install golang.org/dl/go$v@latest
        if test $status -ne 0
            echo "go install golang.org/dl/go$v@latest failed" >&2
            continue
        end
        go$v download
        if test $status -ne 0
            echo "go$v download failed" >&2
            continue
        end
    end
end

function __gg-remove -d 'remove specified version'
    argparse 'h/help' -- $argv 2>/dev/null

    if set -q _flag_help 
        _gg-remove_help
        return 0
    end

    if test -z "$argv"
        _gg-remove_help
        return 1
    end

    set -l rootdir (__gg_rootdir)
    for v in $argv
        rm -rf "$rootdir/go$v"
        rm -rf "$GOPATH/bin/go$v"
    end
end

function __gg-use -d 'print the specified version environment'
    argparse -X 1 'h/help' 'b/bash' 'z/zsh' 'f/fish' -- $argv 2>/dev/null

    if set -q _flag_help 
        _gg-use_help
        return 0
    end

    if test -z "$argv"
        _gg-use_help
        return 1
    end

    set -l v $argv[1]

    set -l rootdir (__gg_rootdir)
    if test ! -d $rootdir/go$v
        echo "# The version $v is not exist, please run the command below to install it first" >&2
        echo "gg install $v" >&2
        return 2
    end

    set s ''
    if set -q _flag_bash
        set s bash
    else if set -q _flag_zsh
        set s zsh
    else if set -q _flag_fish
        set s fish
    end

    set -l source_cmd 'gg'
    if test -n "$s"
        set source_cmd (printf 'gg use --%s %s' $s $v)
    else
        set source_cmd (printf 'gg use %s' $v)
    end

    if test -z "$s"
        set s $SHELL
    end

    if string match -r -q 'fish$' $s
        # set -g GOROOT (go1.14.12 env GOROOT)
        # fish_add_path $GOROOT/bin
        printf '# source this code to enable it\n'
        printf '# for example:\n'
        printf '# > %s | source\n' $source_cmd
        printf '\n'
        printf 'set -gx GOROOT (go%s env GOROOT)\n' $v
        printf 'fish_add_path $GOROOT/bin\n'
    else
        # export GOROOT=$(go1.14.12 env GOROOT)
        # export PATH=${GOROOT}/bin:$PATH
        printf '# source this code to enable it\n'
        printf '# for example:\n'
        printf '# > %s | source\n' $source_cmd
        printf '\n'
        printf '# if you use direnv to manage environment, you can redirect the output to .envrc in the current directory\n'
        printf '# > %s >> .envrc; direnv allow\n' $source_cmd
        printf '\n'
        printf 'export GOROOT=$(go%s env GOROOT)\n' $v
        printf 'export PATH=$GOROOT/bin:$PATH\n'
    end
end

function __gg_helper_print
    for d in $argv
        set -l v (string sub -s 3 $d)
        if test -z "$v"
            continue
        end
        echo $v
    end
end

function __gg_rootdir
    echo "$HOME/sdk"
end

function _gg_help
    printf %s\n \
        'gg: golang version manager' \
        'Usage: gg [options] <subcommand> [options] <args>' \
        '' \
        'Options:' \
        '  -h/--help         print this help message' \
        '' \
        'Subcommands:' \
        '  ls           list local version' \
        '  ls-remote    list remote version' \
        '  install      install specified version' \
        '  remove       remove specified version' \
        '  use          print the specified version environment'
end

function _gg-ls_help 
    printf %s\n \
        'gg ls: list local version' \
        'Usage: gg ls [options]' \
        '' \
        'Options:' \
        '  -h/--help    print this help message'
end

function _gg-ls-remote_help 
    printf %s\n \
        'gg ls-remote: list remote version, it will use the cache if the age of it less than 1 day' \
        'Usage: gg ls-remote [options]' \
        '' \
        'Options:' \
        '  -f/--force   force to update cache' \
        '  -h/--help    print this help message'
end

function _gg-install_help
    printf %s\n \
        'gg install: install specified version' \
        'Usage: gg install [options] <version...>' \
        '' \
        'Options:' \
        '  -h/--help    print this help message'
end

function _gg-remove_help
    printf %s\n \
        'gg remove: remove specified version' \
        'Usage: gg remove [options] <version...>' \
        '' \
        'Options:' \
        '  -h/--help    print this help message'
end

function _gg-use_help
    printf %s\n \
        'gg use: print the specified version environment' \
        'If no shell option provide, it will use the $SHELL as default' \
        'Usage: gg use [options] <version>' \
        '' \
        'Options:' \
        '  -b/--bash          print the bash environment' \
        '  -z/--zsh           print the zsh environment' \
        '  -f/--fish          print the fish environment' \
        '  -h/--help          print this help message' 
end

