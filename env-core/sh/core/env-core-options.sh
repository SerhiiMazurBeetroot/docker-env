#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail


delete_site_data () {
    
    if [ -d "$PROJECT_ROOT_DIR" ];
    then
        EMPTY_LINE
        ECHO_YELLOW "Deleting Site files and webroot"
        rm -rf "$PROJECT_ROOT_DIR"
    else
        echo "Webroot not found"
    fi

    #Remove from wp-instances.log
    sed -i -e '/'"| $DOMAIN_NAME |"'/d' ./wp-instances.log

    #Remove from /etc/hosts
    setup_hosts_file rem
}

# Load/Create enviroment variables
env_file_load () {
    # get_domain_name

    get_project_dir "skip_question"

    if [ -f $PROJECT_DOCKER_DIR/.env ]; 
    then
        source $PROJECT_DOCKER_DIR/.env
    else
        ECHO_YELLOW ".env file not found, creating..."
        cp -rf ./env-core/templates/wordpress/.env.dev.example $PROJECT_DOCKER_DIR/.env

        sed -i -e 's/{DOMAIN_NAME}/'$DOMAIN_NAME'/g' $PROJECT_DOCKER_DIR/.env
        sed -i -e 's/{TABLE_PREFIX}/'$TABLE_PREFIX'/g' $PROJECT_DOCKER_DIR/.env
        sed -i -e 's/{DOMAIN_FULL}/'$DOMAIN_FULL'/g' $PROJECT_DOCKER_DIR/.env
        sed -i -e 's/{WP_VERSION}/'$WP_VERSION'/g' $PROJECT_DOCKER_DIR/.env
        sed -i -e 's/{PORT}/'$PORT'/g' $PROJECT_DOCKER_DIR/.env
        sed -i -e 's/{WP_VERSION}/'$WP_VERSION'/g' $PROJECT_DOCKER_DIR/.env
        sed -i -e 's/{WP_USER}/'$WP_USER'/g' $PROJECT_DOCKER_DIR/.env
        sed -i -e 's/{WP_PASSWORD}/'$WP_PASSWORD'/g' $PROJECT_DOCKER_DIR/.env
        sed -i -e 's/{PHP_VERSION}/'$PHP_VERSION'/g' $PROJECT_DOCKER_DIR/.env

        #Replace only first occurrence in the file
        sed -i -e '0,/{MYSQL_DATABASE}/s//'$DB_NAME'/' $PROJECT_DOCKER_DIR/.env
    fi
}

fix_permissions () {
    check_domain_exists

    if [[ $DOMAIN_EXISTS == 1 ]];
    then
        get_project_dir "skip_question"

        EMPTY_LINE
        ECHO_YELLOW "Fixing Permissions, this can take a while!"
        if [ "$( docker ps --format '{{.Names}}' | grep -P '(^|_)'$DOCKER_CONTAINER_WP'(?=\s|$)' )" ];
        then
            docker exec -i "$DOCKER_CONTAINER_WP" sh -c 'exec chown -R www-data:www-data /var/www/html/'
            docker exec -i "$DOCKER_CONTAINER_WP" sh -c 'exec chmod -R 755 /var/www/html/'
        else
            ECHO_ERROR "Docker container for this site does not exist"
        fi

        #Fix WP permissions
        if [[ $OSTYPE != "windows" ]];
        then
            if [ -d $PROJECT_ROOT_DIR ];
            then
                sudo chmod -R 777 "$PROJECT_ROOT_DIR" # Suggested Permissions 755
            fi

            if [ -d $PROJECT_CONTENT_DIR ];
            then
                sudo chmod -R 777 "$PROJECT_CONTENT_DIR" # Suggested Permissions 755
                [[ -d "$PROJECT_CONTENT_DIR"/themes ]] && sudo chmod -R 777 "$PROJECT_CONTENT_DIR"/themes # Suggested Permissions 755
                [[ -d "$PROJECT_CONTENT_DIR"/plugins ]] && sudo chmod -R 777 "$PROJECT_CONTENT_DIR"/plugins # Suggested Permissions 755
                [[ -d "$PROJECT_CONTENT_DIR"/uploads ]] && sudo chmod -R 777 "$PROJECT_CONTENT_DIR"/uploads # Suggested Permissions 755
            fi

            git_config_fileMode
        fi

    else
        ECHO_ERROR "Wordpress site not exists"
    fi
}

edit_file_wp_config_setup_beetroot() {

    if [[ -f "$PROJECT_ROOT_DIR/wp-config.php" ]];
    then
        #Replace wp-config variables
        sed -i -e "s/getenv('WP_SITEURL')/getenv('WP_HOME')/g" "$PROJECT_ROOT_DIR/wp-config.php"

        CONFIG_EXISTS=$(awk '/composer_autoload/{print}' "$PROJECT_ROOT_DIR/wp-config.php");

        if [[ -z $CONFIG_EXISTS ]];
        then
            #Include Composer to wp-config (Before first line)
ex  "$PROJECT_ROOT_DIR/wp-config.php" <<EOF
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

edit_file_gitignore() {
    if [[ -f "$PROJECT_ROOT_DIR/.gitignore" ]];
    then
        GITIGNORE_EDITED=$(awk '/wp-docker/{print $1}' "$PROJECT_ROOT_DIR/.gitignore" | head -n 1);

        if [ "$GITIGNORE_EDITED" == '' ];
        then
            EMPTY_LINE
            ECHO_YELLOW "eidt .gitignore file..."
ex  "$PROJECT_ROOT_DIR/.gitignore" <<EOF
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
    fi
}

edit_file_env_setup_beetroot() {
    PROJECT_THEME_DIR=$PROJECT_CONTENT_DIR/themes/$WP_DEFAULT_THEME

    if [[ -f "$PROJECT_THEME_DIR/.env.example" ]];
    then
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
