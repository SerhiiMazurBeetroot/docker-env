#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

database_search_replace() {
    while true; do

        yn=$(GET_USER_INPUT "question" "Run search-replace?")

        case $yn in
        [Yy]*)
            check_domain_exists

            if [[ $DOMAIN_EXISTS == 1 ]]; then
                read -rp "search: " search
                read -rp "replace: " replace

                ECHO_YELLOW "Running search-replace now from $search to $replace, this might take a while!"
                docker exec -i "$DOCKER_CONTAINER_APP" sh -c 'exec wp search-replace --all-tables '$search' '$replace' --allow-root'
                ECHO_SUCCESS "Search-replace done"
            fi
            break
            ;;
        [Nn]*)
            break
            ;;

        *) echo "Please answer [y/n]" ;;
        esac
    done
}
