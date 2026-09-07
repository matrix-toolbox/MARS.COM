#!/usr/bin/env bash
# Verifies we fetch exactly the v86 assets the page needs.
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
. "$(dirname "${BASH_SOURCE[0]}")/../scripts/lib.sh"

assert_success bash "$REPO_ROOT/scripts/fetch-v86.sh"

assert_file_exists "$BUILD_DIR/v86/libv86.js"
assert_file_exists "$BUILD_DIR/v86/v86.wasm"
assert_file_exists "$BUILD_DIR/v86/bios/seabios.bin"
assert_file_exists "$BUILD_DIR/v86/bios/vgabios.bin"

# The BIOS blobs are binaries, not an HTML error page.
sea=$(wc -c < "$BUILD_DIR/v86/bios/seabios.bin" | tr -d ' ')
if [ "$sea" -gt 60000 ]; then pass "seabios.bin looks like a real BIOS ($sea bytes)"; else fail "seabios.bin is only $sea bytes"; fi

finish_tests
