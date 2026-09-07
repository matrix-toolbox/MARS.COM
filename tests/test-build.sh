#!/usr/bin/env bash
# Verifies the assembler pipeline produces the expected MARS.COM.
# First run is slow: it builds JWasm from source.
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
. "$(dirname "${BASH_SOURCE[0]}")/../scripts/lib.sh"

rm -f "$BUILD_DIR/MARS.COM"
assert_success bash "$REPO_ROOT/scripts/build.sh"
assert_file_exists "$BUILD_DIR/MARS.COM"

actual_size=$(wc -c < "$BUILD_DIR/MARS.COM" | tr -d ' ')
assert_eq "$actual_size" "$MARS_COM_SIZE" "MARS.COM is the expected size"

actual_sha=$(shasum -a 256 "$BUILD_DIR/MARS.COM" 2>/dev/null | cut -d' ' -f1 \
  || sha256sum "$BUILD_DIR/MARS.COM" | cut -d' ' -f1)
assert_eq "$actual_sha" "$MARS_COM_SHA256" "MARS.COM is byte-identical to the pinned build"

# --check must succeed on a good build
assert_success bash "$REPO_ROOT/scripts/build.sh" --check

finish_tests
