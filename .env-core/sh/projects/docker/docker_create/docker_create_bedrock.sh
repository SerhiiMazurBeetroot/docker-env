#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

docker_create_bedrock() {
    unset_variables

    if [ $NGINX_EXISTS -eq 1 ]; then
        setup_installation_type_callback docker_create_bedrock
        check_domain_exists

        if [[ $DOMAIN_EXISTS == 0 ]]; then
            check_data_before_continue_callback docker_create_bedrock

            ECHO_INFO "Setting up Docker containers for $DOMAIN_FULL"

            #GET PORT
            get_unique_port

            get_project_dir "skip_question"

            print_to_file_instances

            # Create DIR
            mkdir -p $PROJECT_ROOT_DIR

            # Clone templates files
            git clone $TEMPLATES_REPO-$PROJECT_TYPE.git $PROJECT_ROOT_DIR --depth 1

            # Rename files
            replace_templates_files

            # Replace Variables
            replace_variables

            # Load env
            env_file_load "create"

            ECHO_GREEN "Docker compose file set and container can be built and started"
            ECHO_TEXT "Starting Container"
            docker_compose_runner "up -d --build"

            ECHO_SUCCESS "Containers Started"

            setup_hosts_file add
            fix_permissions
            notice_windows_host add
            docker_restart

            # TODO: add clone

            # Print for user project info
            notice_project_vars "open"

        fi

    else
        ECHO_ERROR "Nginx container not running"
        nginx_actions
    fi
}
