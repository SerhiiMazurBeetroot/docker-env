#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

database_import() {
    if [ "$(docker ps --format '{{.Names}}' | grep -E '(^|_|-)'$DOCKER_CONTAINER_DB'($)')" ]; then
        ECHO_GREEN "Wordpress and DB container exists"

        ECHO_GREEN "PROJECT_DATABASE_DIR: $PROJECT_DATABASE_DIR"

        if [[ -d "$PROJECT_DATABASE_DIR" ]]; then
            ECHO_YELLOW "Getting DB from '/wp-database/' and updating local"
            get_db_file

            if [[ "$DB_FILE" ]]; then
                get_db_name
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
                        docker exec -i "$DOCKER_CONTAINER_DB" bash -l -c "mysqladmin drop $DB_NAME -f -uroot -p$MYSQL_ROOT_PASSWORD"

                        # Create empty DB
                        docker exec -i "$DOCKER_CONTAINER_DB" bash -l -c "mysqladmin create $DB_NAME -f -uroot -p$MYSQL_ROOT_PASSWORD"

                        # Import DB
                        docker exec -i "$DOCKER_CONTAINER_DB" bash -l -c "mysql -uroot -p"$MYSQL_ROOT_PASSWORD" "$MYSQL_DATABASE" < /docker-entrypoint-initdb.d/dump.sql"

                        ECHO_SUCCESS "DB dump for inserted [$PROJECT_ROOT_DIR]"

                        database_search_replace
                    else
                        sleep 5
                        check_db_exists
                        ECHO_YELLOW "Trying to insert DB, awaiting MariaDB container..."

                        if [ $DB_EXISTS ]; then
                            # Drop DB
                            docker exec -i "$DOCKER_CONTAINER_DB" bash -l -c "mysqladmin drop $DB_NAME -f -uroot -p$MYSQL_ROOT_PASSWORD"
                        fi

                        if [ ! $DB_EXISTS ]; then
                            # Create empty DB
                            docker exec -i "$DOCKER_CONTAINER_DB" bash -l -c "mysqladmin create $DB_NAME -f -uroot -p$MYSQL_ROOT_PASSWORD"
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
