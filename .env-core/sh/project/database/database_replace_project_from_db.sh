#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

database_replace_project_from_db() {
	if [[ -d "$PROJECT_DATABASE_DIR" ]]; then
		EMPTY_LINE
		ECHO_YELLOW "Replace project from DB..."

		DOMAIN_FULL=$(instances_get domain_full)

		PREV_INSTANCES=$(instances_line)
		PREV_DB_NAME=$(instances_get db_name)

		# DB_FILE
		get_db_file

		# DB_NAME case 1
		NEW_DB_NAME=$(grep 'Database:' "$PROJECT_DATABASE_DIR/$DB_FILE" | head -n 1 | grep -o '[A-Za-z0-9.,-_]\+[`]' | tr -d \` || true)

		# DB_NAME case 2 (Cyrillic letters)
		if [[ "$NEW_DB_NAME" == '' ]]; then
			NEW_DB_NAME=$(grep -e 'База данных:' "$PROJECT_DATABASE_DIR/$DB_FILE" | head -n 1 | awk '/''/{print $4}' | tr -d \` || true)
		fi

		# DB_NAME case 3 (file without description), get DB_NAME from file name
		if [[ "$NEW_DB_NAME" == '' ]]; then
			NEW_DB_NAME="$(basename "$DB_FILE" | sed 's/.sql//g')"
		fi

		# TABLE_PREFIX
		NEW_TABLE_PREFIX=$(grep 'CREATE TABLE' "$PROJECT_DATABASE_DIR/$DB_FILE" | grep -o '[`][A-Za-z0-9_]\+[_comments]\+[`]' | awk '/'_comments'/{print}' | head -n 1 | sed 's/comments//g' | tr -d \`)

		# Replace instances.log
		instances_set_field db_name "$NEW_DB_NAME"

		# Replace .env
		PREV_DB_ENV=$(awk '/'MYSQL_DATABASE'/{print}' $PROJECT_DOCKER_DIR/.env | head -n 1)
		PREV_TABLE_PREFIX=$(awk '/'TABLE_PREFIX'/{print}' $PROJECT_DOCKER_DIR/.env | head -n 1)
		sed_inplace "s|^MYSQL_DATABASE=.*$|MYSQL_DATABASE='$NEW_DB_NAME'|" "$PROJECT_DOCKER_DIR/.env"
		sed_inplace "s|^TABLE_PREFIX=.*$|TABLE_PREFIX='$NEW_TABLE_PREFIX'|" "$PROJECT_DOCKER_DIR/.env"

		ECHO_KEY_VALUE "PREV_INSTANCES:" "$PREV_INSTANCES"
		ECHO_KEY_VALUE "NEW_INSTANCES:" "$(instances_line)"
	else
		ECHO_ERROR "DB DIR doesn't exists"

	fi
}
