#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

# Newest published release for a typed major or full version.
# 12, 12.0, and 12.x mean the newest Laravel 12. An exact 12.12.2 is kept.
laravel_resolve_version() {
	local want="$1"
	shift
	local -a versions=("$@")
	local version major

	want="${want#v}"
	want="${want%.x}"
	want="${want%.\*}"

	for version in "${versions[@]}"; do
		if [[ "$version" == "$want" ]]; then
			printf '%s' "$version"
			return 0
		fi
	done

	if [[ "$want" =~ ^([0-9]+)(\.0)?(\.0)?$ ]]; then
		major="${BASH_REMATCH[1]}"
		for version in "${versions[@]}"; do
			if [[ "$version" == "$major."* ]]; then
				printf '%s' "$version"
				return 0
			fi
		done
	elif [[ "$want" =~ ^([0-9]+)\.([1-9][0-9]*)$ ]]; then
		local prefix="${BASH_REMATCH[1]}.${BASH_REMATCH[2]}."
		for version in "${versions[@]}"; do
			if [[ "$version" == "$prefix"* ]]; then
				printf '%s' "$version"
				return 0
			fi
		done
	fi

	return 1
}

get_laravel_version() {
	QUESTION=${1:-}
	# shellcheck disable=SC2207
	local -a ALL=()
	local -a LIST=()
	local preset="${LARAVEL_VERSION:-}"
	local version major seen choice resolved

	ALL=($(curl -fs 'https://repo.packagist.org/p2/laravel/laravel.json' | jq -r '.packages["laravel/laravel"][].version | sub("^v";"")' | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$'))

	if ((${#ALL[@]} == 0)); then
		ECHO_WARN_RED "Could not read Laravel versions from Packagist. Composer will install the latest release."
		return 0
	fi

	seen=" "
	for version in "${ALL[@]}"; do
		major="${version%%.*}"
		if [[ "$seen" != *" $major "* ]]; then
			seen+="$major "
			LIST+=("$version")
		fi
		if ((${#LIST[@]} >= 3)); then
			break
		fi
	done

	LARAVEL_VERSION="${LIST[0]}"

	if [[ -n "$preset" ]]; then
		if resolved=$(laravel_resolve_version "$preset" "${ALL[@]}"); then
			LARAVEL_VERSION="$resolved"
		fi
		return 0
	fi

	if [[ ${QUESTION:-} == "default" || ${TEST_RUNNING:-0} -eq 1 ]]; then
		return 0
	fi

	ECHO_ENTER "Enter LARAVEL_VERSION [default '$LARAVEL_VERSION']"
	print_list "${LIST[@]}"
	ECHO_YELLOW "Type 12 for the newest Laravel 12. You do not need the patch number."

	choice=$(GET_USER_INPUT "select_one_of")

	if [[ -z "$choice" ]]; then
		LARAVEL_VERSION="${LIST[0]}"
	elif [[ "$choice" =~ ^[0-9]+$ ]] && (("$choice" > 0 && "$choice" <= ${#LIST[@]})); then
		LARAVEL_VERSION="${LIST[$((choice - 1))]}"
	elif resolved=$(laravel_resolve_version "$choice" "${ALL[@]}"); then
		LARAVEL_VERSION="$resolved"
		ECHO_GREEN "Set version: $LARAVEL_VERSION"
	else
		ECHO_WARN_RED "Invalid choice or version. Using default version: $LARAVEL_VERSION"
		ECHO_GREEN "Set default version: $LARAVEL_VERSION"
		EMPTY_LINE
	fi
}
