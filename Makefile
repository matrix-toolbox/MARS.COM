# Thin wrappers over scripts/. Every target is also runnable directly.
.PHONY: all build image v86 site serve test clean help

all: site

help:   ## List the available targets
	@grep -hE '^[a-z-]+:.*##' $(MAKEFILE_LIST) \
		| sed -e 's/:.*##/\t/' \
		| awk -F'\t' '{ printf "  \033[1m%-8s\033[0m %s\n", $$1, $$2 }'

build:   ## Assemble MARS.ASM into build/MARS.COM
	@bash scripts/build.sh

image: build   ## Build the bootable FreeDOS floppy (build/mars.img)
	@bash scripts/make-image.sh

v86:   ## Fetch the pinned v86 runtime and BIOS blobs
	@bash scripts/fetch-v86.sh

site:   ## Compose the deployable site into _site/
	@bash scripts/build-site.sh

serve:   ## Build the site and serve it at http://localhost:8080
	@bash scripts/serve.sh

test:   ## Run the test suite
	@bash tests/run-tests.sh

clean:   ## Remove build outputs (keeps the cached toolchain)
	@rm -rf build _site
	@echo "Removed build/ and _site/ (run 'rm -rf .toolchain' to drop the assembler too)"
