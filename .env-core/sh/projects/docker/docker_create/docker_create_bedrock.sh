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
            get_all_ports

            get_project_dir "skip_question"

            print_to_file_instances

            # Create DIR
            mkdir -p $PROJECT_ROOT_DIR

            # Clone templates files
            git_clone_templates_files

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

            wait_for_db
            wp_core_install
            wp_site_empty

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
