#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

check_domain_exists () {
    DOMAIN_CHECK=$(awk '/'"$DOMAIN_NAME"'/{print $5}' wp-instances.log | head -n 1);

    if [[ "$DOMAIN_NAME" == "$DOMAIN_CHECK" ]];
    then
        DOMAIN_EXISTS=1
    else
        DOMAIN_EXISTS=0
    fi
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

unset_variables () {
    unset DOMAIN_NAME
}
