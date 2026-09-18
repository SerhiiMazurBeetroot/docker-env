#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

git_save_token_github() {
	read -rsp "Github token: " TOKEN_GITHUB
	echo
	[[ $TOKEN_GITHUB != '' ]] && save_settings "TOKEN_GITHUB=$TOKEN_GITHUB"
}

git_save_user_github() {
	read -rp "Github user: " USER_GITHUB
	[[ $USER_GITHUB != '' ]] && save_settings "USER_GITHUB=$USER_GITHUB"
}

git_create_repo_github() {
	TOKEN_GITHUB=$(awk -F= '/^TOKEN_GITHUB=/{print $2}' "$FILE_SETTINGS")
	USER_GITHUB=$(awk -F= '/^USER_GITHUB=/{print $2}' "$FILE_SETTINGS")

	[[ $TOKEN_GITHUB == '' ]] && git_save_token_github || true
	[[ $USER_GITHUB == '' ]] && git_save_user_github || true

	if [[ $TOKEN_GITHUB && $USER_GITHUB ]]; then
		ECHO_ENTER "Enter REPO_TYPE [default '1']"
		ECHO_GREEN "1 - Private"
		ECHO_GREEN "2 - Public"

		REPO_TYPE=$(GET_USER_INPUT "select_one_of")

		REPO_NAME="$DOMAIN_NAME"

		[[ $REPO_TYPE == 1 ]] && REPO_TYPE="private"
		[[ $REPO_TYPE == 2 ]] && REPO_TYPE="public"

		response=$(
			curl -sS -o /dev/null -w "%{http_code}" -X POST https://api.github.com/user/repos \
				-H "Authorization: Bearer $TOKEN_GITHUB" \
				-H "Accept: application/vnd.github+json" \
				-d @- <<EOF
{
  "name": "$REPO_NAME",
  "description": "Project $REPO_NAME",
  "$REPO_TYPE": true
}
EOF
		)

		if [[ $response == "201" || $response == "200" ]]; then
			ECHO_SUCCESS "Github"

			cd "$PROJECT_ROOT_DIR" || return 1

			if [[ -d "${PWD}/.git" ]]; then
				ECHO_YELLOW "Push Origin Master..."
				git_push_origin_with_token "$TOKEN_GITHUB"
			else
				ECHO_YELLOW "Creating Repository..."

				git init
				git add .
				git commit -m "initial commit"
				git branch -M master
				git remote add origin "https://github.com/${USER_GITHUB}/${REPO_NAME}.git"
				git_push_origin_with_token "$TOKEN_GITHUB"
			fi

			cd ../../
		else
			ECHO_ERROR "Github: HTTP $response"
		fi
	else
		ECHO_ATTENTION "Please fill in your access information"
	fi
}
