.PHONY: all

cwd=$(shell pwd)

all: 
	gg_repo=$(cwd) bats tests/*.bats
