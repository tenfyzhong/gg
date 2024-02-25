.PHONY: all bash fish ggenvbash

cwd=$(shell pwd)

all: bash fish

bash:
	gg_repo=$(cwd) bats tests/*.bats

fish:
	fish -c 'fishtape tests/*.fish'

ggenvbash:
	gg_repo=$(cwd) bats tests/ggenv.bats
