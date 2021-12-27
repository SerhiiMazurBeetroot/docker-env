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

get_existing_domains () {
    if [ -z "$DOMAIN_NAME" ];
    then
        string=$(awk '{print $5}' wp-instances.log | tail -n +2);
        OptionList=($string)

        if [ "$string" ];
        then
            while true;
            do
                EMPTY_LINE
                ECHO_INFO "Your Next choice:"
                ECHO_YELLOW "[0] Return to the previous menu"
                for i in "${!OptionList[@]}";
                do
                    ECHO_KEY_VALUE "[$(($i+1))]" "${OptionList[$i]}"
                done

                ((++i))
                read -rp "$(ECHO_YELLOW "Please select one of:")" choice

                [ -z "$choice" ] && choice=-1
                if (( "$choice" > 0 && "$choice" <= $i )); then
                    DOMAIN_NAME="${OptionList[$(($choice-1))]}"
                    break
                else
                    if [ "$choice" == 0 ];
                    then
                        existing_site_actions
                    else
                        ECHO_WARN_RED "Wrong option"
                    fi
                fi
            done
        else
            ECHO_ERROR "Wordpress sites don't exists"
            main_actions
        fi
    fi
}

get_project_dir () {
    QUESTION=$1

    #DOMAIN_FULL
    if [[ $QUESTION == "skip_question" ]];
    then
        DOMAIN_FULL=$(awk '/'"$DOMAIN_NAME"'/{print $7}' wp-instances.log | head -n 1);
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

check_domain_exists () {
    DOMAIN_CHECK=$(awk '/'"$DOMAIN_NAME"'/{print $5}' wp-instances.log | head -n 1);

    if [[ "$DOMAIN_NAME" == "$DOMAIN_CHECK" ]];
    then
        DOMAIN_EXISTS=1
    else
        DOMAIN_EXISTS=0
    fi
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
            unset DOMAIN_NAME
            docker_wp_create
            ;;

        *) echo "Please answer yes or no" ;;
        esac
    done
}

set_setup_type () {
    EMPTY_LINE
    while true; do
        ECHO_YELLOW "Installation type:"
        ECHO_KEY_VALUE "[1]" "default"
        ECHO_KEY_VALUE "[2]" "custom"
        ECHO_KEY_VALUE "[3]" "beetroot"
        read -rp "$(ECHO_YELLOW "Please select one of:")" SETUP_TYPE

        case $SETUP_TYPE in
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

recommendation_windows_host () {
    QUESTION=$1

	if [[ $OSTYPE == "windows" ]];
    then
        if [[ $QUESTION == "add" ]];
        then
            ECHO_INFO "For Windows User"
            ECHO_GREEN "kindly add the below in the Windows host file"
            ECHO_GREEN "[location C:\Windows\System32\drivers\etc\hosts]"
            ECHO_GREEN "127.0.0.1 $DOMAIN_FULL"
        fi

        if [[ $QUESTION == "rem" ]];
        then
            ECHO_INFO "For Windows User"
            ECHO_GREEN "127.0.0.1 $DOMAIN_FULL"
            ECHO_GREEN "please remember to remove it from the host file"
            ECHO_GREEN "[location C:\Windows\System32\drivers\etc\hosts]"
        fi
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
                sudo chmod -R 777 "$PROJECT_CONTENT_DIR"/themes # Suggested Permissions 755
                sudo chmod -R 777 "$PROJECT_CONTENT_DIR"/plugins # Suggested Permissions 755

                if [ -d "$PROJECT_CONTENT_DIR"/uploads ];
                then
                    sudo chmod -R 777 "$PROJECT_CONTENT_DIR"/uploads # Suggested Permissions 755
                fi
            fi

            git_config_fileMode
        fi

    else
        ECHO_ERROR "Wordpress site not exists"
    fi
}

check_package_availability () {
    command -v docker-compose >/dev/null 2>&1 || { ECHO_ERROR "Please install docker-compose"; exit 1; }
}

check_instances_file_exists () {
    if [ ! -f ./wp-instances.log ];
    then
        PORT=3309
        echo "$PORT | PROTOCOL | DOMAIN_NAME | DOMAIN_FULL | MYSQL_DATABASE |" >> wp-instances.log
    fi
}

# Load/Create enviroment variables
env_file_load () {
    get_domain_name

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

delete_site_data () {
    
    if [ -d $PROJECT_ROOT_DIR ];
    then
        EMPTY_LINE
        ECHO_YELLOW "Deleting Site files and webroot"
        rm -rf $PROJECT_ROOT_DIR
    else
        echo "Webroot not found"
    fi

    #Remove from wp-instances.log
    sed -i -e '/'"$DOMAIN_NAME"'/d' ./wp-instances.log

    #Remove from /etc/hosts
    setup_hosts_file rem
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

detect_os () {
    UNAME=$( command -v uname)

    case $( "${UNAME}" | tr '[:upper:]' '[:lower:]') in
    linux*)
        OSTYPE='linux'
        ;;
    darwin*)
        OSTYPE='darwin'
        ;;
    msys*|cygwin*|mingw*)
        # or possible 'bash on windows'
        OSTYPE='windows'
        ;;
    nt|win*)
        OSTYPE='windows'
        ;;
    *)
        OSTYPE='unknown'
        ;;
    esac
    export $OSTYPE
}

git_config_fileMode() {
    if [ "$(git rev-parse --is-inside-work-tree 2>/dev/null)" == "true" ];
    then
        git config core.fileMode false
    fi
}

existing_projects_list() {
    EMPTY_LINE
    awk 'NR==FNR{for(i=1;i<=NF;i++) 
        max[i] = length($i) > max[i] ? length($i) : max[i]; next} 
    { for(i=1;i<=NF;i++) printf "%-"max[i]"s  ", $i; printf "\n"}' wp-instances.log wp-instances.log
}

running_projects_list() {
    string=$(docker ps -a --format "table {{.Names}}" | grep -w "wordpress" | sed -r 's/'-wordpress'/''/');
    running_container=($string)
    
    if [ "$string" ];
    then
        while true;
        do
            EMPTY_LINE
            ECHO_INFO "Your Next choice:"
            ECHO_YELLOW "[0] Return to main menu"

            for i in "${!running_container[@]}";
            do
                ECHO_KEY_VALUE "[$(($i+1))]" "${running_container[$i]}"
            done

            ((++i))
            read -rp "$(ECHO_YELLOW "Please select one of:")" choice

            [ -z "$choice" ] && choice=-1
            if (( "$choice" > 0 && "$choice" <= $i )); then
                DOMAIN_NAME="${running_container[$(($choice-1))]}"
                break
            else
                if [ "$choice" == 0 ];
                then
                    existing_site_actions
                else
                    ECHO_WARN_RED "Wrong option"
                fi
            fi
        done
    else
        ECHO_ERROR "Wordpress sites not running"
        main_actions
    fi
}

stopped_projects_list() {
    running_string=$(docker ps -a --format "table {{.Names}}" | grep -w "wordpress");
    existing_string=$(awk '{print $5}' wp-instances.log | tail -n +2);

    for I in $existing_string
    do
        existing_container=${existing_container:+$existing_container }$I"-wordpress"
    done

    if [[ "$running_string" && "$existing_container" ]];
    then
        running_container=($running_string)
        running_container=$(printf "%s\|" "${running_container[@]}")

        stopped_container=$(echo "$existing_container" | sed "s/\($running_container\)//g")
        stopped_container=($(echo "$stopped_container" | sed -r 's/'-wordpress'/''/g' ))

        while true;
        do
            EMPTY_LINE
            ECHO_INFO "Your Next choice:"
            ECHO_YELLOW "[0] Return to main menu"

            for i in "${!stopped_container[@]}";
            do
                ECHO_KEY_VALUE "[$(($i+1))]" "${stopped_container[$i]}"
            done

            ((++i))
            read -rp "$(ECHO_YELLOW "Please select one of:")" choice

            [ -z "$choice" ] && choice=-1
            if (( "$choice" > 0 && "$choice" <= $i )); then
                DOMAIN_NAME="${stopped_container[$(($choice-1))]}"
                break
            else
                if [ "$choice" == 0 ];
                then
                    existing_site_actions
                else
                    ECHO_WARN_RED "Wrong option"
                fi
            fi
        done
    else
        ECHO_ERROR "Wordpress sites not running"
        main_actions
    fi
}

get_php_versions () {
    QUESTION=$1

    PHP_LIST=($(curl -s 'https://www.php.net/releases/active.php' | grep -Eo '[0-9]\.[0-9]' | awk '!a[$0]++'));

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
}
