#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

# Shared look for the interactive menus (site, System, Nginx, Web UI):
#   ==== Title · state ====
#   [0] Back
#   [1] Label            grey hint
# Menus build their rows from the current state, so numbers can change between redraws;
# keep a parallel "keys" array and dispatch on the key, not on the number.

menu_header() {
	ECHO_CYAN "==== $* ===="
}

menu_row() {
	local num="$1"
	local label="$2"
	local hint="${3:-}"
	local color="${4:-$GREEN}"

	if [[ -n "$hint" ]]; then
		printf '%b[%s]%b %-16s %b%s%b\n' "$color" "$num" "$NC" "$label" "$CYAN" "$hint" "$NC"
	else
		printf '%b[%s]%b %s\n' "$color" "$num" "$NC" "$label"
	fi
}

# Maps the menu number the user typed to a key from the parallel keys array.
# Prints the key, or nothing for 0 / out-of-range / non-numeric input.
menu_pick_key() {
	local choice="${1:-}"
	shift
	local -a keys=("$@")

	choice="${choice//[[:space:]]/}"
	[[ "$choice" =~ ^[0-9]+$ ]] || return 0
	if ((choice >= 1 && choice <= ${#keys[@]})); then
		printf '%s' "${keys[$((choice - 1))]}"
	fi
}
