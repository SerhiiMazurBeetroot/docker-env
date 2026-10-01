#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

wp_site_empty() {
	local mode="${1:-}"
	local agree=""
	local installed=0
	local empty_all=0

	if [[ "$mode" == "ask" ]]; then
		ECHO_ATTENTION "The following command will remove default posts, pages, plugins, themes"
		agree=$(GET_USER_INPUT "question" "Are you sure?")

		if [[ "$agree" != "y" ]]; then
			return 0
		fi

		if [[ -z "${DOMAIN_NAME:-}" ]]; then
			running_projects_list "==== Delete site content ====" || return 1
		fi

		EMPTY_POSTS=$(GET_USER_INPUT "question" "Do you want to remove posts?")
		EMPTY_THEMES=$(GET_USER_INPUT "question" "Do you want to remove default themes?")
		EMPTY_PLUGINS=$(GET_USER_INPUT "question" "Do you want to remove default plugins?")
	elif [[ "${EMPTY_CONTENT:-}" == "yes" ]]; then
		empty_all=1
	else
		return 0
	fi

	if docker exec -i "$DOCKER_CONTAINER_APP" wp core is-installed --allow-root >/dev/null 2>&1; then
		installed=1
	fi

	if [[ "$installed" -ne 1 ]]; then
		ECHO_ERROR "WordPress is not installed"
		return 1
	fi

	if [[ "$empty_all" -ne 1 && "$agree" != "y" ]]; then
		return 0
	fi

	database_auto_backup

	if [[ "$empty_all" -eq 1 || "${EMPTY_POSTS:-}" == "y" ]]; then
		docker exec -i "$DOCKER_CONTAINER_APP" sh -c 'wp site empty --yes --allow-root'
	fi

	if [[ "$empty_all" -eq 1 || "${EMPTY_THEMES:-}" == "y" ]]; then
		docker exec -i "$DOCKER_CONTAINER_APP" sh -c 'wp theme delete twentynineteen twentytwenty twentytwentyone twentytwentytwo --allow-root'

		docker exec -i "$DOCKER_CONTAINER_APP" sh -c 'wp rewrite structure '/%postname%/' --hard --allow-root'
		docker exec -i "$DOCKER_CONTAINER_APP" sh -c 'wp rewrite flush --hard --allow-root'
	fi

	if [[ "$empty_all" -eq 1 || "${EMPTY_PLUGINS:-}" == "y" ]]; then
		docker exec -i "$DOCKER_CONTAINER_APP" sh -c 'wp plugin delete hello akismet --allow-root'
	fi
}
