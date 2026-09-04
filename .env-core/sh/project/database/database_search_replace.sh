#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

database_search_replace() {
	case $DB_TYPE in
	"MYSQL")
		perform_mysql_search_replace
		;;
	esac
}

perform_mysql_search_replace() {
	check_domain_exists

	if [[ $DOMAIN_EXISTS == 1 ]]; then
		while true; do
			yn=$(GET_USER_INPUT "question" "Run search-replace?")

			case $yn in
			[Yy]*)
				read -rp "Enter search term: " search
				read -rp "Enter replace term: " replace

				ECHO_YELLOW "Running search-replace from $search to $replace. This might take a while!"

				docker exec -i "$DOCKER_CONTAINER_APP" sh -c "exec wp search-replace --all-tables '$search' '$replace' --allow-root"

				if [ $? -eq 0 ]; then
					ECHO_SUCCESS "Search-replace completed successfully."
				else
					ECHO_ERROR "Error occurred during search-replace operation."
				fi
				;;
			[Nn]*) break ;;
			*) ECHO_ERROR "Please answer [y/n]" ;;
			esac
		done
	fi
}
