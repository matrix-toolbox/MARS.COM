#!/usr/bin/env bash
# Shared helpers for every script in this repo. Source it, don't execute it.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$REPO_ROOT/build"
SITE_OUT="$REPO_ROOT/_site"
TOOLCHAIN_DIR="$REPO_ROOT/.toolchain"

# shellcheck source=/dev/null
. "$REPO_ROOT/versions.env"

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31mError:\033[0m %s\n' "$*" >&2; exit 1; }
need() { command -v "$1" >/dev/null 2>&1 || die "required tool not found: $1"; }

sha256_of() {
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | cut -d' ' -f1
  else
    sha256sum "$1" | cut -d' ' -f1
  fi
}

# Every third-party download must pass through this. Anything fetched over
# the network and then executed — a BIOS blob, a DOS driver, a wasm runtime —
# is pinned by content, not just by name or version.
verify_sha() {
  local file="$1" expected="$2" label="$3" actual
  actual="$(sha256_of "$file")"
  [ "$actual" = "$expected" ] \
    || die "$label checksum mismatch: expected $expected, got $actual"
}
