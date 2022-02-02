#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

get_domain_name () {
    if [ -z "$DOMAIN_NAME" ];
    then 
        EMPTY_LINE
        ECHO_YELLOW "Enter Domain Name without subdomain:"
        read -rp 'Domain: ' DOMAIN_NAME

        while [ -z "$DOMAIN_NAME" ]; do 
            read -rp "Please fill in the Domain: " DOMAIN_NAME
        done
    fi
}

get_project_dir () {
    QUESTION=$1

    #DOMAIN_FULL
    if [[ $QUESTION == "skip_question" ]];
    then
        DOMAIN_FULL=$(awk '/'" $DOMAIN_NAME "'/{print $7}' wp-instances.log | head -n 1);
    else
        EMPTY_LINE
        ECHO_YELLOW "Enter DOMAIN_FULL [default dev.$DOMAIN_NAME.local]"
        read -rp "DOMAIN_FULL: " DOMAIN_FULL
    fi

    [[ $DOMAIN_FULL == '' ]] && DOMAIN_FULL="dev.$DOMAIN_NAME.local"

    DOMAIN_NODOT=$(echo "$DOMAIN_NAME" | tr . _)
    PROJECT_ROOT_DIR=./projects/"$DOMAIN_FULL"
    PROJECT_DOCKER_DIR=$PROJECT_ROOT_DIR/wp-docker
    PROJECT_DATABASE_DIR=$PROJECT_ROOT_DIR/wp-database
    PROJECT_CONTENT_DIR=$PROJECT_ROOT_DIR/wp-content
}

get_db_name () {
    DB_NAME=$(awk '/'"$DOMAIN_NAME"'/{print $9}' wp-instances.log | head -n 1);

    if [ "$DB_NAME" ];
    then
        DOMAIN_NAME=$(awk '/'"$DOMAIN_NAME"'/{print $5}' wp-instances.log | head -n 1);
    else
        ECHO_ERROR "Wordpress site not exists"
    fi
}

get_unique_port() {
    # GET PORT [ count port from 3309 ]
    PORT=3309
    while true; do
        port_exist=$(awk '/'"$PORT"'/{print $1}' wp-instances.log | head -n 2 | tail -n 1);

        if [[ ! "$port_exist" ]]; then
            break
        fi
        ((PORT++))
    done
}

get_php_versions () {
    QUESTION=$1

    PHP_LIST=($(curl -s 'https://www.php.net/releases/active.php' | grep -Eo '[0-9]\.[0-9]' | awk '!a[$0]++'));

    if [ ! $PHP_VERSION ];
    then
        if [[ $QUESTION == "default" ]];
        then
            PHP_VERSION="${PHP_LIST[1]}"
        else
            for i in "${!PHP_LIST[@]}";
            do
                ECHO_KEY_VALUE "[$(($i+1))]" "${PHP_LIST[$i]}"
            done

            ((++i))
            read -rp "$(ECHO_YELLOW "Please select one of:")" choice

            [ -z "$choice" ] && choice=-1
            if (( "$choice" > 0 && "$choice" <= $i )); then
                PHP_VERSION="${PHP_LIST[$(($choice-1))]}"
            else
                PHP_VERSION="${PHP_LIST[1]}"
            fi
        fi
    fi
}
