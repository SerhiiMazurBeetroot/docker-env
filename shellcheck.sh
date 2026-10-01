#!/bin/bash

# Warning-level shellcheck for the scripts the CLI sources.
# sh/dev is local scratch and is not sourced.

set -euo pipefail

root=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
cd "$root"

files=()
while IFS= read -r file; do
	[[ -n "$file" ]] && files+=("$file")
done < <(find .env-core/sh setup.sh -name '*.sh' -not -path '*/sh/dev/*' | sort)

if [[ ${#files[@]} -eq 0 ]]; then
	echo "No shell scripts found" >&2
	exit 1
fi

if command -v shellcheck >/dev/null 2>&1; then
	exec shellcheck -s bash -S warning "${files[@]}"
fi

exec docker run --rm -v "$PWD:/mnt" -w /mnt koalaman/shellcheck:stable -s bash -S warning "${files[@]}"
