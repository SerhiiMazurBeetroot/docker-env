#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

database_auto_backup() {
	[[ "${DOMAIN_NAME:-}" == '' ]] && running_projects_list "========= STOP project ========"

	if [ "$(docker ps --format '{{.Names}}' | grep -E '(^|_|-)'$DOCKER_CONTAINER_DB'($)')" ]; then
		get_db_name

		if [ "$DB_NAME" ]; then
			ECHO_YELLOW "Creating DB dump..."

			TIMESTAMP=$(date +"%Y-%m-%d-%H%M%S")

			#DUMP_FILE
			DUMP_FILE=dump-$DB_NAME-$TIMESTAMP.sql

			database_create_dump
		fi
	fi

}
