#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

docker_create_php() {
    unset_variables

    if [ $NGINX_EXISTS -eq 1 ]; then
        get_domain_name
        check_domain_exists

        if [[ $DOMAIN_EXISTS == 0 ]]; then
            get_project_dir "$@"
            setup_default_args
        else
            ECHO_ERROR "Site already exists"

            # Run next function again
            get_domain_name
        fi

        if [[ $DOMAIN_EXISTS == 0 ]]; then
            check_data_before_continue_callback docker_create_custom

            ECHO_INFO "Setting up Docker containers for $DOMAIN_FULL"

            #GET PORT
            get_unique_port

            get_project_dir "skip_question"

            print_to_file_instances

            # Create DIR
            mkdir -p $PROJECT_DOCKER_DIR

            # Copy templates files
            cp -r ./.env-core/templates/php/* $PROJECT_DOCKER_DIR
            mv $PROJECT_DOCKER_DIR/app $PROJECT_ROOT_DIR

            # Rename files
            replace_templates_files

            # Replace Variables
            replace_variables

            # Load env
            env_file_load

            ECHO_GREEN "Docker compose file set and container can be built and started"
            ECHO_TEXT "Starting Container"
            docker-compose -f $PROJECT_DOCKER_DIR/docker-compose.yml up -d --build

            ECHO_SUCCESS "Containers Started"

            setup_hosts_file add
            fix_permissions
            notice_windows_host add
            docker_restart

            # TODO: add clone

            # Print for user project info
            EMPTY_LINE
            ECHO_INFO "Project variables:"
            notice_project_vars

        fi

    else
        ECHO_ERROR "Nginx container not running"
        nginx_actions
    fi
}
