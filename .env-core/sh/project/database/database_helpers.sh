#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

# Get the last *.sql file
get_db_file() {
	SQL_FILES=("$PROJECT_DATABASE_DIR"/*.sql)

	for file in "${SQL_FILES[@]}"; do
		DB_FILE="$(basename "$file")"
		db_file_find_and_replace
	done
}

get_db_name() {
	DB_NAME=$(instances_get db_name)

	if [ "$DB_NAME" ]; then
		DOMAIN_NAME=$(instances_get domain_name)
	else
		ECHO_ERROR "Site not exists"
	fi
}

get_db_info() {
	DB_NAME=$(instances_get db_name)
	DB_TYPE=$(instances_get db_type)

	if [ "$DB_NAME" ]; then
		DOMAIN_NAME=$(instances_get domain_name)
	else
		ECHO_ERROR "Site not exists"
	fi
}

_db_shell_mysql_password() {
	MYSQL_ROOT_PASSWORD="$(env_file_value MYSQL_ROOT_PASSWORD 2>/dev/null || true)"
}

check_db_exists() {
	case $DB_TYPE in
	"MYSQL")
		_db_shell_mysql_password
		get_mysql_cmd

		DB_EXISTS=$(docker exec -e MYSQL_PWD="${MYSQL_ROOT_PASSWORD:-}" -i "$DOCKER_CONTAINER_DB" \
			sh -c "$MYSQL_CMD -uroot --silent --execute 'SHOW DATABASES'" | grep -Eo "$DB_NAME" || true)
		;;
	"POSTGRES")
		DB_EXISTS=$(docker exec -i "$DOCKER_CONTAINER_DB" psql -U "$DB_USER" -d "$DB_NAME" -tAc "SELECT 1 FROM pg_database WHERE datname='$DB_NAME'" | grep -q "1" && echo true || echo false)
		;;
	esac
}

get_mysql_cmd() {
	# mariadb v.11.0 (mysql is deprecated)
	# https://mariadb.com/kb/en/mariadb-dump/
	# https://i.imgur.com/4ElZqbd.png

	MYSQL_EXISTS=$(docker exec -i "$DOCKER_CONTAINER_DB" sh -c "command -v mysql || true")

	if [ -n "$MYSQL_EXISTS" ]; then
		export MYSQL_CMD="mysql"
		export MYSQL_DUMP_CMD="mysqldump"
		export MYSQL_ADMIN_CMD="mysqladmin"
	else
		export MYSQL_CMD="mariadb"
		export MYSQL_DUMP_CMD="mariadb-dump"
		export MYSQL_ADMIN_CMD="mariadb-admin"
	fi
}

db_file_find_and_replace() {
	sed_inplace 's/utf8mb4_0900_ai_ci/utf8mb4_unicode_520_ci/g' "$PROJECT_DATABASE_DIR/$DB_FILE"
}

wait_for_docker_container() {
	local container="${1:-}"
	local attempts="${2:-90}"
	local i status

	[[ -n "$container" ]] || return 1

	for ((i = 1; i <= attempts; i++)); do
		status=$(docker inspect -f '{{.State.Status}}' "$container" 2>/dev/null || echo "")

		case "$status" in
		running)
			return 0
			;;
		exited | dead)
			ECHO_ERROR "Container $container is $status"
			docker logs "$container" 2>&1 | tail -40 || true
			return 1
			;;
		*)
			sleep 2
			;;
		esac
	done

	ECHO_ERROR "Timeout waiting for container $container (last status: ${status:-missing})"
	docker logs "$container" 2>&1 | tail -40 || true
	return 1
}

wait_for_db() {
	local db_name

	EMPTY_LINE
	get_project_dir "skip_question"

	MYSQL_ROOT_PASSWORD="$(env_file_value MYSQL_ROOT_PASSWORD || true)"
	db_name="$(env_file_value MYSQL_DATABASE || true)"
	[[ -n "$db_name" ]] && DB_NAME="$db_name"

	wait_for_docker_container "$DOCKER_CONTAINER_DB" || return 1
	get_mysql_cmd

	# TCP to 127.0.0.1 — socket /run/mysqld/mysqld.sock is missing until mysqld is up.
	docker exec -e MYSQL_PWD="${MYSQL_ROOT_PASSWORD:-}" -i "$DOCKER_CONTAINER_DB" sh -c "
		until $MYSQL_ADMIN_CMD ping -h 127.0.0.1 -uroot --silent; do
			>&2 echo '$MYSQL_CMD is unavailable - waiting...'
			sleep 2
		done
		until $MYSQL_CMD -h 127.0.0.1 -uroot -D $DB_NAME -e 'SELECT 1' >/dev/null 2>&1; do
			>&2 echo 'database $DB_NAME is unavailable - waiting...'
			sleep 2
		done
	"
}
