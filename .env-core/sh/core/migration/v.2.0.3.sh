#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

env_update_repo() {
    if repo_exists "$MAIN_REPO"; then
        # Repository does not exist.
        MAIN_REPO=$OLD_REPO
    else
        # Repository exists.
        MAIN_REPO=$MAIN_REPO
    fi

    ECHO_KEY_VALUE "MAIN_REPO:" "$MAIN_REPO"
}
