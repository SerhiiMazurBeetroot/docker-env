#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

fix_permissions() {
    check_domain_exists

    if [[ $DOMAIN_EXISTS == 1 ]]; then
        case $PROJECT_TYPE in
        "wordpress" | "bedrock" | "wpnextjs")
            fix_permissions_wp
            ;;
        *)
            fix_permissions_project_root
            ;;
        esac
    else
        ECHO_ERROR "Site not exists"
    fi
}

fix_permissions_wp() {
    EMPTY_LINE
    ECHO_YELLOW "Fixing Permissions, this can take a while! [$PROJECT_ROOT_DIR]"

    if [ "$(docker ps --format '{{.Names}}' | grep -E '(^|_|-)'$DOCKER_CONTAINER_APP'($)')" ]; then
        docker exec -i "$DOCKER_CONTAINER_APP" sh -c 'exec chown -R www-data:www-data /var/www/html/'
        docker exec -i "$DOCKER_CONTAINER_APP" sh -c 'exec chmod -R 777 /var/www/html/'
    else
        ECHO_ERROR "Docker container doesn't exist [$PROJECT_ROOT_DIR]"
    fi

    #Fix WP_CONTENT permissions
    if [[ $OSTYPE != "windows" ]]; then
        if [ -d $PROJECT_ROOT_DIR ]; then
            EMPTY_LINE
            sudo chmod -R 777 "$PROJECT_ROOT_DIR"
        fi

        if [ -d $PROJECT_WP_CONTENT_DIR ]; then
            sudo chmod -R 777 "$PROJECT_WP_CONTENT_DIR"
            [[ -d "$PROJECT_WP_CONTENT_DIR"/themes ]] && sudo chmod -R 777 "$PROJECT_WP_CONTENT_DIR"/themes
            [[ -d "$PROJECT_WP_CONTENT_DIR"/plugins ]] && sudo chmod -R 777 "$PROJECT_WP_CONTENT_DIR"/plugins
            [[ -d "$PROJECT_WP_CONTENT_DIR"/uploads ]] && sudo chmod -R 777 "$PROJECT_WP_CONTENT_DIR"/uploads
        fi

        git_config_fileMode
    fi
}

fix_permissions_project_root() {
    if [[ $OSTYPE != "windows" ]]; then
        if [ -d $PROJECT_ROOT_DIR ]; then
            EMPTY_LINE
            ECHO_YELLOW "Fixing Permissions, this can take a while! [$PROJECT_ROOT_DIR]"
            sudo chmod -R 777 "$PROJECT_ROOT_DIR"/
        fi
    fi
}
