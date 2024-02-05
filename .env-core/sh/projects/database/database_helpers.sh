#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

# Get the last *.sql file
get_db_file() {
    SQL_FILES=("$PROJECT_DATABASE_DIR"/*.sql)

    for file in "${SQL_FILES[@]}"; do
        DB_FILE="$(basename "$file")"
        db_file_find_and_replace
    done
}

get_db_name() {
    DB_NAME=$(awk '/'" $DOMAIN_NAME "'/{print $9}' "$FILE_INSTANCES" | head -n 1)

    if [ "$DB_NAME" ]; then
        DOMAIN_NAME=$(awk '/'" $DOMAIN_NAME "'/{print $5}' "$FILE_INSTANCES" | head -n 1)
    else
        ECHO_ERROR "Site not exists"
    fi
}

get_db_info() {
    DB_NAME=$(awk '/'" $DOMAIN_NAME "'/{print $9}' "$FILE_INSTANCES" | head -n 1)
    DB_TYPE=$(awk '/'" $DOMAIN_NAME "'/{print $11}' "$FILE_INSTANCES" | head -n 1)

    if [ "$DB_NAME" ]; then
        DOMAIN_NAME=$(awk '/'" $DOMAIN_NAME "'/{print $5}' "$FILE_INSTANCES" | head -n 1)
    else
        ECHO_ERROR "Site not exists"
    fi
}

check_db_exists() {
    case $DB_TYPE in
    "MYSQL")
        get_mysql_cmd

        DB_EXISTS=$(docker exec -i "$DOCKER_CONTAINER_DB" sh -c "$MYSQL_CMD -uroot -p\"$MYSQL_ROOT_PASSWORD\" --execute \"SHOW DATABASES\" | grep -Eo \"$DB_NAME\" || true")
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
    sed -i -e 's/utf8mb4_0900_ai_ci/utf8mb4_unicode_520_ci/g' "$PROJECT_DATABASE_DIR/$DB_FILE"
}
