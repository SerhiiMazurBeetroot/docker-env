#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

database_import() {
	if [ "$(docker ps --format '{{.Names}}' | grep -E '(^|_|-)'$DOCKER_CONTAINER_DB'($)')" ]; then
		ECHO_GREEN "App and DB container exists"

		ECHO_GREEN "PROJECT_DATABASE_DIR: $PROJECT_DATABASE_DIR"

		if [[ -d "$PROJECT_DATABASE_DIR" ]]; then
			ECHO_YELLOW "Getting DB from '/database/' and updating local"
			get_db_file

			if [[ "$DB_FILE" ]]; then
				get_db_info
				env_file_load

				ECHO_GREEN "DB collected, inserting it to the SQL container"
				dbstatus=1
				while [[ $dbstatus != [0] ]]; do
					check_db_exists

					if [ $DB_EXISTS ]; then
						dbstatus=0
						ECHO_GREEN "DB found"

						docker cp "$PROJECT_DATABASE_DIR/$DB_FILE" "$DOCKER_CONTAINER_DB":/docker-entrypoint-initdb.d/dump.sql

						# Drop DB
						case $DB_TYPE in
						"MYSQL")
							docker exec -e MYSQL_PWD="${MYSQL_ROOT_PASSWORD:-}" -i "$DOCKER_CONTAINER_DB" bash -l -c "$MYSQL_ADMIN_CMD drop $DB_NAME -f -uroot"
							;;
						esac

						# Create empty DB
						case $DB_TYPE in
						"MYSQL")
							docker exec -e MYSQL_PWD="${MYSQL_ROOT_PASSWORD:-}" -i "$DOCKER_CONTAINER_DB" bash -l -c "$MYSQL_ADMIN_CMD create $DB_NAME -f -uroot"
							;;
						esac

						# Import DB
						case $DB_TYPE in
						"MYSQL")
							docker exec -e MYSQL_PWD="${MYSQL_ROOT_PASSWORD:-}" -i "$DOCKER_CONTAINER_DB" bash -l -c "$MYSQL_CMD -uroot \"$MYSQL_DATABASE\" < /docker-entrypoint-initdb.d/dump.sql"
							;;
						"POSTGRES")
							docker exec -i "$DOCKER_CONTAINER_DB" bash -c "$(declare -f database_import_postgres); database_import_postgres $DB_NAME $DB_USER"
							;;
						esac

						ECHO_SUCCESS "DB dump for inserted [$PROJECT_ROOT_DIR]"

						database_search_replace
					else
						sleep 5
						ECHO_YELLOW "Trying to insert DB, awaiting MariaDB container..."
						check_db_exists

						if [ $DB_EXISTS ]; then
							# Drop DB
							case $DB_TYPE in
							"MYSQL")
								docker exec -e MYSQL_PWD="${MYSQL_ROOT_PASSWORD:-}" -i "$DOCKER_CONTAINER_DB" bash -l -c "$MYSQL_ADMIN_CMD drop $DB_NAME -f -uroot"
								;;
							esac
						fi

						if [ ! $DB_EXISTS ]; then
							# Create empty DB
							case $DB_TYPE in
							"MYSQL")
								docker exec -e MYSQL_PWD="${MYSQL_ROOT_PASSWORD:-}" -i "$DOCKER_CONTAINER_DB" bash -l -c "$MYSQL_ADMIN_CMD create $DB_NAME -f -uroot"
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
