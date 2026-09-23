#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

get_php_versions() {
	QUESTION=${1:-}
	local PHP_LIST=()
	local preset="${PHP_VERSION:-}"

	PHP_LIST=($(curl -fs 'https://www.php.net/releases/index.php?json' | jq -r '.[].supported_versions[]' | sort -Vr | uniq))

	if [[ -n "$preset" ]]; then
		PHP_VERSION="$preset"
		return 0
	fi

	PHP_VERSION="${PHP_LIST[1]}"

	if [[ -z "${PHP_VERSION:-}" ]]; then
		if [[ ${QUESTION:-} == "default" ]]; then
			PHP_VERSION="${PHP_LIST[1]}"
		else
			ECHO_ENTER "Enter PHP_VERSION [default '$PHP_VERSION']"

			print_list "${PHP_LIST[@]}"

			choice=$(GET_USER_INPUT "select_one_of")
			choice=${choice%.*}

			if [ -z "$choice" ]; then
				choice=-1
				PHP_VERSION="${PHP_LIST[1]}"
			else
				if (("$choice" > 0 && "$choice" <= ${#PHP_LIST[@]})); then
					PHP_VERSION="${PHP_LIST[$(($choice - 1))]}"
				else
					PHP_VERSION="${PHP_LIST[1]}"
					ECHO_WARN_RED "This version of PHP does not support"
					ECHO_GREEN "Set default version: $PHP_VERSION"
					EMPTY_LINE
				fi
			fi
		fi
	fi
}
