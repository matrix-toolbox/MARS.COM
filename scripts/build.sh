#!/usr/bin/env bash
# Assembles MARS.ASM into a runnable DOS .COM image.
#
# MARS.ASM is MASM/TASM dialect (.model tiny, org 100h, COMMENT # blocks),
# so it needs a MASM-compatible assembler — NASM cannot build it. We use
# JWasm, pinned in versions.env. Because the model is tiny, the assembler
# emits the .COM memory image directly; there is no link step.
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

usage() {
  cat <<'EOF'
Usage: scripts/build.sh [--docker] [--check]

  --docker  Run the build inside a container (no host compiler needed).
  --check   Verify the output matches the pinned size and SHA-256.

Assembler resolution order:
  1. $JWASM environment variable
  2. jwasm on PATH
  3. build JWasm from source into .toolchain/ (needs gcc, make, git)
EOF
}

use_docker=0
do_check=0
for arg in "$@"; do
  case "$arg" in
    --docker) use_docker=1 ;;
    --check)  do_check=1 ;;
    -h|--help) usage; exit 0 ;;
    *) die "unknown option: $arg (try --help)" ;;
  esac
done

if [ "$use_docker" -eq 1 ]; then
  need docker
  log "Building inside debian:bookworm-slim"
  docker run --rm -v "$REPO_ROOT:/repo" -w /repo debian:bookworm-slim bash -c '
    set -e
    apt-get update -qq >/dev/null
    apt-get install -y -qq build-essential git ca-certificates >/dev/null 2>&1
    bash scripts/build.sh
  '
  exit $?
fi

# --- resolve an assembler -----------------------------------------------
resolve_jwasm() {
  if [ -n "${JWASM:-}" ]; then
    [ -x "$JWASM" ] || die "\$JWASM is set to '$JWASM' but that is not executable"
    printf '%s' "$JWASM"
    return
  fi

  if command -v jwasm >/dev/null 2>&1; then
    command -v jwasm
    return
  fi

  local cached="$TOOLCHAIN_DIR/bin/jwasm"
  if [ -x "$cached" ]; then
    printf '%s' "$cached"
    return
  fi

  log "No assembler found; building JWasm $JWASM_TAG from source"
  need git
  need make
  command -v cc >/dev/null 2>&1 || command -v gcc >/dev/null 2>&1 \
    || die "no C compiler found. Install gcc/clang, set \$JWASM to a jwasm binary, or rerun with --docker"

  local src="$TOOLCHAIN_DIR/JWasm"
  local buildlog="$TOOLCHAIN_DIR/jwasm-build.log"
  rm -rf "$src"
  mkdir -p "$TOOLCHAIN_DIR/bin"
  git clone -q "$JWASM_REPO" "$src" >&2
  ( cd "$src" && git checkout -q "$JWASM_TAG" ) \
    || die "could not check out JWasm $JWASM_TAG"

  # GccUnix.mak targets Linux/FreeBSD, so it needs two fixes on macOS:
  #
  #   1. It includes <malloc.h>, a glibc location. macOS declares malloc in
  #      <stdlib.h>. Rather than editing 58 source files, we prepend an
  #      include directory holding a malloc.h that forwards to stdlib.h.
  #   2. It links with -s and -Wl,-Map, both GNU ld flags that Apple's ld
  #      rejects. These are hardcoded in the recipe, not in a variable, so
  #      they have to be stripped from our throwaway checkout.
  #
  # Both are confined to .toolchain/, which is gitignored. Verified to yield
  # a binary byte-identical to the Linux build.
  local inc_dirs="-Isrc/H"
  if [ "$(uname -s)" = "Darwin" ]; then
    local shim="$TOOLCHAIN_DIR/shim"
    mkdir -p "$shim"
    printf '/* Darwin shim: malloc is declared in stdlib.h, not malloc.h */\n#include <stdlib.h>\n' \
      > "$shim/malloc.h"
    sed -i.bak -e 's/ -Wl,-Map,[^ ]*//' -e 's/ -s -o / -o /' "$src/GccUnix.mak" \
      || die "could not patch GccUnix.mak for macOS"
    inc_dirs="-Isrc/H -I$shim"
    log "Applied macOS portability patches to the JWasm checkout"
  fi

  ( cd "$src" && make -f GccUnix.mak inc_dirs="$inc_dirs" ) >"$buildlog" 2>&1 \
    || die "JWasm build failed; see $buildlog. Rerun with --docker, or set \$JWASM to a prebuilt binary."

  local built
  built="$(find "$src" -name jwasm -type f -perm -u+x | head -1)"
  [ -n "$built" ] || die "JWasm built but no 'jwasm' binary was produced"
  cp "$built" "$cached"
  printf '%s' "$cached"
}

JWASM_BIN="$(resolve_jwasm)"
log "Assembler: $JWASM_BIN"

# --- assemble ------------------------------------------------------------
mkdir -p "$BUILD_DIR"
out="$BUILD_DIR/MARS.COM"
rm -f "$out"

# -bin: raw binary output, which for .model tiny is exactly a .COM image.
"$JWASM_BIN" -bin -Fo="$out" "$REPO_ROOT/MARS.ASM" \
  || die "assembly failed"

[ -s "$out" ] || die "assembler produced an empty $out"

size=$(wc -c < "$out" | tr -d ' ')
[ "$size" -le "$MARS_COM_MAX_SIZE" ] \
  || die "$out is $size bytes, which exceeds the $MARS_COM_MAX_SIZE byte .COM ceiling"

if command -v shasum >/dev/null 2>&1; then
  sha=$(shasum -a 256 "$out" | cut -d' ' -f1)
else
  sha=$(sha256sum "$out" | cut -d' ' -f1)
fi

log "Built $out — $size bytes, sha256 $sha"

if [ "$do_check" -eq 1 ]; then
  [ "$size" = "$MARS_COM_SIZE" ] \
    || die "size mismatch: expected $MARS_COM_SIZE bytes, got $size. If MARS.ASM changed on purpose, update versions.env."
  [ "$sha" = "$MARS_COM_SHA256" ] \
    || die "sha256 mismatch: expected $MARS_COM_SHA256, got $sha. If MARS.ASM changed on purpose, update versions.env."
  log "Reproducibility check passed"
fi
