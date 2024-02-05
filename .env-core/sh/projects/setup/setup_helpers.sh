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
        unset DOMAIN_NAME DB_NAME TABLE_PREFIX PHP_VERSION MULTISITE EMPTY_CONTENT NODE_VERSIONS $1
    fi
}

update_file_instances() {
    if [[ $INSTANCES_STATUS == "remove" ]]; then
        #Remove
        sed -i -e '/'"| $DOMAIN_NAME |"'/d' "$FILE_INSTANCES"
        sed -i'.bak' -e '/'"| $DOMAIN_NAME |"'/d' "$FILE_INSTANCES"
    elif [[ $INSTANCES_STATUS == 'archive' ]]; then
        #Change status to "archive"
        PREV_INSTANCES=$(awk '/'" $DOMAIN_NAME "'/{print}' "$FILE_INSTANCES" | head -n 1)
        NEW_INSTANCES=$(echo $PREV_INSTANCES | sed -r 's/active/archive/')

        sed -i -e 's/'"$PREV_INSTANCES"'/'"$NEW_INSTANCES"'/g' "$FILE_INSTANCES"
        sed -i'.bak' -e 's/'"$PREV_INSTANCES"'/'"$NEW_INSTANCES"'/g' "$FILE_INSTANCES"
    elif [[ $INSTANCES_STATUS == 'active' ]]; then
        #Change status to "active"
        PREV_INSTANCES=$(awk '/'" $DOMAIN_NAME "'/{print}' "$FILE_INSTANCES" | head -n 1)
        NEW_INSTANCES=$(echo $PREV_INSTANCES | sed -r 's/archive/active/')

        sed -i -e 's/'"$PREV_INSTANCES"'/'"$NEW_INSTANCES"'/g' "$FILE_INSTANCES"
        sed -i'.bak' -e 's/'"$PREV_INSTANCES"'/'"$NEW_INSTANCES"'/g' "$FILE_INSTANCES"
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

# Load/Create enviroment variables
env_file_load() {
    local CREATE_FILE=$1
    get_project_dir "skip_question"

    if [[ $CREATE_FILE == '' && -f $PROJECT_DOCKER_DIR/.env ]]; then
        source $PROJECT_DOCKER_DIR/.env
    else
        ECHO_YELLOW ".env file not found, creating..."

        if [ -f $PROJECT_DOCKER_DIR/.env.example ]; then
            cp -rf $ENV_DIR/.env-core/templates/"$PROJECT_DIR"/.env.example $PROJECT_DOCKER_DIR/.env
        fi

        sed -i -e 's/{DOMAIN_NAME}/'$DOMAIN_NAME'/g' $PROJECT_DOCKER_DIR/.env
        sed -i -e 's/{TABLE_PREFIX}/'$TABLE_PREFIX'/g' $PROJECT_DOCKER_DIR/.env
        sed -i -e 's/{DOMAIN_FULL}/'$DOMAIN_FULL'/g' $PROJECT_DOCKER_DIR/.env
        sed -i -e 's/{WP_VERSION}/'$WP_VERSION'/g' $PROJECT_DOCKER_DIR/.env
        sed -i -e 's/{PORT}/'$PORT'/g' $PROJECT_DOCKER_DIR/.env
        sed -i -e 's/{WP_VERSION}/'$WP_VERSION'/g' $PROJECT_DOCKER_DIR/.env
        sed -i -e 's/{WP_USER}/'$WP_USER'/g' $PROJECT_DOCKER_DIR/.env
        sed -i -e 's/{WP_PASSWORD}/'$WP_PASSWORD'/g' $PROJECT_DOCKER_DIR/.env
        sed -i -e 's/{PHP_VERSION}/'$PHP_VERSION'/g' $PROJECT_DOCKER_DIR/.env
        sed -i -e 's/{COMPOSE_PROJECT_NAME}/'$COMPOSE_PROJECT_NAME'/g' $PROJECT_DOCKER_DIR/.env

        # Headless CMS
        sed -i -e 's/{PORT_FRONT}/'$PORT_FRONT'/g' $PROJECT_DOCKER_DIR/.env

        # Node.js
        sed -i -e 's/{MONGODB_LOCAL_PORT}/'$MONGODB_LOCAL_PORT'/g' $PROJECT_DOCKER_DIR/.env
        sed -i -e 's/{MONGO_EXPRESS_PORT}/'$MONGO_EXPRESS_PORT'/g' $PROJECT_DOCKER_DIR/.env
        sed -i -e 's/{NODE_VERSION}/'$NODE_VERSION'/g' $PROJECT_DOCKER_DIR/.env

        # Directus
        sed -i -e 's/{DIRECTUS_VERSION}/'$DIRECTUS_VERSION'/g' $PROJECT_DOCKER_DIR/.env

        [[ "yes" = "$MULTISITE" ]] && wp_multisite_env

        #Replace only first occurrence in the file
        sed -i -e '0,/{MYSQL_DATABASE}/s//'$DB_NAME'/' $PROJECT_DOCKER_DIR/.env

        # delete .env.example
        cd "$PROJECT_ROOT_DIR" && rm -rf .env.example && cd ../../
    fi
}

replace_templates_files() {
    EXAMPLE_FILES=($(find "$PROJECT_DOCKER_DIR" -type f -name '*.example'))

    if [[ $EXAMPLE_FILES ]]; then
        for EXAMPLE_FILE in "${EXAMPLE_FILES[@]}"; do
            echo $EXAMPLE_FILE | while read FILENAME; do
                NEW_FILENAME="$(echo ${FILENAME} | sed -e 's/.example//')"
                ECHO_KEY_VALUE "$FILENAME   =>   " "$NEW_FILENAME"

                mv "${FILENAME}" "${NEW_FILENAME}"
            done
        done
    fi
}

edit_file_gitignore() {
    if [[ -f "$PROJECT_ROOT_DIR/.gitignore" ]]; then
        GITIGNORE_EDITED=$(awk '/wp-docker/{print $1}' "$PROJECT_ROOT_DIR/.gitignore" | head -n 1)

        if [ "$GITIGNORE_EDITED" == '' ]; then
            EMPTY_LINE
            ECHO_YELLOW "eidt .gitignore file..."
            ex "$PROJECT_ROOT_DIR/.gitignore" <<EOF
1 insert
/wp-docker/
/logs/
/vendor/
adminer.php
wp-config-docker.php
.
xit
EOF
        fi
    else
        EMPTY_LINE
        ECHO_YELLOW "create .gitignore file..."
        cat <<-EOF >$PROJECT_ROOT_DIR/.gitignore
/wp-docker/
/logs/
/vendor/
adminer.php
wp-config-docker.php
EOF
    fi
}

randpassword() {
    WP_PASSWORD=$(LC_CTYPE=C tr -dc A-Za-z0-9_\!\@\#\$\%\^\&\*\(\)-+= </dev/urandom | head -c 20) || true
}
