.PHONY: all

cwd=$(shell pwd)

all: bash fish

bash:
	gg_repo=$(cwd) bats tests/*.bats

fish:
	fish -c 'fishtape tests/*.fish'
