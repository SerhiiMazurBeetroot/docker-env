#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

setup_beetroot_args() {
    EMPTY_LINE
    while true; do
        ECHO_INFO "==== Use variables ===="
        ECHO_YELLOW "[0] Return to main menu"
        ECHO_KEY_VALUE "[1]" "default"
        ECHO_KEY_VALUE "[2]" "custom"
        read -rp "$(ECHO_YELLOW "Please select one of:")" choise

        case $choise in
        0)
            main_actions
            ;;
        1)
            get_domain_name
            get_project_dir "$@"
            set_project_args
            break
            ;;
        2)
            get_domain_name
            get_project_dir "$@"
            set_custom_args
            break
            ;;
        esac
    done
}

edit_file_wp_config_setup_beetroot() {

    if [[ -f "$PROJECT_ROOT_DIR/wp-config.php" ]]; then
        #Replace wp-config variables
        sed -i -e "s/getenv('WP_SITEURL')/getenv('WP_HOME')/g" "$PROJECT_ROOT_DIR/wp-config.php"

        CONFIG_EXISTS=$(awk '/composer_autoload/{print}' "$PROJECT_ROOT_DIR/wp-config.php")

        if [[ -z $CONFIG_EXISTS ]]; then
            #Include Composer to wp-config (Before first line)
            ex "$PROJECT_ROOT_DIR/wp-config.php" <<EOF
1 insert
<?php
\$composer_autoload = __DIR__ . '/vendor/autoload.php';
if ( file_exists( \$composer_autoload ) ) {
    require_once \$composer_autoload;
}
define('WP_DEBUG', getenv('WP_DEBUG'));
define('WP_DEBUG_DISPLAY', getenv('WP_DEBUG_DISPLAY'));
define('WP_DEBUG_LOG', getenv('WP_DEBUG_LOG'));
?>
.
xit
EOF
        else
            touch "$PROJECT_ROOT_DIR/.env"
        fi
    fi

}

edit_file_env_setup_beetroot() {
    PROJECT_THEME_DIR=$PROJECT_WP_CONTENT_DIR/themes/$WP_DEFAULT_THEME

    if [[ -f "$PROJECT_THEME_DIR/.env.example" ]]; then
        EMPTY_LINE
        ECHO_YELLOW "eidt .env file..."
        cp -rf "$PROJECT_THEME_DIR/.env.example" "$PROJECT_THEME_DIR/.env"

        sed -i -e 's~http://site.local~https://'"$DOMAIN_FULL"'~g' "$PROJECT_THEME_DIR/.env"
        sed -i -e 's/dbname/'"$DB_NAME"'/g' "$PROJECT_THEME_DIR/.env"
        sed -i -e 's/DB_USER=mysql/DB_USER=root/g' "$PROJECT_THEME_DIR/.env"
        sed -i -e 's/DB_PASSWORD=mysql/DB_PASSWORD=PassWorD123/g' "$PROJECT_THEME_DIR/.env"
        sed -i -e 's/localhost/'"$DOMAIN_NAME-mysql"'/g' "$PROJECT_THEME_DIR/.env"
    fi
}

edit_file_compose_setup_beetroot() {
    #Replace Volumes from 'wp-content' to 'wp-core' files SETUP_TYPE=beetroot
    if [[ "$SETUP_TYPE" == 3 ]]; then
        sed -i -e 's/wp-content\///g' $PROJECT_DOCKER_DIR/docker-compose.yml

        docker_rebuild
    fi
}
