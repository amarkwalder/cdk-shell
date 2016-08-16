

################################################################################


VERSION             ?= 1.0.0-rc1
PRERELEASE           = true
DRAFT                = false
BUILD                = `git rev-parse HEAD`

TAG_TARGET_COMMITISH = master
TAG_BODY             = ti&m channel suite Software Development Kit (CDK)
TAG_DRAFT            = false
TAG_PRERELEASE       = true


################################################################################


GITHUB_RELEASE_API_JSON={\"tag_name\": \"v$(VERSION)\", \"target_commitish\": \"$(TAG_TARGET_COMMITISH)\", \"name\": \"v$(VERSION)\", \"body\": \"$(TAG_BODY)\", \"draft\": $(TAG_DRAFT), \"prerelease\": $(TAG_PRERELEASE)}

PLATFORMS=linux_amd64 linux_386 linux_arm darwin_amd64 darwin_386 freebsd_amd64 freebsd_386 windows_386 windows_amd64

FLAGS_all           = GOPATH=$(GOPATH)
FLAGS_linux_amd64   = $(FLAGS_all) GOOS=linux GOARCH=amd64
FLAGS_linux_386     = $(FLAGS_all) GOOS=linux GOARCH=386
FLAGS_linux_arm     = $(FLAGS_all) GOOS=linux GOARCH=arm	#GOARM=5
FLAGS_darwin_amd64  = $(FLAGS_all) GOOS=darwin GOARCH=amd64	#CGO_ENABLED=0
FLAGS_darwin_386    = $(FLAGS_all) GOOS=darwin GOARCH=386	#CGO_ENABLED=0
FLAGS_freebsd_amd64 = $(FLAGS_all) GOOS=freebsd GOARCH=amd64	#CGO_ENABLED=0
FLAGS_freebsd_386   = $(FLAGS_all) GOOS=freebsd GOARCH=386	#CGO_ENABLED=0
FLAGS_windows_386   = $(FLAGS_all) GOOS=windows GOARCH=386	#CGO_ENABLED=0
FLAGS_windows_amd64 = $(FLAGS_all) GOOS=windows GOARCH=amd64	#CGO_ENABLED=0

EXTENSION_windows_386=.exe
EXTENSION_windows_amd64=.exe

msg=@printf "\n\033[0;01m>>> %s\033[0m\n" $1


################################################################################


.DEFAULT_GOAL := build

build:
	$(FLAGS_all) go build -ldflags "-X main.Version=${VERSION} -X main.Build=${BUILD}" -o cdk-shell$(EXTENSION_$*) $(wildcard ../*.go)
.PHONY: build

install: build
	mkdir -p /usr/local/bin/
	cp cdk-shell /usr/local/bin/
.PHONY:	install

uninstall:
	rm -f /usr/local/bin/cdk-shell
.PHONY:	uninstall

clean:
	$(call msg,"Clean release directory")
	rm -rf dist
.PHONY: clean

build-all: $(foreach PLATFORM,$(PLATFORMS),dist/$(VERSION)/$(PLATFORM)/.built)
.PHONY: build

dist: build-all $(foreach PLATFORM,$(PLATFORMS),dist/$(VERSION)/cdk-shell-$(VERSION)-$(PLATFORM).zip)
.PHONY: dist 

release: guard-GITHUB_USER_PWD dist dist/$(VERSION)/.github-create-release.json $(foreach PLATFORM,$(PLATFORMS),dist/$(VERSION)/$(PLATFORM)/.uploaded)
.PHONY: release


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

dist/$(VERSION)/%/.uploaded:
	$(call msg,"Upload ZIP $*")
	@ UPLOAD_URL="$$(grep "upload_url" dist/$(VERSION)/.github-create-release.json | awk '{print $$2}' | cut -c 2- | rev | cut -c 16- | rev)"; \
	if [ "$${UPLOAD_URL}" == "" ]; then \
		echo "Could not extract upload url to github.com (see dist/$(VERSION)/.github-create-release.json for more details)"; \
		exit 1; \
	fi; \
	curl -sSL -u $(GITHUB_USER_PWD) -X POST --header "Content-Type:application/zip" --data-binary @dist/$(VERSION)/cdk-shell-$(VERSION)-$*.zip "$${UPLOAD_URL}?name=cdk-shell-$(VERSION)-$*.zip" -o dist/$(VERSION)/.cdk-shell-$(VERSION)-$*.zip-upload.json; \
	echo "curl -sSL -u ... -X POST --header "Content-Type:application/zip" --data-binary @@dist/$(VERSION)/cdk-shell-$(VERSION)-$*.zip "$${UPLOAD_URL}?name=cdk-shell-$(VERSION)-$*.zip" -o dist/$(VERSION)/.cdk-shell-$(VERSION)-$*.zip-upload.json"
	touch $@

dist/$(VERSION)/.github-create-release.json:
	$(call msg,"Tag and create release '$(VERSION)' on github.com")
	rm -f $@
	mkdir -p $(dir $@)
	@ curl -sSL -u $(GITHUB_USER_PWD) --data "$(GITHUB_RELEASE_API_JSON)" https://api.github.com/repos/amarkwalder/cdk-shell/releases -o dist/$(VERSION)/.github-create-release.json; \
	UPLOAD_URL="$$(grep "upload_url" dist/$(VERSION)/.github-create-release.json | awk '{print $$2}' | cut -c 2- | rev | cut -c 16- | rev)"; \
	if [ "$${UPLOAD_URL}" == "" ]; then \
		echo "Could not create release on github.com (see dist/$(VERSION)/.github-create-release.json for more details)"; \
		exit 1; \
	else \
		echo "curl -sSL -u ... --data "..." https://api.github.com/repos/amarkwalder/cdk-shell/releases -o dist/$(VERSION)/.github-create-release.json"; \
		echo "upload-url: $${UPLOAD_URL}"; \
		touch $@; \
	fi;

guard-%:
	@ if [ "${${*}}" = "" ]; then \
		echo "Environment variable $* not set"; \
		exit 1; \
	fi


################################################################################
