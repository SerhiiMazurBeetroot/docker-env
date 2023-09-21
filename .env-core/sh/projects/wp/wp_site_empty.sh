#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

wp_site_empty() {
    EMPTY_LINE

    if [[ $EMPTY_CONTENT != "no" ]]; then
        if [[ $EMPTY_CONTENT == "" ]]; then
            ECHO_ATTENTION "The following command will remove default posts, pages, plugins, themes"
            read -rp "$(ECHO_YELLOW "Are you sure?") y/n " AGREE

            [[ $AGREE == "n" ]] && actions_existing_project

            running_projects_list "==== Delete site content ===="

            read -rp "$(ECHO_YELLOW "Do you want to remove posts?") y/n " EMPTY_POSTS
            read -rp "$(ECHO_YELLOW "Do you want to remove default themes?") y/n " EMPTY_THEMES
            read -rp "$(ECHO_YELLOW "Do you want to remove default plugins?") y/n " EMPTY_PLUGINS
        fi

        WP_IS_INSTALLED=$(docker exec -i "$DOCKER_CONTAINER_APP" sh -c 'wp core is-installed --allow-root | echo $?')

        if [[ "$WP_IS_INSTALLED" && $AGREE == "y" || $EMPTY_CONTENT == "yes" ]]; then
            database_auto_backup

            if [[ "y" = "$EMPTY_POSTS" || $EMPTY_CONTENT == "yes" ]]; then
                # Remove all posts, comments, and terms
                docker exec -i "$DOCKER_CONTAINER_APP" sh -c 'wp site empty --yes --allow-root'
            fi

            if [[ "y" = "$EMPTY_THEMES" || $EMPTY_CONTENT == "yes" ]]; then
                # Remove themes
                docker exec -i "$DOCKER_CONTAINER_APP" sh -c 'exec wp theme delete twentynineteen twentytwenty twentytwentyone twentytwentytwo --allow-root'

                # Set pretty urls
                docker exec -i "$DOCKER_CONTAINER_APP" sh -c 'exec wp rewrite structure '/%postname%/' --hard --allow-root'
                docker exec -i "$DOCKER_CONTAINER_APP" sh -c 'exec wp rewrite flush --hard --allow-root'
            fi

            if [[ "y" = "$EMPTY_PLUGINS" || $EMPTY_CONTENT == "yes" ]]; then
                # Remove plugins and themes
                docker exec -i "$DOCKER_CONTAINER_APP" sh -c 'exec wp plugin delete hello akismet --allow-root'
            fi
        fi
    fi
}
