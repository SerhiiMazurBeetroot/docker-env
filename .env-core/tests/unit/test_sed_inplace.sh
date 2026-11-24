#!/bin/bash

# BSD sed (macOS) reads `sed -i -e …` as "back up with suffix -e" and leaves
# files like settings.log-e next to the data. Every in-place edit goes through
# sed_inplace in core/helpers.sh, which picks the right form per platform.

unit_source "core/core_helpers.sh"

bare=$(grep -rnE '(^|[^_[:alnum:]])sed[[:space:]]+([^|;&]*[[:space:]])?-[[:alnum:]]*i' "$UNIT_ROOT/.env-core/sh" \
	--include='*.sh' | grep -v '/sh/core/core_helpers.sh:' | grep -v '/sh/dev/' || true)
assert_eq "" "$bare" "no bare sed -i outside sed_inplace"

file="$UNIT_TMP/sed_inplace.txt"
printf 'KEY=old\nOTHER=1\n' >"$file"
sed_inplace 's/^KEY=.*/KEY=new/' "$file"
assert_eq "KEY=new" "$(head -n 1 "$file")" "sed_inplace edits the file"
leftovers=$(find "$UNIT_TMP" -maxdepth 1 -name 'sed_inplace.txt?*' | wc -l | tr -d ' ')
assert_eq "0" "$leftovers" "sed_inplace leaves no backup file"
