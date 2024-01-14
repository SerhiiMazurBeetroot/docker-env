#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

healthcheck() {
    check_package_availability
    detect_os
    check_instances_file_exists
    check_env_settings
    docker_nginx_container
    notice_compose_v2
    env_mode
    clear_nginx_logs
}
