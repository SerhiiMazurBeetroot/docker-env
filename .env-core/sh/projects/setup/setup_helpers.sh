#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

get_domain_name() {
    if [ -z "$DOMAIN_NAME" ]; then
        ECHO_ENTER "Enter Domain Name without subdomain:"
        read -rp 'Domain: ' DOMAIN_NAME

        while [ -z "$DOMAIN_NAME" ]; do
            read -rp "Please fill in the Domain: " DOMAIN_NAME
        done

        # Remove non printing chars from DOMAIN_NAME
        DOMAIN_NAME=$(echo $DOMAIN_NAME | tr -dc '[[:print:]]' | tr -d ' ' | tr -d '[A' | tr -d '[C' | tr -d '[B' | tr -d '[D')

        # Replace "_" to "-"
        DOMAIN_NAME=$(echo $DOMAIN_NAME | sed 's/_/-/g')

        # Remove subdomain
        DOMAIN_NAME=$(echo ${DOMAIN_NAME} | cut -d . -f 1)
    fi
}

check_domain_exists() {
    DOMAIN_CHECK=$(awk '/'" $DOMAIN_NAME "'/{print $5}' "$FILE_INSTANCES" | head -n 1)

    if [[ "$DOMAIN_NAME" == "$DOMAIN_CHECK" ]]; then
        DOMAIN_EXISTS=1
    else
        DOMAIN_EXISTS=0
    fi
}

get_unique_port() {
    # GET PORT [ count port from 3309 ]
    PORT=3309
    while true; do
        port_exist=$(awk '/'"$PORT"'/{print $1}' "$FILE_INSTANCES" | head -n 2 | tail -n 1)

        if [[ ! "$port_exist" ]]; then
            break
        fi
        ((PORT++))
    done
}

set_unique_frontport() {
    # SET PORT_FRONT [ count port from 5510 ]

    if [[ $PORT ]]; then
        PORT_FRONT=$(($PORT + 1700))
    else
        get_unique_frontport
    fi
}

get_unique_frontport() {
    if [ -z "$DOMAIN_NAME" ]; then
        PORT_FRONT=$(awk '/'" $DOMAIN_NAME "'/{print $15}' "$FILE_INSTANCES" | head -n 1)
    fi
}

unset_variables() {
    if [[ $TEST_RUNNING -ne 1 ]]; then
        unset DOMAIN_NAME DB_NAME TABLE_PREFIX PHP_VERSION MULTISITE EMPTY_CONTENT NODE_VERSIONS SETUP_ACTION $1
    fi
}

get_project_type() {
    if [[ "$PROJECT_TYPE" == '' ]]; then
        PROJECT_TYPE=$(awk '/'"$DOMAIN_NAME"'/{print $13}' "$FILE_INSTANCES" | head -n 1)
    fi
}

get_compose_project_name() {
    if [ -n "$DOMAIN_FULL" ]; then
        COMPOSE_PROJECT_NAME=$(echo "$DOMAIN_FULL" | sed "s/[^a-zA-Z0-9_\-]/_/g; s/^-//; s/-$/_/; s/-/_/g; s/[^a-zA-Z0-9_\-]//g; s/^$/none/")
    fi
}

delete_site_data() {
    if [ -d "$PROJECT_ROOT_DIR" ]; then
        EMPTY_LINE
        ECHO_YELLOW "Deleting Site files and webroot"
        rm -rf "$PROJECT_ROOT_DIR"
    else
        echo "Webroot not found"
    fi

    #Remove from instances.log
    update_file_instances

    #Remove from /etc/hosts
    setup_hosts_file rem
}

randpassword() {
    WP_PASSWORD=$(LC_CTYPE=C tr -dc A-Za-z0-9_\!\@\#\$\%\^\&\*\(\)-+= </dev/urandom | head -c 20) || true
}
