export gg_repo=$(pwd)

setup() {
    export temp=$(mktemp -d)
    export HOME="$temp"
    export sdkpath="$HOME/sdk"
    echo "HOME:$HOME"
    echo "sdkpath:$sdkpath"
    mkdir -p "$sdkpath"
    mkdir -p "$sdkpath/go1.18"
    mkdir -p "$HOME/bin"
    export PATH=$HOME/bin:$gg_repo:$PATH
    touch $HOME/bin/direnv
    chmod +x $HOME/bin/direnv
    export project=$(mktemp -d)
    cd $project
}

teardown() {
    if [ -n "$temp" ]; then
        rm -rf "$temp"
    fi
    unset sdkpath
    unset HOME
    unset temp
}


@test 'ggenv -t' {
    expect=$(cat <<'EOF'
ggenv: set go version to .envrc and direnv allow
Usage: ggenv [version]

Options:
  -h/--help         print this help message
EOF
)
    run ggenv -t
    [ "$status" -eq 1 ]
    [ "$output" = "$expect" ]
}

@test 'test help' {
    expect=$(cat <<'EOF'
ggenv: set go version to .envrc and direnv allow
Usage: ggenv [version]

Options:
  -h/--help         print this help message
EOF
)
    run ggenv -h
    [ "$status" -eq 0 ]
    [ "$output" = "$expect" ]
}

@test 'no arg' {
    expect=$(cat <<'EOF'
ggenv: set go version to .envrc and direnv allow
Usage: ggenv [version]

Options:
  -h/--help         print this help message
EOF
)
    run ggenv
    [ "$status" -eq 2 ]
    [ "$output" = "$expect" ]
}

@test 'ggenv no exist' {
    expect='ggenv: go version 1.17 not exist, please install it first'
    run ggenv 1.17
    [ "$status" -eq 3 ]
    [ "$output" = "$expect" ]
}

@test 'succ' {
    run ggenv 1.18
    [ "$status" -eq 0 ]
    [ -f "$project/.envrc" ]
}
