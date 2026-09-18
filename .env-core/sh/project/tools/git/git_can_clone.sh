#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

git_can_clone() {
	msg=${1:-}

	EMPTY_LINE
	fix_permissions

	EMPTY_LINE
	ECHO_YELLOW "$msg"
	read -rp "Clone from repo (url): " URL_CLONE
	while [ -z "$URL_CLONE" ]; do
		read -rp "Please complete the cloning path: " URL_CLONE
	done

	if [[ "${URL_CLONE}" == *"git@"* ]]; then
		# replace : => /
		URL_CORRECT=${URL_CLONE//:/\/}
		# replace git@ => https://
		URL_CORRECT=${URL_CORRECT/git@/https://}
	else
		URL_CORRECT=$URL_CLONE
	fi

	if ! is_https_or_git_url "$URL_CLONE"; then
		ECHO_ERROR "Only https:// or git@ clone URLs are allowed"
		export CAN_CLONE=0
		return 1
	fi

	# Checking URL
	if curl --output /dev/null --silent --head --fail -- "$URL_CORRECT"; then
		ECHO_SUCCESS "URL EXISTS"
		export CAN_CLONE=1
	else
		ECHO_WARN_YELLOW "URL NOT EXISTS"
		ECHO_ERROR "Path is not correct"
		export CAN_CLONE=0
		exit
	fi
}
