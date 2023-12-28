# gg
Golang version manager. Shell script to manage multiple active golang versions.

# Install
## fish shell
Install using Fisher(or other plugin manager):
```
fisher install tenfyzhong/fish-gg
```

# Introductions
`gg` is a Golang version manager. It can download a special version of golang, and switch to it.

## How it works
`gg` wraps [golang.org/dl](https://github.com/golang/dl), make it easy to download and install golang version.

If you install a special version manually, you should install follow this steps:
1. `go install golang.org/dl/go1.18@latest`
2. `go1.18 download`

After you install the special version golang, you can use such as: `go1.18 <subcommand>`  
for example: `go1.18 build` or `go1.18 install`

In other ways, you can set the `GOROOT` environment variable to specify the path of golang version.
For bash shell: 
```bash
export GOROOT=$(go1.18 env GOROOT)
export PATH=$GOROOT/bin:$PATH
```

For fish shell:
```fish
set -gx GOROOT (go1.18 env GOROOT)
fish_add_path $GOROOT/bin
```

Using `gg`, you can run `gg use 1.18` to get the command above to run.


If you use [direnv](https://direnv.net/), you can set the bash environment to `.envrc` file, it will automatically use the special version when you cd to the directory.  
With `gg`, you can run this command to set the environment automatic:
```sh
gg use -b 1.18 >> .envrc; direnv allow
```


## Usage
It has 5 subcommands which help you to download or use a special version of golang:  
| command        | options    | description               |
|----------------|------------|---------------------------|
| `gg ls`        |            | list local version        |
| `gg ls-remote` |            | list remote version       |
| `gg install`   | version... | install specified version |
| `gg remove`    | version... | remove specified version  |
| `gg use`       | version    | remove specified version  |
