#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

wp_composer_install() {
    if [ "$DOMAIN_NAME" == '' ]; then
        running_projects_list "======= Install Composer ======"
        get_db_name
        wp_get_default_theme
        edit_file_env_setup_beetroot
        edit_file_gitignore
    fi

    if [[ -f "$PROJECT_WP_CONTENT_DIR/themes/$WP_DEFAULT_THEME/composer.json" ]]; then
        EMPTY_LINE
        ECHO_YELLOW "Running composer install... $DOCKER_CONTAINER_APP"

        COMPOSER_ISSUE=$(docker exec -it "$DOCKER_CONTAINER_APP" bash -l -c "cd ./wp-content/themes/$WP_DEFAULT_THEME && composer install" | awk '{if(/allowed/) print }' || true)
        ECHO_YELLOW "COMPOSER_ISSUE: $COMPOSER_ISSUE"

        docker exec -i "$DOCKER_CONTAINER_APP" bash -l -c "cd ./wp-content/themes/$WP_DEFAULT_THEME && rm -rf ./vendor && composer install" || true
    else
        ECHO_YELLOW "composer.json file doesn't exists"
    fi
}

wp_composer_package() {
    EMPTY_LINE
    ECHO_KEY_VALUE "Package example: " '"wpackagist-plugin/safe-svg": "^2.0"'
    EMPTY_LINE
    read -rp "$(ECHO_YELLOW "Please fill in the package:")" package

    while [ -z "$package" ]; do
        read -rp "$(ECHO_YELLOW "Please fill in the package: ")" package
    done

    if [ "$DOMAIN_NAME" == '' ]; then
        running_projects_list "======= Install package ======"
        get_db_name
        wp_get_default_theme
    fi

    docker exec -it "$DOCKER_CONTAINER_APP" bash -l -c "cd ./wp-content/themes/$WP_DEFAULT_THEME && composer require $package" || true
}

wp_get_default_theme() {
    if [[ -d "$PROJECT_DATABASE_DIR" ]]; then
        # DB_FILE
        get_db_file

        if [[ -f "$PROJECT_DATABASE_DIR/$DB_FILE" ]]; then
            #1 => find in file | #2 => replace 'stylesheet' | #3 => replace character '' | #4 => replace , | #5 => replace space
            WP_DEFAULT_THEME=$(grep -o "'stylesheet',\s*'[A-Za-z0-9.,-]*\+'" "$PROJECT_DATABASE_DIR/$DB_FILE" | sed 's/'stylesheet'//g' | sed 's/'\''//g' | sed 's/,//g' | sed 's/^[ \t]*//;s/[ \t]*$//')
            EMPTY_LINE

            # Replace variable WP_DEFAULT_THEME .env file
            PREV_THEME="$(grep -o "WP_DEFAULT_THEME=[A-Za-z0-9.,-]*\+" "$PROJECT_DOCKER_DIR"/.env)"
            sed -i 's~'"$PREV_THEME"'~'"WP_DEFAULT_THEME=$WP_DEFAULT_THEME"'~g' "$PROJECT_DOCKER_DIR/.env"

        else
            ECHO_YELLOW "DB FILE doesn't exists"
        fi
    else
        ECHO_ERROR "DB DIR doesn't exists"
    fi
}

wp_npm_install() {
    if [ "$DOMAIN_NAME" == '' ]; then
        running_projects_list "======= Install npm ======"
        wp_get_default_theme
    fi

    if [[ -f "$PROJECT_WP_CONTENT_DIR/themes/$WP_DEFAULT_THEME/package.json" ]]; then
        EMPTY_LINE
        ECHO_YELLOW "Running npm install... $DOCKER_CONTAINER_APP"
        docker exec -i "$DOCKER_CONTAINER_APP" bash -l -c "cd ./wp-content/themes/$WP_DEFAULT_THEME && rm -rf ./node_modules && npm install" || true
    fi
}

wp_core_install() {
    EMPTY_LINE
    ECHO_YELLOW "wp_core_install..."
    if [[ "yes" = "$MULTISITE" || "2" = "$MULTISITE" ]]; then
        docker exec -i "$DOCKER_CONTAINER_APP" sh -c 'exec wp core multisite-install --url=https://'$DOMAIN_FULL' --title='$DOMAIN_NAME' --admin_user='$WP_USER' --admin_password="'$WP_PASSWORD'" --admin_email=example@example.com --skip-email --allow-root'

        wp_multisite_htaccess
    else
        docker exec -i "$DOCKER_CONTAINER_APP" sh -c 'exec wp core install --url=https://'$DOMAIN_FULL' --title='$DOMAIN_NAME' --admin_user='$WP_USER' --admin_password="'$WP_PASSWORD'" --admin_email=example@example.com --skip-email --allow-root'
    fi

    ECHO_SUCCESS "Done!"
}
