#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

database_import_postgres() {
    DB_NAME="$1"
    TEMP_DB=$DB_NAME"_dump"
    DB_USER="$2"
    DB_FILE="/docker-entrypoint-initdb.d/dump.sql"

    # Wait to allow connections to terminate
    while [ $(psql -U $DB_USER -d postgres -tAc "SELECT COUNT(*) FROM pg_stat_activity WHERE datname = '$TEMP_DB';") -gt 0 ]; do
        psql -U $DB_USER -d postgres -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '$TEMP_DB';"

        echo "Waiting for active connections to $TEMP_DB to terminate..."
        sleep 1
    done

    sleep 2

    # Drop temporary database if it exists
    psql -U $DB_USER -d $DB_NAME -c "DROP DATABASE IF EXISTS $TEMP_DB;"

    # Wait to allow connections to terminate
    while [ $(psql -U $DB_USER -d postgres -tAc "SELECT COUNT(*) FROM pg_stat_activity WHERE datname = '$DB_NAME';") -gt 0 ]; do
        psql -U $DB_USER -d postgres -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '$DB_NAME';"

        echo "Waiting for active connections to $DB_NAME to terminate..."
        sleep 1
    done

    sleep 2

    # Copy content to dump (Rename the database)
    psql -U $DB_USER -d postgres -c "ALTER DATABASE $DB_NAME RENAME TO $TEMP_DB;"

    # Create the current database with the original name
    psql -U $DB_USER -d postgres -c "CREATE DATABASE $DB_NAME;"

    # Change the owner of the restored database if needed
    psql -U $DB_USER -d postgres -c "ALTER DATABASE $DB_NAME OWNER TO $DB_USER;"

    # Import database depends on format
    file_format=$(pg_restore --list "$DB_FILE" | grep "Format:" | awk '{print $NF}')

    if [ "$file_format" = "TAR" ]; then
        cat "$DB_FILE" | pg_restore --clean --if-exists -U "$DB_USER" -F t -d "$DB_NAME"
        echo "Export file format is 'TAR'"
    elif [ "$file_format" = "CUSTOM" ]; then
        cat "$DB_FILE" | pg_restore --clean --if-exists -U "$DB_USER" -F c -d "$DB_NAME"
        echo "Export file format is 'CUSTOM'"
    else
        psql -U $DB_USER -d $DB_NAME <$DB_FILE
        echo "Export file format is 'PLAIN"
    fi
}
