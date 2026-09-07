#!/usr/bin/env bash
# Verifies scripts/lib.sh exposes the contract the other scripts rely on.
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
. "$(dirname "${BASH_SOURCE[0]}")/../scripts/lib.sh"

assert_file_exists "$REPO_ROOT/MARS.ASM"   # REPO_ROOT points at the repo
assert_eq "$BUILD_DIR" "$REPO_ROOT/build" "BUILD_DIR derived from REPO_ROOT"
assert_eq "$SITE_OUT" "$REPO_ROOT/_site" "SITE_OUT derived from REPO_ROOT"
assert_eq "$JWASM_TAG" "v2.20" "JWasm pin loaded from versions.env"
assert_eq "$V86_VERSION" "0.5.432" "v86 pin loaded from versions.env"
assert_eq "$MARS_COM_SIZE" "1550" "expected binary size loaded"

# die must exit non-zero and print to stderr
if ( die "boom" ) 2>/dev/null; then
  fail "die should exit non-zero"
else
  pass "die exits non-zero"
fi

finish_tests
