#!/usr/bin/env bash
# Verifies the bootable floppy image contains everything DOS needs.
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
. "$(dirname "${BASH_SOURCE[0]}")/../scripts/lib.sh"
export MTOOLS_SKIP_CHECK=1

bash "$REPO_ROOT/scripts/build.sh" >/dev/null 2>&1
assert_success bash "$REPO_ROOT/scripts/make-image.sh"
assert_file_exists "$BUILD_DIR/mars.img"

size=$(wc -c < "$BUILD_DIR/mars.img" | tr -d ' ')
assert_eq "$size" "$FREEDOS_IMG_SIZE" "image keeps the 720 KB floppy geometry"

listing="$BUILD_DIR/.img-listing.txt"
mdir -i "$BUILD_DIR/mars.img" ::/ > "$listing" 2>/dev/null
assert_contains "$listing" "MARS     COM"
assert_contains "$listing" "CTMOUSE  EXE"
assert_contains "$listing" "AUTOEXEC BAT"
assert_contains "$listing" "COMMAND  COM"

conf="$BUILD_DIR/.img-autoexec.txt"
mtype -i "$BUILD_DIR/mars.img" ::/AUTOEXEC.BAT > "$conf" 2>/dev/null
assert_contains "$conf" "CTMOUSE.EXE"
assert_contains "$conf" "MARS.COM"

rm -f "$listing" "$conf"
finish_tests
