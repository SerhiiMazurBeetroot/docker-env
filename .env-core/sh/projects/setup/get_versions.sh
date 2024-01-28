#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

get_php_versions() {
    QUESTION=$1

    PHP_LIST=($(curl -s 'https://www.php.net/releases/active.php' | grep -Eo '[0-9]\.[0-9]' | awk '!a[$0]++'))
    PHP_VERSION="${PHP_LIST[1]}"

    if [ ! $PHP_VERSION ]; then
        if [[ $QUESTION == "default" ]]; then
            PHP_VERSION="${PHP_LIST[1]}"
        else
            ECHO_ENTER "Enter PHP_VERSION [default '$PHP_VERSION']"

            print_list "${PHP_LIST[@]}"

            choice=$(GET_USER_INPUT "select_one_of")
            choice=${choice%.*}

            if [ -z "$choice" ]; then
                choice=-1
                PHP_VERSION="${PHP_LIST[1]}"
            else
                if (("$choice" > 0 && "$choice" <= ${#PHP_LIST[@]})); then
                    PHP_VERSION="${PHP_LIST[$(($choice - 1))]}"
                else
                    PHP_VERSION="${PHP_LIST[1]}"
                    ECHO_WARN_RED "This version of PHP does not support"
                    ECHO_GREEN "Set default version: $PHP_VERSION"
                    EMPTY_LINE
                fi
            fi
        fi
    fi
}

get_latest_wp_version() {
    WP=$(curl -s 'https://api.github.com/repos/wordpress/wordpress/tags' | grep "name" | head -n 2 | awk '$0=$2' | grep -E '[0-9]+\.[0-9]+?' | tr -d \",)
    WP=($WP)
    WP_LATEST_VER=$(echo ${WP[0]} | grep -Eo '[0-9]+\.[0-9]+\.?[0-9]+' || echo "${WP[0]}.0")
    WP_PREV_VER=$(echo ${WP[1]} | grep -Eo '[0-9]+\.[0-9]+\.?[0-9]+' || echo "${WP[1]}.0")
}

get_nodejs_version() {
    NODE_VERSIONS=($(curl -sL 'https://raw.githubusercontent.com/nodejs/docker-node/main/versions.json' | grep -o '"[0-9]\+": {' | cut -d'"' -f2 | sed 's/: {//'))
    NODE_LATEST_VERSION="${NODE_VERSIONS}"

    if [ ! $NODE_VERSION ]; then
        if [[ $QUESTION == "default" ]]; then
            NODE_VERSION="${NODE_VERSIONS[1]}"
        else
            ECHO_ENTER "Enter NODE_VERSION [default '$NODE_LATEST_VERSION']"

            print_list "${NODE_VERSIONS[@]}"

            choice=$(GET_USER_INPUT "select_one_of")
            choice=${choice%.*}

            if [ -z "$choice" ]; then
                choice=-1
                NODE_VERSION="$NODE_LATEST_VERSION"
            else
                if (("$choice" > 0 && "$choice" <= ${#NODE_VERSIONS[@]})); then
                    NODE_VERSION="${NODE_VERSIONS[$(($choice - 1))]}"
                else
                    EMPTY_LINE
                    NODE_VERSION="${NODE_LATEST_VERSION}"
                    ECHO_GREEN "Set default version: $NODE_VERSION"
                    EMPTY_LINE
                fi
            fi
        fi
    fi
}
