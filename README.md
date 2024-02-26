# Table of Contents
- [gg](#gg)
- [Install](#install)
  - [fish shell](#fish-shell)
  - [bash/zsh](#bash/zsh)
  - [manually](#manually)
    - [fish shell](#fish-shell)
    - [bash](#bash)
    - [zsh](#zsh)
- [Introductions](#introductions)
  - [How it works](#how-it-works)
  - [Usage](#usage)
    - [gg](#gg)
    - [ggenv](#ggenv)

# gg
Golang version manager. Shell script to manage multiple active golang versions.

# Install
## fish shell
Install using Fisher(or other plugin manager):
```
fisher install tenfyzhong/gg
```

## bash/zsh
Use `homebrew` to install
```
brew tap tenfyzhong/tap
brew install gg
```

## manually
### fish shell
1. download `functions/gg.fish` to `~/.config/fish/functions`
2. download `completions` to `~/.config/fish/completions`

### bash
1. download `gg` to a directory in your `$PATH`, such as `/usr/local/bin`
2. download `gg-completions.bash` to a directory and source it in your `.bashrc`

### zsh
1. download `gg` to a directory in your `$PATH`, such as `/usr/local/bin`
2. download `_gg` to a directory in you `fpath`

# Introductions
`gg` is a Golang version manager. It can download a special version of golang, and switch to it.

## How it works
`gg` wraps [golang.org/dl](https://github.com/golang/dl), make it easy to download and install golang version.

If you install a special version manually, you should install follow this steps:
1. `go install golang.org/dl/go1.18@latest`, install a go to `$GOPATH/bin`
2. `go1.18 download`, download the archived go to `~/sdk/`

After you install the special version golang, you can use such as: `go1.18 <subcommand>`  
for example: `go1.18 build` or `go1.18 install`

In other ways, you can set the `GOROOT` environment variable to specify the path of golang version.
For bash shell: 
```bash
export GOROOT=$HOME/sdk/go1.18
export PATH=$GOROOT/bin:$PATH
```

For fish shell:
```fish
set -gx GOROOT $HOME/sdk/go1.18
fish_add_path $GOROOT/bin
```

Using `gg`, you can run `gg use 1.18` to get the command above to run.


If you use [direnv](https://direnv.net/), you can set the bash environment to `.envrc` file, it will automatically use the special version when you cd to the directory.  
With `gg`, you can run this command to set the environment automatic:
```sh
gg use -b 1.18 >> .envrc; direnv allow
```


## Usage
### gg
Command `gg` has 5 subcommands which help you to download or use a special version of golang:  
| command        | options    | description               |
|----------------|------------|---------------------------|
| `gg ls`        |            | list local version        |
| `gg ls-remote` |            | list remote version       |
| `gg install`   | version... | install specified version |
| `gg remove`    | version... | remove specified version  |
| `gg use`       | version    | remove specified version  |

### ggenv
Command `ggenv` combine `gg use` and `direnv allow`, make it use `gg` and `direnv` easily
