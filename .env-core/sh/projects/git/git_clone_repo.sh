#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

git_clone_repo() {
    get_existing_domains

    check_domain_exists

    if [[ $DOMAIN_EXISTS == 1 ]]; then
        get_project_dir "skip_question"
        EMPTY_LINE
        fix_permissions

        EMPTY_LINE
        ECHO_YELLOW "Getting plugins and themes from the repository"
        read -rp "Clone from repo (url): " URL_CLONE
        while [ -z "$URL_CLONE" ]; do
            read -rp "Please complete the cloning path: " URL_CLONE
        done

        if [[ "${URL_CLONE}" == *"git@"* ]]; then
            # replace : => /
            URL_CORRECT=${URL_CLONE//:/\/}
            # replace git@ => https://
            URL_CORRECT=${URL_CORRECT/git@/https://}
        else
            URL_CORRECT=$URL_CLONE
        fi

        # Checking URL
        if curl --output /dev/null --silent --head --fail -k $URL_CORRECT; then
            ECHO_SUCCESS "URL EXISTS"
            URL_EXISTS=1
        else
            ECHO_WARN_YELLOW "URL NOT EXISTS"
            URL_EXISTS=0
        fi

        if [[ $URL_EXISTS == 1 ]]; then
            ECHO_YELLOW "Cloning repository to temp..."
            rm -rf $PROJECT_ROOT_DIR/repository

            git config --global http.sslVerify false

            git clone "$URL_CLONE" $PROJECT_ROOT_DIR/repository/

            if [ ! -d $PROJECT_DATABASE_DIR/ ]; then
                ECHO_INFO "Creating DIR wp-database..."
                mkdir $PROJECT_DATABASE_DIR/
            fi

            ECHO_INFO "Please wait, copying themes and plugins..."

            if [[ -d $PROJECT_ROOT_DIR/repository/wp-content || -d $PROJECT_ROOT_DIR/repository/wp-admin || -d $PROJECT_ROOT_DIR/repository/wp-includes ]]; then
                cp -rf $PROJECT_ROOT_DIR/repository/. $PROJECT_ROOT_DIR/
            fi

            if [ -d $PROJECT_ROOT_DIR/repository/themes ]; then
                cp -rf $PROJECT_ROOT_DIR/repository/themes/. $PROJECT_ROOT_DIR/wp-content/themes/
            fi

            if [ -d $PROJECT_ROOT_DIR/repository/plugins ]; then
                cp -rf $PROJECT_ROOT_DIR/repository/plugins/. $PROJECT_ROOT_DIR/wp-content/plugins/
            fi

            if [ -d $PROJECT_ROOT_DIR/repository/uploads ]; then
                cp -rf $PROJECT_ROOT_DIR/repository/uploads/. $PROJECT_ROOT_DIR/wp-content/uploads/
            fi

            #Bedrock
            if [[ -d $PROJECT_ROOT_DIR/repository/config && -d $PROJECT_ROOT_DIR/repository/web ]]; then
                cp -rf $PROJECT_ROOT_DIR/repository/. $PROJECT_ROOT_DIR/app/
            fi

            rm -rf $PROJECT_ROOT_DIR/repository
            ECHO_YELLOW "Themes and plugins copied"

            while true; do
                EMPTY_LINE
                read -rp "$(ECHO_YELLOW "Start importing DB?") y/n " yn

                case $yn in
                [Yy]*)
                    database_replace_project_from_db
                    docker_rebuild
                    docker_restart
                    database_import
                    fix_permissions
                    edit_file_wp_config_setup_beetroot
                    wp_get_default_theme
                    wp_composer_install
                    edit_file_env_setup_beetroot
                    fix_linux_watchers
                    EMPTY_LINE
                    break
                    ;;
                [Nn]*)
                    break
                    ;;

                *) echo "Please answer yes or no" ;;
                esac
            done
        else
            ECHO_ERROR "Path is not correct"
            exit
        fi
    else
        ECHO_ERROR "Docker container doesn't exist [$PROJECT_ROOT_DIR]"
    fi
}
