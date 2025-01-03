#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

update_file_instances() {
  case $INSTANCES_STATUS in
    "remove")
      sed -i -e '/'"| $DOMAIN_NAME |"'/d' "$FILE_INSTANCES"
      sed -i'.bak' -e '/'"| $DOMAIN_NAME |"'/d' "$FILE_INSTANCES"
      ;;
    
    "archive" | "active" | "inactive")
      PREV_INSTANCES=$(awk '/'" $DOMAIN_NAME "'/{print}' "$FILE_INSTANCES" | head -n 1)
      
      # Create the new line with the updated status
      NEW_INSTANCES=$(echo $PREV_INSTANCES | sed -r 's/(archive|active|inactive)/'"$INSTANCES_STATUS"'/')
      
      sed -i -e 's/'"$PREV_INSTANCES"'/'"$NEW_INSTANCES"'/g' "$FILE_INSTANCES"
      sed -i'.bak' -e 's/'"$PREV_INSTANCES"'/'"$NEW_INSTANCES"'/g' "$FILE_INSTANCES"
      ;;
    
    *)
      echo "Invalid status: $INSTANCES_STATUS"
      ;;
  esac
}

# Load/Create enviroment variables
env_file_load() {
  local ACTION=$1
  get_project_dir "skip_question"

  if [[ $ACTION == '' && -f $PROJECT_DOCKER_DIR/.env ]]; then
    source $PROJECT_DOCKER_DIR/.env
  elif [[ $ACTION == 'create' ]]; then
    sed -i -e 's/{COMPOSE_PROJECT_NAME}/'$COMPOSE_PROJECT_NAME'/g' $PROJECT_DOCKER_DIR/.env
    sed -i -e 's/{DOMAIN_NAME}/'$DOMAIN_NAME'/g' $PROJECT_DOCKER_DIR/.env
    sed -i -e 's/{DOMAIN_FULL}/'$DOMAIN_FULL'/g' $PROJECT_DOCKER_DIR/.env
    sed -i -e 's/{PORT}/'$PORT'/g' $PROJECT_DOCKER_DIR/.env

    #WP
    sed -i -e 's/{WP_VERSION}/'$WP_VERSION'/g' $PROJECT_DOCKER_DIR/.env
    sed -i -e 's/{TABLE_PREFIX}/'$TABLE_PREFIX'/g' $PROJECT_DOCKER_DIR/.env
    sed -i -e 's/{WP_VERSION}/'$WP_VERSION'/g' $PROJECT_DOCKER_DIR/.env
    sed -i -e 's/{WP_USER}/'$WP_USER'/g' $PROJECT_DOCKER_DIR/.env
    sed -i -e 's/{WP_PASSWORD}/'$WP_PASSWORD'/g' $PROJECT_DOCKER_DIR/.env
    sed -i -e 's/{PHP_VERSION}/'$PHP_VERSION'/g' $PROJECT_DOCKER_DIR/.env

    # Headless CMS
    sed -i -e 's/{PORT_FRONT}/'$PORT_FRONT'/g' $PROJECT_DOCKER_DIR/.env

    # Node.js
    sed -i -e 's/{MONGODB_LOCAL_PORT}/'$MONGODB_LOCAL_PORT'/g' $PROJECT_DOCKER_DIR/.env
    sed -i -e 's/{MONGO_EXPRESS_PORT}/'$MONGO_EXPRESS_PORT'/g' $PROJECT_DOCKER_DIR/.env
    sed -i -e 's/{NODE_VERSION}/'$NODE_VERSION'/g' $PROJECT_DOCKER_DIR/.env

    # Directus
    sed -i -e 's/{DIRECTUS_VERSION}/'$DIRECTUS_VERSION'/g' $PROJECT_DOCKER_DIR/.env

    # Elasticsearch
    sed -i -e 's/{ELASTIC_VERSION}/'$ELASTIC_VERSION'/g' $PROJECT_DOCKER_DIR/.env
    sed -i -e 's/{ELASTIC_PORT}/'$ELASTIC_PORT'/g' $PROJECT_DOCKER_DIR/.env
    sed -i -e 's/{KIBANA_PORT}/'$KIBANA_PORT'/g' $PROJECT_DOCKER_DIR/.env
    sed -i -e 's/{LOGSTASH_PORT}/'$LOGSTASH_PORT'/g' $PROJECT_DOCKER_DIR/.env

    [[ "yes" = "$MULTISITE" ]] && wp_multisite_env

    #Replace only first occurrence in the file
    sed -i -e '0,/{MYSQL_DATABASE}/s//'$DB_NAME'/' $PROJECT_DOCKER_DIR/.env

    # delete .env.example
    cd "$PROJECT_ROOT_DIR" && rm -rf .env.example && cd ../../
  elif [[ $ACTION == 'update' ]]; then
    # Elasticsearch
    sed -i "s/^DOMAIN_ELASTIC=.*$/DOMAIN_ELASTIC='$DOMAIN_ELASTIC'/g" "$PROJECT_DOCKER_DIR/.env"
    sed -i "s/^DOMAIN_KIBANA=.*$/DOMAIN_KIBANA='$DOMAIN_KIBANA'/g" "$PROJECT_DOCKER_DIR/.env"

  else
    ECHO_YELLOW ".env file not found, creating..."
    env_file_load "create"
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
