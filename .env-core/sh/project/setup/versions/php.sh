#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

get_php_versions() {
	QUESTION=${1:-}
	local PHP_LIST=()
	local preset="${PHP_VERSION:-}"
	local version choice

	while IFS= read -r version; do
		[[ -n "$version" ]] && PHP_LIST+=("$version")
	done < <(curl -fs 'https://www.php.net/releases/index.php?json' 2>/dev/null | jq -r '.[].supported_versions[]' 2>/dev/null | sort -Vr | uniq || true)

	local picked="8.3"
	if ((${#PHP_LIST[@]} > 1)); then
		picked="${PHP_LIST[1]}"
	elif ((${#PHP_LIST[@]} == 1)); then
		picked="${PHP_LIST[0]}"
	fi

	if [[ -n "$preset" ]]; then
		PHP_VERSION="$preset"
		return 0
	fi

	PHP_VERSION="$picked"

	if [[ ${QUESTION:-} == "default" || ${TEST_RUNNING:-0} -eq 1 || ${CLI_NONINTERACTIVE:-0} -eq 1 ]]; then
		if ((${#PHP_LIST[@]} == 0)); then
			ECHO_WARN_RED "Could not read PHP versions. Using ${PHP_VERSION}."
		fi
		return 0
	fi

	ECHO_ENTER "Enter PHP_VERSION [default '$PHP_VERSION']"

	if ((${#PHP_LIST[@]} > 0)); then
		print_list "${PHP_LIST[@]}"
	fi

	choice=$(GET_USER_INPUT "select_one_of")
	choice=${choice%.*}

	if [[ -z "$choice" ]]; then
		PHP_VERSION="$picked"
	elif (("$choice" > 0 && "$choice" <= ${#PHP_LIST[@]})); then
		PHP_VERSION="${PHP_LIST[$((choice - 1))]}"
	else
		PHP_VERSION="$picked"
		ECHO_WARN_RED "This version of PHP does not support"
		ECHO_GREEN "Set default version: $PHP_VERSION"
		EMPTY_LINE
	fi
}
