#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

fix_linux_watchers() {
    if [[ $OSTYPE == "linux" ]]; then
        limit=$(cat /proc/sys/fs/inotify/max_user_watches)
        if [[ "$limit" -lt 524288 ]]; then
            EMPTY_LINE
            ECHO_YELLOW "Change system limit for number of file watchers"
            echo fs.inotify.max_user_watches=524288 | sudo tee -a /etc/sysctl.conf && sudo sysctl -p
        fi
    fi
}

check_instances_file_exists() {
    if [ ! -f "$FILE_INSTANCES" ]; then
        mkdir $DIR_DATA

        PORT=3309
        echo "$PORT | STATUS | DOMAIN_NAME | DOMAIN_FULL | DB_NAME | DB_TYPE | PROJECT_TYPE | " >>"$FILE_INSTANCES"
    fi
}

print_to_file_instances() {
    if [[ $PORT && $DOMAIN_NAME ]]; then
        echo "$PORT | active | $DOMAIN_NAME | $DOMAIN_FULL | $DB_NAME | $DB_TYPE | $PROJECT_TYPE |" >>"$FILE_INSTANCES"
    fi
}
