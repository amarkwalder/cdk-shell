

################################################################################


VERSION ?= 1.0.0-rc1
BUILD    = `git rev-parse HEAD`


################################################################################


PLATFORMS=linux_amd64 linux_386 linux_arm darwin_amd64 darwin_386 freebsd_amd64 freebsd_386 windows_386 windows_amd64

FLAGS_all           = GOPATH=$(GOPATH)
FLAGS_linux_amd64   = $(FLAGS_all) GOOS=linux GOARCH=amd64
FLAGS_linux_386     = $(FLAGS_all) GOOS=linux GOARCH=386
FLAGS_linux_arm     = $(FLAGS_all) GOOS=linux GOARCH=arm
FLAGS_darwin_amd64  = $(FLAGS_all) GOOS=darwin GOARCH=amd64
FLAGS_darwin_386    = $(FLAGS_all) GOOS=darwin GOARCH=386
FLAGS_freebsd_amd64 = $(FLAGS_all) GOOS=freebsd GOARCH=amd64
FLAGS_freebsd_386   = $(FLAGS_all) GOOS=freebsd GOARCH=386
FLAGS_windows_386   = $(FLAGS_all) GOOS=windows GOARCH=386
FLAGS_windows_amd64 = $(FLAGS_all) GOOS=windows GOARCH=amd64

EXTENSION_windows_386=.exe
EXTENSION_windows_amd64=.exe

msg=@printf "\n\033[0;01m>>> %s\033[0m\n" $1


################################################################################


.DEFAULT_GOAL := build

build:
	$(call msg,"Build binary")
	$(FLAGS_all) go build -ldflags "-X main.Version=${VERSION} -X main.Build=${BUILD}" -o cdk-shell$(EXTENSION_$*) $(wildcard ../*.go)
.PHONY: build

install: build
	$(call msg,"Install cdk-shell")
	mkdir -p /usr/local/bin/
	cp cdk-shell /usr/local/bin/
.PHONY:	install

uninstall:
	$(call msg,"Uninstall cdk-shell")
	rm -f /usr/local/bin/cdk-shell
.PHONY:	uninstall

test:
	$(call msg,"Run tests")
	@echo TODO
.PHONY: test

clean:
	$(call msg,"Clean release directory")
	rm -rf dist
.PHONY: clean

build-all: $(foreach PLATFORM,$(PLATFORMS),dist/$(VERSION)/$(PLATFORM)/.built)
.PHONY: build

dist: build-all $(foreach PLATFORM,$(PLATFORMS),dist/$(VERSION)/cdk-shell-$(VERSION)-$(PLATFORM).zip)
.PHONY:	dist 


################################################################################


dist/$(VERSION)/%/.built:
	$(call msg,"Build binary for $*")
	rm -f $@
	mkdir -p $(dir $@)
	$(FLAGS_$*) go build -ldflags "-X main.Version=${VERSION} -X main.Build=${BUILD}" -o dist/$(VERSION)/$*/cdk-shell$(EXTENSION_$*) $(wildcard ../*.go)
	touch $@

dist/$(VERSION)/cdk-shell-$(VERSION)-%.zip:
	$(call msg,"Create ZIP for $*")
	rm -f $@
	mkdir -p $(dir $@)
	zip -j $@ dist/$(VERSION)/$*/*

guard-%:
	@ if [ "${${*}}" = "" ]; then \
		echo "Environment variable $* not set"; \
		exit 1; \
	fi


################################################################################
