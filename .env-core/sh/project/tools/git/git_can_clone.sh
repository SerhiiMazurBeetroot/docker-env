#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

git_can_clone() {
    msg=$1

    EMPTY_LINE
    fix_permissions

    EMPTY_LINE
    ECHO_YELLOW "$msg"
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
        export CAN_CLONE=1
    else
        ECHO_WARN_YELLOW "URL NOT EXISTS"
        ECHO_ERROR "Path is not correct"
        export CAN_CLONE=0
        exit
    fi
}
