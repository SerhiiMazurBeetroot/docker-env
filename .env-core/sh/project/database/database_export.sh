#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

database_export() {
	if [ "$(docker ps --format '{{.Names}}' | grep -E '(^|_|-)'$DOCKER_CONTAINER_DB'($)')" ]; then
		get_db_info

		if [ "$DB_NAME" ]; then
			TIMESTAMP=$(date +"%Y-%m-%d-%H%M%S")

			#DUMP_FILE
			EMPTY_LINE
			file1=$DB_NAME.sql
			file2=dump-$DB_NAME-$TIMESTAMP.sql
			ECHO_GREEN "[1] $file1"
			ECHO_GREEN "[2] $file2 [default]"

			DUMP_FILE=$(GET_USER_INPUT "select_one_of")

			if [[ ! "$DUMP_FILE" =~ [1-2] ]]; then
				DUMP_FILE="$file2"
			elif [[ "$DUMP_FILE" -eq 1 ]]; then
				DUMP_FILE="$file1"
			elif [[ "$DUMP_FILE" -eq 2 ]]; then
				DUMP_FILE="$file2"
			fi

			EMPTY_LINE
			ECHO_TEXT "The dump file will be saved as: $DUMP_FILE."

			database_create_dump
		fi
	else
		ECHO_ERROR "Container not running"
	fi
}
