#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

get_directus_version() {
	QUESTION=${1:-}
	# shellcheck disable=SC2207
	local LIST=()

	LIST=($(curl -s 'https://api.github.com/repos/directus/directus/tags' | jq -r '.[].name | sub("^v"; "")' | head -n 3))

	if [[ -z "${DIRECTUS_VERSION:-}" ]]; then
		if [[ ${QUESTION:-} == "default" ]]; then
			DIRECTUS_VERSION="${LIST[1]}"
		else
			DIRECTUS_VERSION="${LIST[1]}"
			ECHO_ENTER "Enter DIRECTUS_VERSION [default '$DIRECTUS_VERSION']"

			print_list "${LIST[@]}"

			choice=$(GET_USER_INPUT "select_one_of")
			choice=${choice%.*}

			if [ -z "$choice" ]; then
				choice=-1
				DIRECTUS_VERSION="${LIST[1]}"
			else
				if (("$choice" > 0 && "$choice" <= ${#LIST[@]})); then
					DIRECTUS_VERSION="${LIST[$(($choice - 1))]}"
				else
					ECHO_WARN_RED "Invalid choice or version. Using default version: $DIRECTUS_VERSION"
					ECHO_GREEN "Set default version: $DIRECTUS_VERSION"
					EMPTY_LINE
				fi
			fi
		fi
	fi

	[[ -n "${DIRECTUS_VERSION:-}" ]] || DIRECTUS_VERSION="10.8.2"
}
