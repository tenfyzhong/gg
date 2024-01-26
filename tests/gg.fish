set filename (status current-filename)
set dir (dirname (realpath $filename))
set dlfile $dir/data/dl.html
set expect_cache_file $dir/data/remote-cache
set expect_version_output $dir/data/version-output

function init
    argparse 't/title=' -- $argv
    if test -n "$_flag_title"
        @echo "====================$_flag_title===================="
    end

    set -gx temp (command mktemp -d)
    set -gx HOME $temp
    set -gx sdkpath $HOME/sdk
    mkdir -p $sdkpath
end

function deinit
    rm -rf $temp
    set -e temp
    set -e HOME
    set -e sdkpath
    echo ''
end

function mock_curl -d 'mock curl'
    argparse 's/status=' 'stdout=' -- $argv
    demock_curl

    set -g curl_status $_flag_status
    set -g curl_stdout $_flag_stdout

    function curl
        if test -n "$curl_stdout"
            eval "$curl_stdout"
        end
        return $curl_status
    end
end

function demock_curl
    functions -e curl
    set -e curl_status
    set -e curl_stdout
end

function mock_go -d 'mock go'
    argparse 'status_install=' 'status_download=' -- $argv

    set -g go_install_status $_flag_status_install
    set -g go_download_status $_flag_status_download

    function go
        # @test 'go install argv count' (count $argv) -eq 2
        if test $go_install_status -ne 0
            return $go_install_status
        end
        set -l pkg $argv[2]
        set -l v (string match -r -g 'golang.org\/dl\/go(.*)@latest' $pkg)
        eval "function go$v
    if test \$go_download_status -ne 0
        return \$go_download_status
    end

    mkdir -p $sdkpath/go$v
    
end"
    end

end

function demock_go
    functions -e go
    for v in $argv
        functions -e go$v
    end
end

init -t 'ls-remote success'
mock_curl -s 0 --stdout 'cat $dlfile'
set ls_remote (gg ls-remote | string collect)
@test 'test ls-remote' (cat $expect_version_output | string collect) = "$ls_remote"
@test 'test cache file' -f $sdkpath/.remote-cache
@test 'test cache file data ' (cat $sdkpath/.remote-cache | string collect) = (cat $expect_cache_file | string collect)
demock_curl
deinit

init -t 'ls-remote force'
mock_curl -s 0 --stdout 'cat $dlfile'
echo 'go1.16' > $sdkpath/.remote-cache
set ls_remote (gg ls-remote | string collect)
@test 'test ls-remote' '1.16' = "$ls_remote"
set ls_remote (gg ls-remote -f | string collect)
@test 'test ls-remote' (cat $expect_version_output | string collect) = "$ls_remote"
@test 'test cache file' -f $sdkpath/.remote-cache
@test 'test cache file data ' (cat $sdkpath/.remote-cache | string collect) = (cat $expect_cache_file | string collect)
demock_curl
deinit

init -t 'ls-remote use cache and curl failed'
mock_curl -s 1
echo 'go1.16' > $sdkpath/.remote-cache
set ls_remote (gg ls-remote | string collect)
@test 'test ls-remote' '1.16' = "$ls_remote"
demock_curl
deinit

init -t 'ls-remote cache expired'
mock_curl -s 0 --stdout 'cat $dlfile'
echo 'go1.16' > $sdkpath/.remote-cache
set -l now (date +%s)
set -l twodayago (math "$now-86400*2")
set -l format (date --date="@$twodayago" +%Y%m%d%H%M)
touch -t $format $sdkpath/.remote-cache
set ls_remote (gg ls-remote | string collect)
@test 'test ls-remote' (cat $expect_version_output | string collect) = "$ls_remote"
@test 'test cache file' -f $sdkpath/.remote-cache
@test 'test cache file data ' (cat $sdkpath/.remote-cache | string collect) = (cat $expect_cache_file | string collect)
demock_curl
deinit

init -t 'ls-remote failed'
mock_curl -s 1
set ls_remote (gg ls-remote | string collect)
@test 'test ls-remote' 'tip' = "$ls_remote"
@test 'test cache file' -f $sdkpath/.remote-cache
@test 'test cache file data ' (cat $sdkpath/.remote-cache | string collect) = 'gotip'
demock_curl
deinit

init -t 'install 1.16 success'
mock_go --status_install 0 --status_download 0
gg install 1.16
@test 'check installed dir' -d $sdkpath/go1.16
demock_go 1.16
deinit

init -t 'reinstall 1.16'
mock_go --status_install 0 --status_download 0
gg install 1.16
gg install 1.16
@test 'check installed dir' -d $sdkpath/go1.16
demock_go 1.16
deinit

init -t 'install 1.16 1.18 tip success'
mock_go --status_install 0 --status_download 0
gg install 1.16 1.18 tip
@test 'check installed dir 1.16' -d $sdkpath/go1.16
@test 'check installed dir 1.18' -d $sdkpath/go1.18
@test 'check installed dir tip' -d $sdkpath/gotip
demock_go 1.16 1.18 tip
deinit

init -t 'install 1.16 failed'
mock_go --status_install 1
set -l output (gg install 1.16 2>&1 | string collect)
@test 'check install failed output' (string match -r -q 'go install golang.org\/dl\/go1.16@latest failed' $output) $status -eq 0
@test 'check install dir 1.16 failed' ! -d $sdkpath/go1.16
demock_go
deinit

init -t 'download 1.16 failed'
mock_go --status_install 0 --status_download 1
gg install 1.16
set -l output (gg install 1.16 2>&1 | string collect)
@test 'check download failed output' (string match -r -q 'go1.16 download failed' $output) $status -eq 0
@test 'check download dir 1.16 failed' ! -d $sdkpath/go1.16
demock_go
deinit

init -t 'ls before any install'
set -l output (gg ls)
@test 'check ls' -z "$output"
deinit

init -t 'ls after install'
mock_go --status_install 0 --status_download 0
gg install 1.16
set -l output (gg ls)
@test 'check ls' "$output" = "1.16"
gg install 1.18
gg install tip
set -l output (gg ls | string collect)
@test 'check ls' "$output" = (printf "1.16\n1.18\ntip" | string collect)
demock_go 1.16
deinit

init -t 'remove'
gg remove 1.16
@test 'check status' $status -eq 0
mock_go --status_install 0 --status_download 0
gg install 1.16
gg remove 1.16
@test 'check remove dir' ! -d $sdkpath/go1.16
gg install 1.18 tip
gg remove 1.18 tip
@test 'check remove dir' ! -d $sdkpath/go1.16
@test 'check remove dir' ! -d $sdkpath/gotip
demock_go 1.16 1.18 tip
deinit

init -t 'use not exist'
set -l output (gg use 1.16 2>&1 | string collect)
@test 'check not exist prompt' $output = '# The version 1.16 is not exist, please run the command below to install it first
gg install 1.16'
deinit

init -t 'use 1.16'
mock_go --status_install 0 --status_download 0
gg install 1.16
set -l output (gg use -b 1.16 | string collect)
@test 'check use bash 1.16' "$output" = '# source this code to enable it
# for example:
# > gg use --bash 1.16 | source

# if you use direnv to manage environment, you can redirect the output to .envrc in the current directory
# > gg use --bash 1.16 >> .envrc; direnv allow

export GOROOT=$(go1.16 env GOROOT)
export PATH=$GOROOT/bin:$PATH'

set -l output (gg use -z 1.16 | string collect)
@test 'check use zsh 1.16' "$output" = '# source this code to enable it
# for example:
# > gg use --zsh 1.16 | source

# if you use direnv to manage environment, you can redirect the output to .envrc in the current directory
# > gg use --zsh 1.16 >> .envrc; direnv allow

export GOROOT=$(go1.16 env GOROOT)
export PATH=$GOROOT/bin:$PATH'

set -l output (gg use -f 1.16 | string collect)
@test 'check use fish 1.16' "$output" = '# source this code to enable it
# for example:
# > gg use --fish 1.16 | source

set -gx GOROOT (go1.16 env GOROOT)
fish_add_path $GOROOT/bin'

set -g SHELL bash
set -l output (gg use 1.16 | string collect)
@test 'check use default bash 1.16' "$output" = '# source this code to enable it
# for example:
# > gg use 1.16 | source

# if you use direnv to manage environment, you can redirect the output to .envrc in the current directory
# > gg use 1.16 >> .envrc; direnv allow

export GOROOT=$(go1.16 env GOROOT)
export PATH=$GOROOT/bin:$PATH'

set -g SHELL zsh
set -l output (gg use 1.16 | string collect)
@test 'check use default zsh 1.16' "$output" = '# source this code to enable it
# for example:
# > gg use 1.16 | source

# if you use direnv to manage environment, you can redirect the output to .envrc in the current directory
# > gg use 1.16 >> .envrc; direnv allow

export GOROOT=$(go1.16 env GOROOT)
export PATH=$GOROOT/bin:$PATH'

set -g SHELL fish
set -l output (gg use 1.16 | string collect)
@test 'check use default fish 1.16' "$output" = '# source this code to enable it
# for example:
# > gg use 1.16 | source

set -gx GOROOT (go1.16 env GOROOT)
fish_add_path $GOROOT/bin'
demock_go 1.16
deinit

init -t 'test help'
set help (gg -h | string collect)
@test 'gg -h, test status' $status -eq 0
@test 'gg -h, test output' $help = 'gg: golang version manager
Usage: gg [options] <subcommand> [options] <args>

Options:
  -h/--help         print this help message

Subcommands:
  ls           list local version
  ls-remote    list remote version
  install      install specified version
  remove       remove specified version
  use          print the specified version environment'

set help (gg)
@test 'gg no args, test status' $status -eq 1
@test 'gg no args, test output' "$help" = 'gg: golang version manager Usage: gg [options] <subcommand> [options] <args>  Options:   -h/--help         print this help message  Subcommands:   ls           list local version   ls-remote    list remote version   install      install specified version   remove       remove specified version   use          print the specified version environment'

set help (gg ls -h | string collect)
@test 'gg ls -h, test status' $status -eq 0
@test 'gg ls -h, test output' "$help" = 'gg ls: list local version
Usage: gg ls [options]

Options:
  -h/--help    print this help message'

set help (gg ls-remote -h | string collect)
@test 'gg ls-remote -h, test status' $status -eq 0
@test 'gg ls-remote -h, test output' "$help" = 'gg ls-remote: list remote version, it will use the cache if the age of it less than 1 day
Usage: gg ls-remote [options]

Options:
  -f/--force   force to update cache
  -h/--help    print this help message'

set help (gg install -h | string collect)
@test 'gg install -h, test status' $status -eq 0
@test 'gg install -h, test output' "$help" = 'gg install: install specified version
Usage: gg install [options] <version...>

Options:
  -h/--help    print this help message'

set help (gg install)
@test 'gg install, test status' $status -eq 1
@test 'gg install, test output' "$help" = 'gg install: install specified version Usage: gg install [options] <version...>  Options:   -h/--help    print this help message'

set help (gg remove -h | string collect)
@test 'gg remove -h, test status' $status -eq 0
@test 'gg remove -h, test output' "$help" = 'gg remove: remove specified version
Usage: gg remove [options] <version...>

Options:
  -h/--help    print this help message'

set help (gg remove)
@test 'gg remove, test status' $status -eq 1
@test 'gg remove, test output' "$help" = 'gg remove: remove specified version Usage: gg remove [options] <version...>  Options:   -h/--help    print this help message'

set help (gg use -h | string collect)
@test 'gg use -h, test status' $status -eq 0
@test 'gg use -h, test output' "$help" = 'gg use: print the specified version environment
If no shell option provide, it will use the $SHELL as default
Usage: gg use [options] <version>

Options:
  -b/--bash          print the bash environment
  -z/--zsh           print the zsh environment
  -f/--fish          print the fish environment
  -h/--help          print this help message'

set help (gg use)
@test 'gg use, test status' $status -eq 1
@test 'gg use, test output' "$help" = 'gg use: print the specified version environment If no shell option provide, it will use the $SHELL as default Usage: gg use [options] <version>  Options:   -b/--bash          print the bash environment   -z/--zsh           print the zsh environment   -f/--fish          print the fish environment   -h/--help          print this help message'
deinit

init -t 'complete'
@test 'complete gg' (complete -C 'gg ' | string collect) = 'install	install specified version
ls	list local version
ls-remote	list remote version
remove	remove specified version
use	print the specified version environment
-h	print this help message
--help	print this help message'

@test 'complete gg l' (complete -C 'gg l' | string collect) = 'ls	list local version
ls-remote	list remote version'

mock_curl -s 0 --stdout 'cat $dlfile'
mock_go --status_install 0 --status_download 0
gg install 1.16 1.18 tip

@test 'complete gg install ' (complete -C 'gg install ' | string collect) = (cat $expect_version_output | string collect)

@test 'complete bb use ' (complete -C 'gg use ' | string collect) = '1.16
1.18
tip'

@test 'complete bb remove ' (complete -C 'gg remove ' | string collect) = '1.16
1.18
tip'
demock_go
demock_curl
deinit
