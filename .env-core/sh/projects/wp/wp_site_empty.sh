#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

wp_site_empty() {
    if [[ $EMPTY_CONTENT != "no" ]]; then
        if [[ $EMPTY_CONTENT == "" ]]; then
            ECHO_ATTENTION "The following command will remove default posts, pages, plugins, themes"
            AGREE=$(GET_USER_INPUT "question" "Are you sure?")

            [[ $AGREE == "n" ]] && actions_existing_project

            running_projects_list "==== Delete site content ===="

            EMPTY_POSTS=$(GET_USER_INPUT "question" "Do you want to remove posts?")
            EMPTY_THEMES=$(GET_USER_INPUT "question" "Do you want to remove default themes?")
            EMPTY_PLUGINS=$(GET_USER_INPUT "question" "Do you want to remove default plugins?")
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
                docker exec -i "$DOCKER_CONTAINER_APP" sh -c 'wp theme delete twentynineteen twentytwenty twentytwentyone twentytwentytwo --allow-root'

                # Set pretty urls
                docker exec -i "$DOCKER_CONTAINER_APP" sh -c 'wp rewrite structure '/%postname%/' --hard --allow-root'
                docker exec -i "$DOCKER_CONTAINER_APP" sh -c 'wp rewrite flush --hard --allow-root'
            fi

            if [[ "y" = "$EMPTY_PLUGINS" || $EMPTY_CONTENT == "yes" ]]; then
                # Remove plugins and themes
                docker exec -i "$DOCKER_CONTAINER_APP" sh -c 'wp plugin delete hello akismet --allow-root'
            fi
        fi
    fi
}
