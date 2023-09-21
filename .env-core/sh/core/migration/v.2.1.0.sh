#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

migrate_instances_2_1_0() {
    DB_USER="root"
    DB_PASSWORD="PassWorD123"
    DB_NAME="docker_env"

    # Variables
    LOG_FILE="./.env-core/data/instances.log"
    DB_CONTAINER="nginx-db"
    MYSQL_ROOT_USER="root"
    MYSQL_ROOT_PASSWORD="PassWorD123"
    MYSQL_DATABASE="docker_env"
    TABLE_NAME="instances"
    COLUMN_NAME="PORT"

    SQL_ARRAY=()

    # Read the log file line by line
    while IFS="|" read -r PORT STATUS DOMAIN_NAME DOMAIN_FULL DB_NAME DB_TYPE PROJECT_TYPE PORT_FRONT; do
        # Trim leading/trailing whitespace from each field
        PORT=$(echo "$PORT" | tr -d '[:space:]')
        STATUS=$(echo "$STATUS" | tr -d '[:space:]')
        DOMAIN_NAME=$(echo "$DOMAIN_NAME" | tr -d '[:space:]')
        DOMAIN_FULL=$(echo "$DOMAIN_FULL" | tr -d '[:space:]')
        DB_NAME=$(echo "$DB_NAME" | tr -d '[:space:]')
        DB_TYPE=$(echo "$DB_TYPE" | tr -d '[:space:]')
        PROJECT_TYPE=$(echo "$PROJECT_TYPE" | tr -d '[:space:]')
        PORT_FRONT=$(echo "$PORT_FRONT" | tr -d '[:space:]')

        # Skip the header line
        if [[ $PORT == "3309" ]]; then
            continue
        fi

        INSERT_SQL="INSERT INTO instances (PORT, STATUS, DOMAIN_NAME, DOMAIN_FULL, DB_NAME, DB_TYPE, PROJECT_TYPE, PORT_FRONT) VALUES ('$PORT', '$STATUS', '$DOMAIN_NAME', '$DOMAIN_FULL', '$DB_NAME', '$DB_TYPE', '$PROJECT_TYPE', '$PORT_FRONT');"
        SQL_ARRAY+=("$INSERT_SQL")
    done <"$LOG_FILE"

    for sql_statement in "${SQL_ARRAY[@]}"; do
        PORT=$(echo "$sql_statement" | grep -o "'[0-9]*'" | sed "s/'//g")
        value_exists=$(docker exec -i "$DB_CONTAINER" sh -c "mysql -u$MYSQL_ROOT_USER -p$MYSQL_ROOT_PASSWORD -e \"USE $MYSQL_DATABASE; SELECT COUNT(*) FROM $TABLE_NAME WHERE $COLUMN_NAME = '$PORT';\" | awk 'NR==2 {print \$1}'")

        if [[ "$value_exists" =~ ^[0-9]+$ ]]; then
            if [ "$value_exists" == 0 ]; then
                docker exec -i "$DB_CONTAINER" sh -c "mysql -u$MYSQL_ROOT_USER -p$MYSQL_ROOT_PASSWORD -D$MYSQL_DATABASE -e \"$sql_statement\""
            fi
        fi
    done
}
