#!/usr/bin/env bash
# Minimal assertion helpers. No external test framework dependency.
TESTS_RUN=0
TESTS_FAILED=0

pass() { TESTS_RUN=$((TESTS_RUN + 1)); printf '  \033[0;32mok\033[0m %s\n' "$1"; }

fail() {
  TESTS_RUN=$((TESTS_RUN + 1))
  TESTS_FAILED=$((TESTS_FAILED + 1))
  printf '  \033[0;31mFAIL\033[0m %s\n' "$1"
}

assert_eq() {
  local actual="$1" expected="$2" label="$3"
  if [ "$actual" = "$expected" ]; then
    pass "$label"
  else
    fail "$label (expected '$expected', got '$actual')"
  fi
}

assert_file_exists() {
  if [ -f "$1" ]; then pass "file exists: $1"; else fail "file missing: $1"; fi
}

assert_contains() {
  local file="$1" needle="$2"
  if grep -qF -- "$needle" "$file" 2>/dev/null; then
    pass "$file contains '$needle'"
  else
    fail "$file does not contain '$needle'"
  fi
}

assert_success() {
  if "$@" >/dev/null 2>&1; then pass "command succeeded: $*"; else fail "command failed: $*"; fi
}

finish_tests() {
  printf '\n  %d assertion(s), %d failure(s)\n' "$TESTS_RUN" "$TESTS_FAILED"
  [ "$TESTS_FAILED" -eq 0 ] || exit 1
}
