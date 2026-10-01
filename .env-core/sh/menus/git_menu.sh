#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

git_menu() {
	while true; do
		EMPTY_LINE
		ECHO_CYAN "========= GIT actions ========="
		ECHO_YELLOW "[0] Return to the previous menu"
		ECHO_GREEN "[1] Clone Project"
		ECHO_GREEN "[2] Clone WP Theme"
		ECHO_GREEN "[3] Create Github repo"
		ECHO_GREEN "[4] Create Gitlab repo"
		ECHO_GREEN "[5] Repo access"

		actions=$(GET_USER_INPUT "select_one_of")

		case $actions in
		0)
			return 0
			;;
		1)
			git_clone_project
			unset_variables
			;;
		2)
			git_clone_theme
			unset_variables
			;;
		3)
			get_existing_domains "====== Create Github Repo =====" || continue
			git_create_repo_github
			unset_variables
			;;
		4)
			get_existing_domains "====== Create GitLab Repo =====" || continue
			git_create_repo_gitlab
			unset_variables
			;;
		5)
			git_save_access
			;;
		esac
	done
}
