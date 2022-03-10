#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

check_domain_exists () {
    DOMAIN_CHECK=$(awk '/'" $DOMAIN_NAME "'/{print $5}' "$FILE_INSTANCES" | head -n 1);

    if [[ "$DOMAIN_NAME" == "$DOMAIN_CHECK" ]];
    then
        DOMAIN_EXISTS=1
    else
        DOMAIN_EXISTS=0
    fi
}



check_package_availability () {
    command -v docker-compose >/dev/null 2>&1 || { ECHO_ERROR "Please install docker-compose"; exit 1; }
}

check_instances_file_exists () {
    if [ ! -f "$FILE_INSTANCES" ];
    then
        PORT=3309
        echo "$PORT | PROTOCOL | DOMAIN_NAME | DOMAIN_FULL | MYSQL_DATABASE |" >> "$FILE_INSTANCES"
    fi
}

detect_os () {
    UNAME=$( command -v uname)

    case $( "${UNAME}" | tr '[:upper:]' '[:lower:]') in
    linux*)
        OSTYPE='linux'
        ;;
    darwin*)
        OSTYPE='darwin'
        ;;
    msys*|cygwin*|mingw*)
        # or possible 'bash on windows'
        OSTYPE='windows'
        ;;
    nt|win*)
        OSTYPE='windows'
        ;;
    *)
        OSTYPE='unknown'
        ;;
    esac
    export $OSTYPE
}

git_config_fileMode() {
    if [ "$(git rev-parse --is-inside-work-tree 2>/dev/null)" == "true" ];
    then
        git config core.fileMode false
        cd "${PWD}/projects/$DOMAIN_FULL" && git config core.fileMode false
        cd ../../
    fi
}

unset_variables () {
    unset DOMAIN_NAME DB_NAME TABLE_PREFIX PHP_VERSION
}


# Get the last *.sql file
get_db_file () {
    SQL_FILES=("$PROJECT_DATABASE_DIR"/*.sql)

    for file in "${SQL_FILES[@]}"
    do
        DB_FILE="$(basename "$file")"
    done
}
