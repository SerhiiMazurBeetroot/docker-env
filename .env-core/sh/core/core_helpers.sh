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
        echo "$PORT | STATUS | DOMAIN_NAME | DOMAIN_FULL | DB_NAME | DB_TYPE | PROJECT_TYPE | PORT_FRONT | " >>"$FILE_INSTANCES"
    fi
}

print_to_file_instances() {
    if [[ $PORT && $DOMAIN_NAME ]]; then

        [[ $PORT_FRONT == "" ]] && PORT_FRONT='-'

        echo "$PORT | active | $DOMAIN_NAME | $DOMAIN_FULL | $DB_NAME | $DB_TYPE | $PROJECT_TYPE | $PORT_FRONT |" >>"$FILE_INSTANCES"
        # Save backup
        echo "$PORT | active | $DOMAIN_NAME | $DOMAIN_FULL | $DB_NAME | $DB_TYPE | $PROJECT_TYPE | $PORT_FRONT |" >>"$FILE_INSTANCES.bak"
    fi
}

# usage array:
# Call: print_list "${ARRAY[@]}"

print_list() {
    OPTION_LIST=("$@")

    for ((i = 0; i < ${#OPTION_LIST[@]}; i++)); do
        index=$((i + 1))
        option="${OPTION_LIST[i]}"
        ECHO_KEY_VALUE "[$index]" "$option"
    done
}
