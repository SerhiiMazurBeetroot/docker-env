#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

# Get the last *.sql file
get_db_file() {
    SQL_FILES=("$PROJECT_DATABASE_DIR"/*.sql)

    for file in "${SQL_FILES[@]}"; do
        DB_FILE="$(basename "$file")"
    done
}

get_db_name() {
    DB_NAME=$(awk '/'" $DOMAIN_NAME "'/{print $9}' "$FILE_INSTANCES" | head -n 1)

    if [ "$DB_NAME" ]; then
        DOMAIN_NAME=$(awk '/'" $DOMAIN_NAME "'/{print $5}' "$FILE_INSTANCES" | head -n 1)
    else
        ECHO_ERROR "Dite not exists"
    fi
}

check_db_exists() {
    DB_EXISTS=$(docker exec -i "$DOCKER_CONTAINER_DB" sh -c 'mysql -uroot -p"$MYSQL_ROOT_PASSWORD" --execute "show databases"' | grep -Eo $DB_NAME || true)
}
