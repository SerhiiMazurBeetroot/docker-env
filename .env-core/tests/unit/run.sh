#!/usr/bin/env bash

# Fast unit tests for pure shell helpers (no Docker).

set -uo pipefail

UNIT_DIR="$(cd "$(dirname "$0")" && pwd)"

# shellcheck disable=SC1091
source "$UNIT_DIR/bootstrap.sh"
# shellcheck disable=SC1091
source "$UNIT_DIR/assert.sh"

echo "docker-env unit tests"

for file in "$UNIT_DIR"/test_*.sh; do
	[[ -f "$file" ]] || continue
	echo "==> $(basename "$file")"
	set +o errexit
	# shellcheck disable=SC1090
	source "$file" || true
done

unit_summary
