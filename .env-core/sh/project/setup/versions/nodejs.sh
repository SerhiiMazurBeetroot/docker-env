#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

get_nodejs_version() {
	QUESTION=${1:-}
	NODE_VERSIONS=($(curl -sL 'https://raw.githubusercontent.com/nodejs/docker-node/main/versions.json' | grep -o '"[0-9]\+": {' | cut -d'"' -f2 | sed 's/: {//'))
	NODE_LATEST_VERSION="${NODE_VERSIONS}"

	if [[ -z "${NODE_VERSION:-}" ]]; then
		if [[ ${QUESTION:-} == "default" ]]; then
			NODE_VERSION="${NODE_VERSIONS[1]}"
		else
			ECHO_ENTER "Enter NODE_VERSION [default '$NODE_LATEST_VERSION']"

			print_list "${NODE_VERSIONS[@]}"

			choice=$(GET_USER_INPUT "select_one_of")
			choice=${choice%.*}

			if [ -z "$choice" ]; then
				choice=-1
				NODE_VERSION="$NODE_LATEST_VERSION"
			else
				if (("$choice" > 0 && "$choice" <= ${#NODE_VERSIONS[@]})); then
					NODE_VERSION="${NODE_VERSIONS[$(($choice - 1))]}"
				else
					EMPTY_LINE
					NODE_VERSION="${NODE_LATEST_VERSION}"
					ECHO_GREEN "Set default version: $NODE_VERSION"
					EMPTY_LINE
				fi
			fi
		fi
	fi
}
