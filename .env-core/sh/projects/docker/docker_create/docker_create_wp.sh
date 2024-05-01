#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

docker_create_wp() {
    unset_variables

    if [ $NGINX_EXISTS -eq 1 ]; then
        setup_installation_type_callback docker_create_wp
        check_domain_exists

        if [[ $DOMAIN_EXISTS == 0 ]]; then
            check_data_before_continue_callback docker_create_wp

            ECHO_INFO "Setting up Docker containers for $DOMAIN_FULL"

            #GET PORT
            get_all_ports

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
            docker_restart

            wp_core_install
            wp_site_empty

            edit_file_compose_setup_beetroot
            edit_file_gitignore

            #clone root or theme
            git_clone_actions

            # Print for user project info
            notice_project_vars "open"

            # COMPOSER_ISSUE exists
            notice_composer

        else
            ECHO_ERROR "Site already exists"
            docker_create_wp
        fi
    else
        ECHO_ERROR "Nginx container not running"
        nginx_actions
    fi
}
