#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

clone_repo () {
    get_existing_domains

    check_domain_exists

    if [[ $DOMAIN_EXISTS == 1 ]];
    then
        get_project_dir "skip_question"
    
        EMPTY_LINE
        ECHO_YELLOW "Getting plugins and themes from the repository"
        read -rp "Clone from repo (url): " URL_CLONE
        while [ -z "$URL_CLONE" ]; do 
            read -rp "Please complete the cloning path: " URL_CLONE
        done

        if [[ "${URL_CLONE}" == *"git@"* ]];
        then
            # replace : => /
            URL_CORRECT=${URL_CLONE//:/\/}
            # replace git@ => https://
            URL_CORRECT=${URL_CORRECT/git@/https://}
        else
            URL_CORRECT=$URL_CLONE
        fi

        # Checking URL
        if curl --output /dev/null --silent --head --fail -k $URL_CORRECT
        then
            ECHO_SUCCESS "URL EXISTS"
            URL_EXISTS=1
        else
            ECHO_WARN_YELLOW "URL NOT EXISTS"
            URL_EXISTS=0
        fi

        if [[ $URL_EXISTS == 1 ]];
        then
            ECHO_YELLOW "Cloning repository to temp..."
            rm -rf $PROJECT_ROOT_DIR/repository
            
            git config --global http.sslVerify false

            git clone "$URL_CLONE" $PROJECT_ROOT_DIR/repository/

            if [ ! -d $PROJECT_DATABASE_DIR/ ];
            then
                ECHO_INFO "Creating DIR wp-database..."
                mkdir $PROJECT_DATABASE_DIR/
            fi

            ECHO_INFO "Please wait, copying themes and plugins..."

            if [[ -d $PROJECT_ROOT_DIR/repository/wp-content || -d $PROJECT_ROOT_DIR/repository/wp-admin || -d $PROJECT_ROOT_DIR/repository/wp-includes ]];
            then
                cp -rf  $PROJECT_ROOT_DIR/repository/. $PROJECT_ROOT_DIR/
            fi

            if [ -d $PROJECT_ROOT_DIR/repository/themes ];
            then
                cp -rf $PROJECT_ROOT_DIR/repository/themes/. $PROJECT_ROOT_DIR/wp-content/themes/
            fi

            if [ -d $PROJECT_ROOT_DIR/repository/plugins ];
            then
                cp -rf $PROJECT_ROOT_DIR/repository/plugins/. $PROJECT_ROOT_DIR/wp-content/plugins/
            fi

            if [ -d $PROJECT_ROOT_DIR/repository/uploads ];
            then
                cp -rf $PROJECT_ROOT_DIR/repository/uploads/. $PROJECT_ROOT_DIR/wp-content/uploads/
            fi

            rm -rf $PROJECT_ROOT_DIR/repository
            ECHO_YELLOW "Themes and plugins copied"

            while true; do
                EMPTY_LINE
                read -rp "$(ECHO_YELLOW "Start importing DB?") Y/n " yn

                case $yn in
                [Yy]*)
                    replace_project_from_db
                    docker_wp_rebuild
                    docker_wp_restart
                    import_db
                    fix_permissions
                    break
                ;;
                [Nn]*)
                    break
                    ;;

                *) echo "Please answer yes or no" ;;
                esac
            done
        else
            ECHO_ERROR "Path is not correct"
            exit;
        fi
    else
        ECHO_ERROR "Docker container for this site does not exist"
    fi
}

get_latest_wp_version () {
    WP_LATEST_VER=$(curl -s 'https://api.github.com/repos/wordpress/wordpress/tags' | grep "name" | head -n 1 | awk '$0=$2' | awk '{gsub(/\"|\",/, ""); print}');
    export WP_LATEST_VER
}

wp_core_install () {    
    docker exec -i "$DOMAIN_NAME"-wordpress sh -c 'exec wp core install --url=https://'$DOMAIN_FULL' --title='$DOMAIN_NAME' --admin_user='$WP_USER' --admin_password='$WP_PASSWORD' --admin_email=example@example.com --allow-root'
}

randpassword(){ 
    WP_PASSWORD=$(LC_CTYPE=C tr -dc A-Za-z0-9_\!\@\#\$\%\^\&\*\(\)-+= < /dev/urandom | head -c 20) || true
}

wp_remove_default_content () {
    EMPTY_LINE
    ECHO_ATTENTION "The following command will remove default posts, pages, plugins, themes"
    read -rp "$(ECHO_YELLOW "Do you want to remove the default content?") Y/n " EMPTY_CONTENT

    if [ "y" = "$EMPTY_CONTENT" ]
    then
        get_existing_domains

        # Remove all posts, comments, and terms
        docker exec -i "$DOMAIN_NAME"-wordpress sh -c 'wp site empty --yes --allow-root'

        # Remove plugins and themes
        docker exec -i "$DOMAIN_NAME"-wordpress sh -c 'exec wp plugin delete hello akismet --allow-root'
        docker exec -i "$DOMAIN_NAME"-wordpress sh -c 'exec wp theme delete twentynineteen twentytwenty --allow-root'

        # Set pretty urls
        docker exec -i "$DOMAIN_NAME"-wordpress sh -c 'exec wp rewrite structure '/%postname%/' --hard --allow-root'
        docker exec -i "$DOMAIN_NAME"-wordpress sh -c 'exec wp rewrite flush --hard --allow-root'
    fi
}
