#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

create_db_dump () {
    get_project_dir "skip_question"

    mkdir -p $PROJECT_DATABASE_DIR/temp

    # Save old files to "/temp" before deleting
    for files in $PROJECT_DATABASE_DIR/*.sql
    do
        if [ -e "$files" ]
        then
            ECHO_TEXT "There are old files to delete"
            mv $PROJECT_DATABASE_DIR/*.sql $PROJECT_DATABASE_DIR/temp
            break
        fi
    done

    file=$PROJECT_DATABASE_DIR/$DUMP_FILE

    # Create dump
    docker exec -i "$DOMAIN_NAME"-mysql sh -c 'exec mysqldump -uroot -p"$MYSQL_ROOT_PASSWORD" "$MYSQL_DATABASE"' > "$file"

    # Check if new backup was created
    if [ -e "$file" ];
    then
        rm -rf $PROJECT_DATABASE_DIR/temp
        ECHO_SUCCESS "Backup done $(date +%Y'-'%m'-'%d' '%H':'%M)"
    else
        ECHO_ERROR "DB dump not created"
        mv $PROJECT_DATABASE_DIR/temp/*.sql $PROJECT_DATABASE_DIR/
        rm -rf $PROJECT_DATABASE_DIR/temp
    fi
    EMPTY_LINE
}

auto_backup_db () {
    running_projects_list

    if [ "$(docker ps -a | grep "$DOMAIN_NAME"-mysql)" ];
    then
        get_db_name

        if [ "$DB_NAME" ];
        then
            ECHO_YELLOW "Creating DB dump..."

            TIMESTAMP=$(date +"%Y-%m-%d-%H%M%S")

            #DUMP_FILE
            DUMP_FILE=dump-$DB_NAME-$TIMESTAMP.sql

            create_db_dump
        fi
    fi

}

export_db () {
    running_projects_list

    if [ "$(docker ps -a | grep "$DOMAIN_NAME"-mysql)" ];
    then
        get_db_name

        if [ "$DB_NAME" ];
        then
            TIMESTAMP=$(date +"%Y-%m-%d-%H%M%S")

            #DUMP_FILE
            EMPTY_LINE
            file1=$DB_NAME.sql
            file2=dump-$DB_NAME-$TIMESTAMP.sql
            ECHO_GREEN "1 - $file1"
            ECHO_GREEN "2 - $file2 [default]"
            read -rp "$(ECHO_YELLOW "Please select one of:")" DUMP_FILE
            if [[ ! "$DUMP_FILE" =~ [1-2] ]];
            then
                DUMP_FILE="$file2"
            elif [[ "$DUMP_FILE" -eq 1 ]];
            then
                DUMP_FILE="$file1"
            elif [[ "$DUMP_FILE" -eq 2 ]];
            then
                DUMP_FILE="$file2"
            fi

            EMPTY_LINE
            ECHO_TEXT "The dump file will be saved as: $DUMP_FILE."

            create_db_dump
        fi
    else
        ECHO_ERROR "Container not running"
    fi
}

import_db () {
    running_projects_list
    get_project_dir "skip_question"

    if [ "$(docker ps -a | grep "$DOMAIN_NAME"-mysql)" ];
    then
        ECHO_GREEN "Wordpress and DB container exists"
        ECHO_YELLOW "Getting DB from '/wp-database/' and updating local"

        DB_FILE=$(find $PROJECT_DATABASE_DIR/ -name "*.sql")
        if [[ "$DB_FILE" ]];
        then
            get_db_name
            env_file_load

            ECHO_GREEN "DB collected, inserting it to the SQL container"
            dbstatus=1
            while [[ $dbstatus != [0] ]]
            do

                if [ "$(docker exec -i "$DOMAIN_NAME"-mysql sh -c 'exec mysql -uroot -p"$MYSQL_ROOT_PASSWORD" --execute "show databases"' | grep $DB_NAME )" ];
                then
                    dbstatus=0
                    ECHO_GREEN "DB found"

                    docker cp $PROJECT_DATABASE_DIR/*.sql "$DOMAIN_NAME"-mysql:/docker-entrypoint-initdb.d/dump.sql

                    # Drop DB
                    docker exec -t -i "$DOMAIN_NAME-mysql"  bash -l -c "mysqladmin drop $DB_NAME -f -uroot -p$MYSQL_ROOT_PASSWORD"

                    # Create empty DB                                        
                    docker exec -t -i "$DOMAIN_NAME-mysql"  bash -l -c "mysqladmin create $DB_NAME -f -uroot -p$MYSQL_ROOT_PASSWORD"

                    # Import DB
                    docker exec -i "$DOMAIN_NAME"-mysql bash -l -c "mysql -uroot -p"$MYSQL_ROOT_PASSWORD" "$MYSQL_DATABASE" < /docker-entrypoint-initdb.d/dump.sql"
                    
                    ECHO_SUCCESS "DB dump for $DOMAIN_FULL inserted"

                    search_replace
                else
                    sleep 5
                    ECHO_YELLOW "Trying to insert DB, awaiting MariaDB container..."

                    # Create empty DB                                        
                    docker exec -t -i "$DOMAIN_NAME-mysql"  bash -l -c "mysqladmin create $DB_NAME -f -uroot -p$MYSQL_ROOT_PASSWORD"
                fi
            done
        else
            ECHO_ERROR "DB dump not found or downloaded"
        fi

    else
        ECHO_ERROR "Container not running"
    fi
}

search_replace () {
    while true; do

        EMPTY_LINE
        read -rp "$(ECHO_YELLOW "Run search-replace? Y/n ")" yn

        case $yn in
        [Yy]*)
            running_projects_list
            check_domain_exists

            if [[ $DOMAIN_EXISTS == 1 ]];
            then
            read -rp "search: " search
            read -rp "replace: " replace

            ECHO_YELLOW "Running search-replace now from $search to $replace, this might take a while!"
            docker exec -i "$DOMAIN_NAME"-wordpress sh -c 'exec wp search-replace --all-tables '$search' '$replace' --allow-root'
            ECHO_SUCCESS "Search-replace done"

            fi
            break
            ;;
        [Nn]*)
            break
            ;;

        *) echo "Please answer yes or no" ;;
        esac
    done
}

replace_project_from_db () {
    get_existing_domains
    get_project_dir "skip_question"

    if [[ -d "$PROJECT_DATABASE_DIR" ]];
    then
        EMPTY_LINE
        ECHO_YELLOW "Replace... DB_NAME & TABLE_PREFIX"

        DOMAIN_FULL=$(awk '/'"$DOMAIN_NAME"'/{print $7}' wp-instances.log | head -n 1);

        PREV_INSTANCES=$(awk '/'"$DOMAIN_NAME"'/{print}' wp-instances.log | head -n 1);
        PREV_DB_NAME=$(awk '/'"$DOMAIN_NAME"'/{print $9}' wp-instances.log | head -n 1);
        NEW_DB_NAME=$(grep 'Database:' projects/$DOMAIN_FULL/wp-database/*.sql | awk '/''/{print $5}' )
        NEW_TABLE_PREFIX=$(grep 'Table structure for table' projects/$DOMAIN_FULL/wp-database/*.sql | awk '/'_comments'/{print $6}' | sed 's/comments//g' | sed 's/`//g' )

        # Replace wp-instances.log
        FIND_DB_NAME='\| '"$PREV_DB_NAME"' \|'
        REPLACE_DB_NAME='\| '"$NEW_DB_NAME"' |'
        NEW_INSTANCES=$(echo $PREV_INSTANCES | sed -r 's/'"$FIND_DB_NAME"'/'"$REPLACE_DB_NAME"'/')
        sed -i -e 's/'"$PREV_INSTANCES"'/'"$NEW_INSTANCES"'/g' wp-instances.log

        # Replace .env
        PREV_DB_ENV=$(awk '/'MYSQL_DATABASE'/{print}' $PROJECT_DOCKER_DIR/.env | head -n 1);
        PREV_TABLE_PREFIX=$(awk '/'TABLE_PREFIX'/{print}' $PROJECT_DOCKER_DIR/.env | head -n 1);
        sed -i -e 's/'"$PREV_DB_ENV"'/'"MYSQL_DATABASE='$NEW_DB_NAME'"'/g' $PROJECT_DOCKER_DIR/.env
        sed -i -e 's/'"$PREV_TABLE_PREFIX"'/'"TABLE_PREFIX='$NEW_TABLE_PREFIX'"'/g' $PROJECT_DOCKER_DIR/.env
    else
        ECHO_ERROR "DB DIR doesn't exists"

    fi
}
