#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

database_export() {
    get_project_dir "skip_question"

    if [ "$(docker ps --format '{{.Names}}' | grep -E '(^|_|-)'$DOCKER_CONTAINER_DB'($)')" ]; then
        get_db_name

        if [ "$DB_NAME" ]; then
            TIMESTAMP=$(date +"%Y-%m-%d-%H%M%S")

            #DUMP_FILE
            EMPTY_LINE
            file1=$DB_NAME.sql
            file2=dump-$DB_NAME-$TIMESTAMP.sql
            ECHO_GREEN "1 - $file1"
            ECHO_GREEN "2 - $file2 [default]"
            read -rp "$(ECHO_YELLOW "Please select one of:")" DUMP_FILE
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
