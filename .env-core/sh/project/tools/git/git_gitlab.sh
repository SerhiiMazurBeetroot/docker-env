#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

git_save_token_gitlab() {
	read -rsp "Gitlab token: " TOKEN_GITLAB
	echo
	[[ $TOKEN_GITLAB != '' ]] && save_settings "TOKEN_GITLAB=$TOKEN_GITLAB"
}

git_save_user_gitlab() {
	read -rp "Gitlab user: " USER_GITLAB
	[[ $USER_GITLAB != '' ]] && save_settings "USER_GITLAB=$USER_GITLAB"
}

git_create_repo_gitlab() {
	TOKEN_GITLAB=$(awk -F= '/^TOKEN_GITLAB=/{print $2}' "$FILE_SETTINGS")
	USER_GITLAB=$(awk -F= '/^USER_GITLAB=/{print $2}' "$FILE_SETTINGS")

	[[ $TOKEN_GITLAB == '' ]] && git_save_token_gitlab || true
	[[ $USER_GITLAB == '' ]] && git_save_user_gitlab || true

	if [[ $TOKEN_GITLAB && $USER_GITLAB ]]; then
		ECHO_ENTER "Enter REPO_TYPE [default '1']"
		ECHO_GREEN "[1] Private"
		ECHO_GREEN "[2] Public"

		REPO_TYPE=$(GET_USER_INPUT "select_one_of")

		REPO_NAME="$DOMAIN_NAME"

		[[ $REPO_TYPE == 1 ]] && REPO_TYPE="private"
		[[ $REPO_TYPE == 2 ]] && REPO_TYPE="public"

		response=$(curl --silent --header "PRIVATE-TOKEN: $TOKEN_GITLAB" \
			-X POST \
			--data-urlencode "name=${REPO_NAME}" \
			--data-urlencode "visibility=${REPO_TYPE}" \
			"https://gitlab.com/api/v4/projects")

		if [[ "$response" == *'"id":'* && "$response" != *'"message"'* ]]; then
			ECHO_SUCCESS "Gitlab"

			cd "$PROJECT_ROOT_DIR" || return 1

			if [[ -d "${PWD}/.git" ]]; then
				ECHO_YELLOW "Push Origin Master..."
				git_push_origin_with_token "$TOKEN_GITLAB"
			else
				ECHO_YELLOW "Creating Repository..."

				git init
				git add .
				git commit -m "initial commit"
				git branch -M master
				git remote add origin "https://gitlab.com/${USER_GITLAB}/${REPO_NAME}.git"
				git_push_origin_with_token "$TOKEN_GITLAB"
			fi

			cd ../../
		else
			ECHO_ERROR "Gitlab: $response"
		fi
	else
		ECHO_ATTENTION "Please fill in your access information"
	fi
}
