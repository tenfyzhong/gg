function direnv
end

set -gx HOME (command mktemp -d)
mkdir -p $HOME/sdk
mkdir -p $HOME/sdk/go1.18

set -gx cwd (command mktemp -d)
cd $cwd

@test 'ggenv -t, status' (ggenv -t) $status -eq 1
@test 'ggenv -t' (ggenv -t 2>&1 | string collect) = 'ggenv: set go version to .envrc and direnv allow
Usage: ggenv [version]

Options:
  -h/--help                print this help message'

@test 'ggenv help' (ggenv -h | string collect) = 'ggenv: set go version to .envrc and direnv allow
Usage: ggenv [version]

Options:
  -h/--help                print this help message'

@test 'ggenv no arg, status' (ggenv) $status -eq 2
@test 'ggenv no arg' (ggenv 2>&1 | string collect) = 'ggenv: set go version to .envrc and direnv allow
Usage: ggenv [version]

Options:
  -h/--help                print this help message'

@test 'ggenv no exist' (ggenv 1.17) $status -eq 3
@test 'ggenv no exist' (ggenv 1.17 2>&1) = 'ggenv: go version 1.17 not exist, please install it first'

@test 'succ' (ggenv 1.18) $status -eq 0
@test 'check .envrc' -f .envrc


rm -rf $HOME
rm -rf $cwd
