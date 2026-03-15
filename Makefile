# VERSION is set at release time (e.g. VERSION=v1.0.0 make release).
# Artifacts go to dist/ for upload to GitHub Releases; checksums.txt is optional for verification.
VERSION ?= dev

# COMMIT is the short (7-char) git hash for dev build traceability; used only for build target.
COMMIT := $(shell git rev-parse --short=7 HEAD 2>/dev/null || true)

# BUILD // dev
# More verbose platform separation...but you can still override bits on the CLI
PLATFORMS := linux-amd64 linux-arm64 darwin-amd64 darwin-arm64
BUILD_BINS := $(addprefix bin/stet-,$(PLATFORMS))
BUILD_LDFLAGS := -ldflags "-X stet/cli/internal/version.Commit=$(COMMIT)"

# RELEASE
# Full release needs to do extra stuff for the windows binaries
RELEASE_PLATFORMS := $(PLATFORMS) windows-amd64 windows-arm64
_win := $(filter windows-%,$(RELEASE_PLATFORMS))
_nonwin := $(filter-out windows-%,$(RELEASE_PLATFORMS))
RELEASE_BINS := $(addprefix dist/stet-,$(addsuffix .exe,$(_win)) $(_nonwin))

LDFLAGS = -ldflags "-X stet/cli/internal/version.Version=$(VERSION)"

# App related -- to more easily find which source changes to gate building
STET := ./cli/cmd/stet
STET_SRC := $(shell find $(STET) -name '*.go' -not -name '*_test.go')

.PHONY: build build-all clean test coverage release check

build: bin/stet

bin/stet: $(STET_SRC) go.mod go.sum | bin
	go build -buildvcs=false $(BUILD_LDFLAGS) -o $@ $(STET)

bin:
	mkdir -p bin

build-all: bin/stet $(BUILD_BINS)

# Parse os/arch from any stet binary target (bin/ or dist/, strips .exe).
_temp = $(subst -, ,$(patsubst stet-%,%,$(basename $(notdir $@))))
os = $(word 1, $(_temp))
arch = $(word 2, $(_temp))

$(BUILD_BINS): $(STET_SRC) go.mod go.sum | bin
	GOOS=$(os) GOARCH=$(arch) go build -buildvcs=false $(BUILD_LDFLAGS) -o $@ $(STET)

# Release binaries into dist/ with checksums.
# Run: VERSION=v1.0.0 make release
dist:
	mkdir -p dist

$(RELEASE_BINS): $(STET_SRC) go.mod go.sum | dist
	GOOS=$(os) GOARCH=$(arch) go build -buildvcs=false $(LDFLAGS) -o $@ $(STET)

release: $(RELEASE_BINS)
	@(cd dist && (sha256sum stet-* 2>/dev/null || shasum -a 256 stet-*) > checksums.txt)

clean:
	rm -f bin/stet bin/stet-* coverage.out
	# dist/ contains release binaries (stet-{os}-{arch}); rm -rf removes all
	rm -rf dist

test:
	go test ./cli/... -count=1

check: bin/stet
	bin/stet doctor

coverage: coverage.out
	@bash scripts/check-coverage.sh coverage.out

coverage.out:
	go test ./cli/... -coverprofile=coverage.out -count=1
