#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

database_import() {
	local attempts=0
	local max_attempts=24
	local db_target=""

	if [ "$(docker ps --format '{{.Names}}' | grep -E '(^|_|-)'$DOCKER_CONTAINER_DB'($)')" ]; then
		ECHO_GREEN "App and DB container exists"

		ECHO_GREEN "PROJECT_DATABASE_DIR: $PROJECT_DATABASE_DIR"

		if [[ -d "$PROJECT_DATABASE_DIR" ]]; then
			ECHO_YELLOW "Getting DB from '/database/' and updating local"
			get_db_file

			if [[ "$DB_FILE" ]]; then
				get_db_info
				env_file_load
				_db_shell_mysql_password
				get_mysql_cmd

				ECHO_GREEN "DB collected, inserting it to the SQL container"
				if [[ "$DB_TYPE" == "MYSQL" ]] && ! database_wait_mysql_ready 30; then
					ECHO_ERROR "Database not ready for import"
					return 1
				fi

				dbstatus=1
				attempts=0
				while [[ "$dbstatus" != "0" ]]; do
					check_db_exists

					if [[ -n "${DB_EXISTS:-}" ]]; then
						dbstatus=0
						ECHO_GREEN "DB found"

						docker cp "$PROJECT_DATABASE_DIR/$DB_FILE" "$DOCKER_CONTAINER_DB":/docker-entrypoint-initdb.d/dump.sql

						case $DB_TYPE in
						"MYSQL")
							db_target="${MYSQL_DATABASE:-${DB_NAME:-}}"
							docker exec -e MYSQL_PWD="${MYSQL_ROOT_PASSWORD:-}" -i "$DOCKER_CONTAINER_DB" \
								sh -c "$MYSQL_ADMIN_CMD -h 127.0.0.1 -uroot drop $(printf '%q' "$DB_NAME") -f"
							docker exec -e MYSQL_PWD="${MYSQL_ROOT_PASSWORD:-}" -i "$DOCKER_CONTAINER_DB" \
								sh -c "$MYSQL_ADMIN_CMD -h 127.0.0.1 -uroot create $(printf '%q' "$DB_NAME") -f"
							docker exec -e MYSQL_PWD="${MYSQL_ROOT_PASSWORD:-}" -i "$DOCKER_CONTAINER_DB" \
								sh -c "$MYSQL_CMD -h 127.0.0.1 -uroot $(printf '%q' "$db_target") < /docker-entrypoint-initdb.d/dump.sql"
							;;
						"POSTGRES")
							database_import_postgres "$DB_NAME" "$DB_USER" || return 1
							;;
						esac

						ECHO_SUCCESS "DB dump for inserted [$PROJECT_ROOT_DIR]"

						database_search_replace
					else
						attempts=$((attempts + 1))
						if ((attempts >= max_attempts)); then
							ECHO_ERROR "Database did not become ready"
							return 1
						fi

						sleep 5
						ECHO_YELLOW "Trying to insert DB, awaiting MariaDB container... (${attempts}/${max_attempts})"
						check_db_exists

						if [[ -n "${DB_EXISTS:-}" ]]; then
							case $DB_TYPE in
							"MYSQL")
								docker exec -e MYSQL_PWD="${MYSQL_ROOT_PASSWORD:-}" -i "$DOCKER_CONTAINER_DB" \
									sh -c "$MYSQL_ADMIN_CMD -h 127.0.0.1 -uroot drop $(printf '%q' "$DB_NAME") -f"
								;;
							esac
						fi

						if [[ -z "${DB_EXISTS:-}" ]]; then
							case $DB_TYPE in
							"MYSQL")
								docker exec -e MYSQL_PWD="${MYSQL_ROOT_PASSWORD:-}" -i "$DOCKER_CONTAINER_DB" \
									sh -c "$MYSQL_ADMIN_CMD -h 127.0.0.1 -uroot create $(printf '%q' "$DB_NAME") -f"
								;;
							esac
						fi
					fi
				done
			else
				ECHO_ERROR "DB dump not found or downloaded"
			fi
		else
			ECHO_ERROR "DB directory not found"
		fi
	else
		ECHO_ERROR "Container not running"
	fi
}
