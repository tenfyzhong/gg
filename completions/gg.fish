complete -c gg -f
complete -c gg -f -s h -l help -d 'print this help message'
complete -c gg -f -n '! __fish_seen_subcommand_from ls ls-remote install remove use' -a 'ls' -d 'list local version'
complete -c gg -f -n '! __fish_seen_subcommand_from ls ls-remote install remove use' -a 'ls-remote' -d 'list remote version'
complete -c gg -f -n '! __fish_seen_subcommand_from ls ls-remote install remove use' -a 'install' -d 'install specified version'
complete -c gg -f -n '! __fish_seen_subcommand_from ls ls-remote install remove use' -a 'remove' -d 'remove specified version'
complete -c gg -f -n '! __fish_seen_subcommand_from ls ls-remote install remove use' -a 'use' -d 'print the specified version environment'
complete -c gg -f -n '__fish_seen_subcommand_from ls' -s h -l help -d 'print this help message'
complete -c gg -f -n '__fish_seen_subcommand_from ls-remote' -s f -l force -d 'force to update cache'
complete -c gg -f -n '__fish_seen_subcommand_from ls-remote' -s h -l help -d 'print this help message'
complete -c gg -f -n '__fish_seen_subcommand_from install' -s h -l help -d 'print this help message'
complete -c gg -f -k -n '__fish_seen_subcommand_from install' -a '(__gg-ls-remote)'
complete -c gg -f -n '__fish_seen_subcommand_from remove' -s h -l help -d 'print this help message'
complete -c gg -f -k -n '__fish_seen_subcommand_from remove' -a "(__gg-ls)"
complete -c gg -f -n '__fish_seen_subcommand_from use' -s b -l bash -d 'print the bash environment'
complete -c gg -f -n '__fish_seen_subcommand_from use' -s z -l zsh -d 'print the zsh environment'
complete -c gg -f -n '__fish_seen_subcommand_from use' -s f -l fish -d 'print the fish environment'
complete -c gg -f -n '__fish_seen_subcommand_from use' -s h -l help -d 'print this help message'
complete -c gg -f -k -n '__fish_seen_subcommand_from use' -a "(__gg-ls)"
