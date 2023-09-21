#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

database_create_dump() {
    env_file_load
    get_mysql_cmd

    mkdir -p $PROJECT_DATABASE_DIR/temp

    # Save old files to "/temp" before deleting
    for files in $PROJECT_DATABASE_DIR/*.sql; do
        if [ -e "$files" ]; then
            ECHO_TEXT "There are old files to delete"
            mv $PROJECT_DATABASE_DIR/*.sql $PROJECT_DATABASE_DIR/temp
            break
        fi
    done

    file=$PROJECT_DATABASE_DIR/$DUMP_FILE

    # Create dump
    docker exec -i "$DOCKER_CONTAINER_DB" sh -c "$MYSQL_DUMP_CMD -uroot -p$MYSQL_ROOT_PASSWORD $MYSQL_DATABASE" >"$file"

    # Check if new backup was created
    if [ -e "$file" ]; then
        rm -rf $PROJECT_DATABASE_DIR/temp
        ECHO_SUCCESS "Backup done $(date +%Y'-'%m'-'%d' '%H':'%M)"
    else
        ECHO_ERROR "DB dump not created"
        mv $PROJECT_DATABASE_DIR/temp/*.sql $PROJECT_DATABASE_DIR/
        rm -rf $PROJECT_DATABASE_DIR/temp
    fi
    EMPTY_LINE
}
