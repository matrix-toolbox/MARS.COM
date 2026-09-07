#!/usr/bin/env bash
# Verifies the composed site is complete and self-contained.
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
. "$(dirname "${BASH_SOURCE[0]}")/../scripts/lib.sh"

assert_success bash "$REPO_ROOT/scripts/build-site.sh"

assert_file_exists "$SITE_OUT/index.html"
assert_file_exists "$SITE_OUT/style.css"
assert_file_exists "$SITE_OUT/mars.img"
assert_file_exists "$SITE_OUT/MARS.COM"
assert_file_exists "$SITE_OUT/MARS.ASM"
assert_file_exists "$SITE_OUT/v86/libv86.js"
assert_file_exists "$SITE_OUT/v86/v86.wasm"
assert_file_exists "$SITE_OUT/v86/bios/seabios.bin"

# The page must reference its own copies, not a CDN.
assert_contains "$SITE_OUT/index.html" 'v86/v86.wasm'
assert_contains "$SITE_OUT/index.html" 'mars.img'

# No third-party origins anywhere in the page.
if grep -qE 'https?://(v8\.)?js-dos\.com|copy\.sh|cdn\.|unpkg|jsdelivr' "$SITE_OUT/index.html"; then
  fail "index.html references a third-party asset origin"
else
  pass "no third-party asset origins in index.html"
fi

# Attribution must survive any future edit of the page.
assert_contains "$SITE_OUT/index.html" "Tim J. Clarke"
assert_contains "$SITE_OUT/index.html" "Bruzda"

finish_tests
