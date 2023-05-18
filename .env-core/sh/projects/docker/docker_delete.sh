#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

docker_delete() {
    get_existing_domains "======== DELETE project ======="

    get_project_dir "skip_question"

    if [ -d $PROJECT_ROOT_DIR ]; then
        EMPTY_LINE
        ECHO_ATTENTION "You can't restore the site after it has been deleted."
        ECHO_ATTENTION "This operation will remove the localhost containers, volumes, and the WordPress core files."

        while true; do
            ECHO_WARN_YELLOW "Removing now... [$PROJECT_ROOT_DIR]"
            read -rp "$(ECHO_WARN_RED "Do you wish to proceed?") [y/n] " yn

            case $yn in
            [Yy]*)
                EMPTY_LINE
                ECHO_YELLOW "Deleting site..."
                fix_permissions
                docker_stop

                if [[ $(docker image ls --format '{{.Repository}}' | grep -E '(^|_|-)'$DOCKER_CONTAINER_APP'($)') ]]; then
                    EMPTY_LINE
                    imageid=$(docker image ls --format '{{.Repository}}' | grep -E '(^|_|-)'$DOCKER_CONTAINER_APP'($)')
                    [ -n "$imageid" ] && docker rmi "$imageid" --force && ECHO_YELLOW "Deleting images" || ECHO_WARN_YELLOW "Image not found"
                else
                    ECHO_ERROR "Docker image does not exist"
                fi

                if [ $(docker volume ls --format '{{.Name}}' | grep -E '(^|_|-)'$DOCKER_VOLUME_DB'($)') ]; then
                    EMPTY_LINE
                    volumename=$(docker volume ls --format '{{.Name}}' | grep -E '(^|_|-)'$DOCKER_VOLUME_DB'($)')
                    [ -n "$volumename" ] && docker volume rm "$volumename" && ECHO_YELLOW "Deleting Volume" || echo "Volume not found"
                else
                    ECHO_ERROR "Docker volume does not exist"
                fi

                delete_site_data
                notice_windows_host rem

                break
                ;;
            [Nn]*)
                unset_variables
                actions_existing_project
                ;;

            *) echo "Please answer yes or no" ;;
            esac
        done
    else
        ECHO_ERROR "Site DIR does not exist: $PROJECT_ROOT_DIR"
        delete_site_data
    fi
}
