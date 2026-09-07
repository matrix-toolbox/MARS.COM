#!/usr/bin/env bash
# Runs every tests/test-*.sh and reports a combined result.
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

failed=0
for t in test-*.sh; do
  printf '\n\033[1m%s\033[0m\n' "$t"
  bash "$t" || failed=$((failed + 1))
done

printf '\n'
if [ "$failed" -ne 0 ]; then
  printf '\033[1;31m%d test file(s) failed\033[0m\n' "$failed"
  exit 1
fi
printf '\033[1;32mAll test files passed\033[0m\n'
