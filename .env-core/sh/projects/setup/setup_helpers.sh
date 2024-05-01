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

get_domain_default_name() {
    case $PROJECT_TYPE in
    "elasticsearch")
        DOMAIN_NAME_DEFAULT="dev.$DOMAIN_NAME.elastic"
        ;;
    *)
        DOMAIN_NAME_DEFAULT="dev.$DOMAIN_NAME.local"
        ;;
    esac
}

check_domain_exists() {
    DOMAIN_CHECK=$(awk '/'" $DOMAIN_NAME "'/{print $5}' "$FILE_INSTANCES" | head -n 1)

    if [[ "$DOMAIN_NAME" == "$DOMAIN_CHECK" ]]; then
        DOMAIN_EXISTS=1
    else
        DOMAIN_EXISTS=0
    fi
}

unset_variables() {
    if [[ $TEST_RUNNING -ne 1 ]]; then
        unset DOMAIN_NAME DB_NAME TABLE_PREFIX PHP_VERSION MULTISITE EMPTY_CONTENT NODE_VERSIONS SETUP_ACTION DOMAIN_MAIL $1
    fi
}

get_project_type() {
    if [[ -z "$PROJECT_TYPE" ]]; then
        PROJECT_TYPE=$(awk '/'" $DOMAIN_NAME "'/{print $13}' "$FILE_INSTANCES" | head -n 1)
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

git_clone_templates_files() {
    local action=$1

    if [[ $action == "copy" ]]; then
        # for development
        if [ -d "$ENV_DIR/../docker-env-templates/docker-env-template-$PROJECT_TYPE/" ]; then
            cp -r $ENV_DIR/../docker-env-templates/docker-env-template-$PROJECT_TYPE/* $PROJECT_ROOT_DIR
        else
            ECHO_ERROR "Please check you templates"
        fi
    else
        git clone $TEMPLATES_REPO-$PROJECT_TYPE.git $PROJECT_ROOT_DIR --depth 1
    fi
}
