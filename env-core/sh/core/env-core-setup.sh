#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

check_all_data () {
    EMPTY_LINE
    ECHO_YELLOW "Check everything before proceeding:"

    while true; do
       ECHO_KEY_VALUE "DOMAIN_NAME:" "$DOMAIN_NAME"
       ECHO_KEY_VALUE "DOMAIN_FULL:" "$DOMAIN_FULL"
       ECHO_KEY_VALUE "WP_VERSION:" "$WP_VERSION"
       ECHO_KEY_VALUE "WP_USER:" "$WP_USER"
       ECHO_KEY_VALUE "WP_PASSWORD:" "$WP_PASSWORD"
       ECHO_KEY_VALUE "PHP_VERSION:" "$PHP_VERSION"
       ECHO_KEY_VALUE "DB_NAME:" "$DB_NAME"
       ECHO_KEY_VALUE "TABLE_PREFIX:" "$TABLE_PREFIX"
       ECHO_YELLOW "You can find this info in the file /projects/$DOMAIN_FULL/wp-docker/.env" 
       EMPTY_LINE

        read -rp "Is that correct? [Y/n] " yn

        case $yn in
        [Yy]*)
            break
            ;;
        [Nn]*)
            ECHO_ERROR "Enter correct information"
            unset_variables
            docker_wp_create
            ;;

        *) echo "Please answer yes or no" ;;
        esac
    done
}

set_setup_type () {
    unset_variables

    EMPTY_LINE
    while true; do
        ECHO_INFO "== Installation type =="
        ECHO_YELLOW "[0] Return to main menu"
        ECHO_KEY_VALUE "[1]" "default"
        ECHO_KEY_VALUE "[2]" "custom"
        ECHO_KEY_VALUE "[3]" "beetroot"
        read -rp "$(ECHO_YELLOW "Please select one of:")" SETUP_TYPE

        case $SETUP_TYPE in
        0)
            main_actions
            ;;
        1)
            get_domain_name
            get_project_dir "$@"
            setup_default_args
            break
            ;;
        2)
            get_domain_name
            get_project_dir "$@"
            setup_custom_args "$@"
            break
            ;;
        3)
            get_domain_name
            get_project_dir "$@"
            setup_default_args
            break
            ;;
        esac
    done
}

setup_default_args () {
    #DB_NAME
    if [[ $DB_NAME == '' ]];
    then
        DB_NAME="db"
    fi

    #TABLE_PREFIX
    if [[ $TABLE_PREFIX == '' ]];
    then
        TABLE_PREFIX="wp_"
    fi

    #WP_VERSION
    EMPTY_LINE
    get_latest_wp_version
    if [[ $WP_VERSION ]];
    then
        true
    elif [[ ! $WP_VERSION ]];
    then
        WP_VERSION=$WP_LATEST_VER
    else
        ECHO_ERROR "Wordpress not supported, please check version"
    fi

    #WP_USER
    [[ $WP_USER == '' ]] && WP_USER=developer

    #WP_PASSWORD
    randpassword
    if [[ ! "$passw" =~ [1-3] ]];
    then
        WP_PASSWORD=1
    elif [[ "$passw" -eq 1 ]];
    then
        WP_PASSWORD=1
    elif [[ "$passw" -eq 2 ]];
    then
        WP_PASSWORD="$WP_PASSWORD"
    elif [[ "$passw" -eq 3 ]];
    then
        EMPTY_LINE
        read -rp "$(ECHO_YELLOW "Your password:")" WP_PASSWORD
    fi

    #PHP_VERSION
    get_php_versions "default"
}

setup_custom_args () {
    #DB_NAME
    EMPTY_LINE
    ECHO_YELLOW "Enter DB_NAME [default 'db']"
    read -rp "DB_NAME: " DB_NAME

    #TABLE_PREFIX
    EMPTY_LINE
    ECHO_YELLOW "Enter DB TABLE_PREFIX, [default 'wp_']" 
    read -rp "DB TABLE_PREFIX: " TABLE_PREFIX

    #WP_VERSION
    EMPTY_LINE
    get_latest_wp_version
    ECHO_YELLOW "Enter WP_VERSION [default $WP_LATEST_VER]" 
    read -rp "WP_VERSION: " WP_VERSION

    #WP_USER
    EMPTY_LINE
    ECHO_YELLOW "Enter WP_USER [default 'developer']"
    read -rp "WP_USER: " WP_USER

    #WP_PASSWORD
    EMPTY_LINE
    ECHO_YELLOW "Enter WP_PASSWORD [default '1']"
    randpassword
    ECHO_GREEN "1 - 1"
    ECHO_GREEN "2 - $WP_PASSWORD"
    ECHO_GREEN "3 - Enter your password"
    read -rp "$(ECHO_YELLOW "Please select one of:")" passw

    #PHP_VERSION
    EMPTY_LINE
    ECHO_YELLOW "Enter PHP_VERSION [default 2nd item]" 
    get_php_versions

    setup_default_args
}

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
    sed -i -e '/'"$DOMAIN_NAME"'/d' ./wp-instances.log

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
        sed -i -e 's/{MYSQL_DATABASE}/'$DB_NAME'/g' $PROJECT_DOCKER_DIR/.env
        sed -i -e 's/{TABLE_PREFIX}/'$TABLE_PREFIX'/g' $PROJECT_DOCKER_DIR/.env
        sed -i -e 's/{DOMAIN_FULL}/'$DOMAIN_FULL'/g' $PROJECT_DOCKER_DIR/.env
        sed -i -e 's/{WP_VERSION}/'$WP_VERSION'/g' $PROJECT_DOCKER_DIR/.env
        sed -i -e 's/{PORT}/'$PORT'/g' $PROJECT_DOCKER_DIR/.env
        sed -i -e 's/{WP_VERSION}/'$WP_VERSION'/g' $PROJECT_DOCKER_DIR/.env
        sed -i -e 's/{WP_USER}/'$WP_USER'/g' $PROJECT_DOCKER_DIR/.env
        sed -i -e 's/{WP_PASSWORD}/'$WP_PASSWORD'/g' $PROJECT_DOCKER_DIR/.env
        sed -i -e 's/{PHP_VERSION}/'$PHP_VERSION'/g' $PROJECT_DOCKER_DIR/.env
    fi
}

fix_permissions () {
    check_domain_exists

    if [[ $DOMAIN_EXISTS == 1 ]];
    then
        get_project_dir "skip_question"

        ECHO_YELLOW "Fixing Permissions, this can take a while!"
        if [ "$(docker ps -a | grep "$DOMAIN_NAME"-wordpress)" ];
        then
            docker exec -i "$DOMAIN_NAME"-wordpress sh -c 'exec chown -R www-data:www-data /var/www/html/'
            docker exec -i "$DOMAIN_NAME"-wordpress sh -c 'exec chmod -R 755 /var/www/html/'
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
