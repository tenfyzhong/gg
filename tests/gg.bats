#!/usr/bin/env bats


setup_file() {
    if [ -z "$gg_repo" ]; then
        cwd=$(pwd)
        export gg_repo="$cwd"
    fi

    dir=$(realpath "$gg_repo")/tests
    if [ ! -d "$dir" ]; then
        exit 1
    fi

    export dlfile=$dir/data/dl.html
    export expect_cache_file=$dir/data/remote-cache
    export expect_version_output=$dir/data/version-output
}

teardown_file() {
    unset dlfile
    unset expect_cache_file
    unset expect_version_output
}

setup() {
    temp=$(mktemp -d)
    export HOME="$temp"
    export sdkpath="$HOME/sdk"
    echo "HOME:$HOME"
    echo "sdkpath:$sdkpath"
    mkdir -p "$sdkpath"
    mkdir -p "$HOME/bin"
    export PATH=$HOME/bin:$gg_repo:$PATH
}

teardown() {
    rm -rf "$HOME"
    unset sdkpath
    unset HOME
}

mock_curl() {
    status=
    stdout=
    while [[ $# -gt 0 ]]; do
        case $1 in 
            -s|--status)
                status=$2
                shift
                shift
                ;;
            --stdout)
                stdout=$2
                shift
                shift
                ;;
            *)
                return 1
                ;;
        esac
    done

    export curl_status=$status
    export curl_stdout=$stdout

cat << EOF > "$HOME"/bin/curl
$curl_stdout
exit \$curl_status
EOF
    chmod +x "$HOME"/bin/curl
}

demock_curl() {
    rm -f "$HOME"/bin/curl
    unset curl_status
    unset curl_stdout
}

mock_go() {
    while [[ $# -gt 0 ]]; do
        case $1 in 
            --status_install)
                export go_install_status=$2
                shift
                shift
                ;;
            --status_download)
                export go_download_status=$2
                shift
                shift
                ;;
            *)
                return 1
                ;;
        esac
    done

cat << 'EOF' > "$HOME"/bin/go
if [ "$go_install_status" -ne 0 ]; then 
    exit "$go_install_status" 
fi
pkg="$2"
v=$(echo "$pkg" | sed 's/golang\.org\/dl\/go\(.*\)@latest/\1/')
chmod +x $HOME/bin/go$v
echo "version:$v"

cat << EOFINLINE > "$HOME"/bin/go$v
if [ "\$go_download_status" -ne 0 ]; then
    exit "\$go_download_status"
fi
mkdir -p \$sdkpath/go$v
echo "downloading $v" 
EOFINLINE

chmod +x "$HOME"/bin/go$v

EOF
    chmod +x "$HOME"/bin/go
}

demock_go() {
    rm -f "$HOME"/bin/go
    for v in "$@"; do
        rm -f "$HOME"/bin/go"$v"
    done
}

@test 'ls-remote success' {
    mock_curl -s 0 --stdout 'cat $dlfile'
    mock_go --status_install 0 --status_download 0
    expect=$(cat "$expect_version_output")
    run gg ls-remote
    [ "$output" = "$expect" ]
    [ -f "$sdkpath"/.remote-cache ]
    expect_cache=$(cat "$expect_cache_file")
    actual_cache=$(cat "$sdkpath"/.remote-cache)
    [ "$actual_cache" = "$expect_cache" ]
}

@test 'ls remote force' {
    mock_curl -s 0 --stdout 'cat $dlfile'
    echo 'go1.16' > "$sdkpath"/.remote-cache
    run gg ls-remote
    [ "$output" = '1.16' ]

    expect=$(cat "$expect_version_output")
    run gg ls-remote -f
    [ "$output" = "$expect" ]
    [ -f "$sdkpath"/.remote-cache ]
    expect_cache=$(cat "$expect_cache_file")
    actual_cache=$(cat "$sdkpath"/.remote-cache)
    [ "$actual_cache" = "$expect_cache" ]
}

@test 'ls-remote use cache and curl failed' {
    mock_curl -s 1
    echo 'go1.16' > "$sdkpath"/.remote-cache
    run gg ls-remote
    [ "$output" = '1.16' ]
}

@test 'ls-remote cache expired' {
    mock_curl -s 0 --stdout 'cat $dlfile'
    echo 'go1.16' > "$sdkpath"/.remote-cache
    now=$(date +%s)
    twodayago=$((now-86400*2))
    format=$(date --date="@$twodayago" +%Y%m%d%H%M)
    touch -t "$format" "$sdkpath"/.remote-cache
    expect=$(cat "$expect_version_output")
    run gg ls-remote
    [ "$output" = "$expect" ]
    [ -f "$sdkpath"/.remote-cache ]
    expect_cache=$(cat "$expect_cache_file")
    actual_cache=$(cat "$sdkpath"/.remote-cache)
    [ "$actual_cache" = "$expect_cache" ]
}

@test 'ls-remote failed' {
    mock_curl -s 1
    run gg ls-remote
    [ "$output" = 'tip' ]
    [ -f "$sdkpath"/.remote-cache ]
    actual_cache=$(cat "$sdkpath"/.remote-cache)
    [ "$actual_cache" = "gotip" ]
}

@test 'install 1.16 success' {
    mock_go --status_install 0 --status_download 0
    gg install 1.16
    [ -d "$sdkpath"/go1.16 ]
}

@test 'reinstall 1.16' {
    mock_go --status_install 0 --status_download 0
    gg install 1.16
    gg install 1.16
    [ -d "$sdkpath"/go1.16 ]
}

@test 'install 1.16 1.18 tip success' {
    mock_go --status_install 0 --status_download 0
    gg install 1.16 1.18 tip
    [ -d "$sdkpath"/go1.16 ]
    [ -d "$sdkpath"/go1.18 ]
    [ -d "$sdkpath"/gotip ]
}

@test 'install 1.16 failed' {
    mock_go --status_install 1
    run gg install 1.16
    [[ "$output" == *"go install golang.org/dl/go1.16@latest failed"* ]]
    [ ! -d "$sdkpath"/go1.16 ]
}

@test 'download 1.16 failed' {
    mock_go --status_install 0 --status_download 1
    run gg install 1.16
    echo "output:$output"
    [[ "$output" == *"go1.16 download failed"* ]]
    [ ! -d "$sdkpath"/go1.16 ]
}

@test 'ls before any install' {
    run gg ls
    [ -z "$output" ]
}

@test 'ls after install' {
    mock_go --status_install 0 --status_download 0
    gg install 1.16
    run gg ls
    [[ "$output" = "1.16" ]]
    gg install 1.18
    gg install tip
    run gg ls
    expect=$(printf "1.16\n1.18\ntip")
    [[ "$output" = "$expect" ]]
}

@test 'remove' {
    run gg remove 1.16
    [ "$status" -eq 0 ]
    mock_go --status_install 0 --status_download 0
    gg install 1.16
    gg remove 1.16
    [ ! -d "$sdkpath"/go1.16 ]
    gg install 1.18 tip
    gg remove 1.18 tip
    [ ! -d "$sdkpath"/go1.18 ]
    [ ! -d "$sdkpath"/gotip ]
}

@test 'use not exist' {
    run gg use 1.16
    expect=$(printf "# The version 1.16 is not exist, please run the command below to install it first\ngg install 1.16")
    [ "$output" = "$expect" ]
}

@test 'use 1.16' {
    mock_go --status_install 0 --status_download 0
    gg install 1.16
    run gg use -b 1.16
    expect=$(cat <<'EOF'
# source this code to enable it
# for example:
# > gg use --bash 1.16 | source

# if you use direnv to manage environment, you can redirect the output to .envrc in the current directory
# > gg use --bash 1.16 >> .envrc; direnv allow

export GOROOT=$HOME/sdk/go1.16
export PATH=$GOROOT/bin:$PATH
EOF
)
    echo "output:$output"
    echo "expect:$expect"
    [ "$output" = "$expect" ]

    run gg use -z 1.16
    expect=$(cat <<'EOF'
# source this code to enable it
# for example:
# > gg use --zsh 1.16 | source

# if you use direnv to manage environment, you can redirect the output to .envrc in the current directory
# > gg use --zsh 1.16 >> .envrc; direnv allow

export GOROOT=$HOME/sdk/go1.16
export PATH=$GOROOT/bin:$PATH
EOF
)
    echo "output:$output"
    echo "expect:$expect"
    [ "$output" = "$expect" ]

    run gg use -f 1.16
    expect=$(cat <<'EOF'
# source this code to enable it
# for example:
# > gg use --fish 1.16 | source

set -gx GOROOT $HOME/sdk/go1.16
fish_add_path $GOROOT/bin
EOF
)
    echo "output:$output"
    echo "expect:$expect"
    [ "$output" = "$expect" ]

    export SHELL=bash
    run gg use 1.16
    expect=$(cat <<'EOF'
# source this code to enable it
# for example:
# > gg use 1.16 | source

# if you use direnv to manage environment, you can redirect the output to .envrc in the current directory
# > gg use 1.16 >> .envrc; direnv allow

export GOROOT=$HOME/sdk/go1.16
export PATH=$GOROOT/bin:$PATH
EOF
)
    echo "output:$output"
    echo "expect:$expect"
    [ "$output" = "$expect" ]

    export SHELL=zsh
    run gg use 1.16
    expect=$(cat <<'EOF'
# source this code to enable it
# for example:
# > gg use 1.16 | source

# if you use direnv to manage environment, you can redirect the output to .envrc in the current directory
# > gg use 1.16 >> .envrc; direnv allow

export GOROOT=$HOME/sdk/go1.16
export PATH=$GOROOT/bin:$PATH
EOF
)
    echo "output:$output"
    echo "expect:$expect"
    [ "$output" = "$expect" ]

    export SHELL=fish
    run gg use 1.16
    expect=$(cat <<'EOF'
# source this code to enable it
# for example:
# > gg use 1.16 | source

set -gx GOROOT $HOME/sdk/go1.16
fish_add_path $GOROOT/bin
EOF
)
    echo "output:$output"
    echo "expect:$expect"
    [ "$output" = "$expect" ]
}

@test 'test help' {
    run gg -h
    [ "$status" -eq 0 ]
    expect=$(cat <<'EOF'
gg: golang version manager
Usage: gg [options] <subcommand> [options] <args>

Options:
  -h/--help         print this help message

Subcommands:
  ls           list local version
  ls-remote    list remote version
  install      install specified version
  remove       remove specified version
  use          print the specified version environment
EOF
)
    echo "output:$output"
    echo "expect:$expect"
    [ "$output" = "$expect" ]

    run gg
    [ "$status" -eq 1 ]
    expect=$(cat <<'EOF'
gg: golang version manager
Usage: gg [options] <subcommand> [options] <args>

Options:
  -h/--help         print this help message

Subcommands:
  ls           list local version
  ls-remote    list remote version
  install      install specified version
  remove       remove specified version
  use          print the specified version environment
EOF
)
    echo "output:$output"
    echo "expect:$expect"
    [ "$output" = "$expect" ]

    run gg ls -h
    [ "$status" -eq 0 ]
    expect=$(cat <<'EOF'
gg ls: list local version
Usage: gg ls [options]

Options:
  -h/--help    print this help message
EOF
)
    echo "output:$output"
    echo "expect:$expect"
    [ "$output" = "$expect" ]

    run gg ls-remote -h
    [ "$status" -eq 0 ]
    expect=$(cat <<'EOF'
gg ls-remote: list remote version, it will use the cache if the age of it less than 1 day
Usage: gg ls-remote [options]

Options:
  -f/--force   force to update cache
  -h/--help    print this help message
EOF
)
    echo "output:$output"
    echo "expect:$expect"
    [ "$output" = "$expect" ]

    run gg install -h
    [ "$status" -eq 0 ]
    expect=$(cat <<'EOF'
gg install: install specified version
Usage: gg install [options] <version...>

Options:
  -h/--help    print this help message
EOF
)
    echo "output:$output"
    echo "expect:$expect"
    [ "$output" = "$expect" ]

    run gg install
    [ "$status" -eq 1 ]
    expect=$(cat <<'EOF'
gg install: install specified version
Usage: gg install [options] <version...>

Options:
  -h/--help    print this help message
EOF
)
    echo "output:$output"
    echo "expect:$expect"
    [ "$output" = "$expect" ]

    run gg remove -h
    [ "$status" -eq 0 ]
    expect=$(cat <<'EOF'
gg remove: remove specified version
Usage: gg remove [options] <version...>

Options:
  -h/--help    print this help message
EOF
)
    echo "output:$output"
    echo "expect:$expect"
    [ "$output" = "$expect" ]

    run gg remove
    [ "$status" -eq 1 ]
    expect=$(cat <<'EOF'
gg remove: remove specified version
Usage: gg remove [options] <version...>

Options:
  -h/--help    print this help message
EOF
)
    echo "output:$output"
    echo "expect:$expect"
    [ "$output" = "$expect" ]

    run gg use -h
    [ "$status" -eq 0 ]
    expect=$(cat <<'EOF'
gg use: print the specified version environment
If no shell option provide, it will use the $SHELL as default
Usage: gg use [options] <version>

Options:
  -b/--bash          print the bash environment
  -z/--zsh           print the zsh environment
  -f/--fish          print the fish environment
  -h/--help          print this help message
EOF
)
    echo "output:$output"
    echo "expect:$expect"
    [ "$output" = "$expect" ]

    run gg use
    [ "$status" -eq 1 ]
    expect=$(cat <<'EOF'
gg use: print the specified version environment
If no shell option provide, it will use the $SHELL as default
Usage: gg use [options] <version>

Options:
  -b/--bash          print the bash environment
  -z/--zsh           print the zsh environment
  -f/--fish          print the fish environment
  -h/--help          print this help message
EOF
)
    echo "output:$output"
    echo "expect:$expect"
    [ "$output" = "$expect" ]
}
