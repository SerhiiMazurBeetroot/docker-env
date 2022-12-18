#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

database_replace_project_from_db() {
    get_project_dir "skip_question"

    if [[ -d "$PROJECT_DATABASE_DIR" ]]; then
        EMPTY_LINE
        ECHO_YELLOW "Replace project from DB..."

        DOMAIN_FULL=$(awk '/'" $DOMAIN_NAME "'/{print $7}' "$FILE_INSTANCES" | head -n 1)

        PREV_INSTANCES=$(awk '/'" $DOMAIN_NAME "'/{print}' "$FILE_INSTANCES" | head -n 1)
        PREV_DB_NAME=$(awk '/'" $DOMAIN_NAME "'/{print $9}' "$FILE_INSTANCES" | head -n 1)

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
        FIND_DB_NAME='\| '"$PREV_DB_NAME"' \|'
        REPLACE_DB_NAME='\| '"$NEW_DB_NAME"' |'
        NEW_INSTANCES=$(echo $PREV_INSTANCES | sed -r 's/'"$FIND_DB_NAME"'/'"$REPLACE_DB_NAME"'/')
        sed -i -e 's/'"$PREV_INSTANCES"'/'"$NEW_INSTANCES"'/g' "$FILE_INSTANCES"

        # Replace .env
        PREV_DB_ENV=$(awk '/'MYSQL_DATABASE'/{print}' $PROJECT_DOCKER_DIR/.env | head -n 1)
        PREV_TABLE_PREFIX=$(awk '/'TABLE_PREFIX'/{print}' $PROJECT_DOCKER_DIR/.env | head -n 1)
        sed -i -e 's/'"$PREV_DB_ENV"'/'"MYSQL_DATABASE='$NEW_DB_NAME'"'/g' $PROJECT_DOCKER_DIR/.env
        sed -i -e 's/'"$PREV_TABLE_PREFIX"'/'"TABLE_PREFIX='$NEW_TABLE_PREFIX'"'/g' $PROJECT_DOCKER_DIR/.env

        ECHO_KEY_VALUE "PREV_INSTANCES:" "$PREV_INSTANCES"
        ECHO_KEY_VALUE "NEW_INSTANCES:" "$NEW_INSTANCES"
    else
        ECHO_ERROR "DB DIR doesn't exists"

    fi
}
