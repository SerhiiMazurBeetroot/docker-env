#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

check_package_availability() {
    command -v docker-compose >/dev/null 2>&1 || {
        ECHO_ERROR "Please install docker-compose"
        exit 1
    }
}

detect_os() {
    UNAME=$(command -v uname)

    case $("${UNAME}" | tr '[:upper:]' '[:lower:]') in
    linux*)
        OSTYPE='linux'
        ;;
    darwin*)
        OSTYPE='darwin'
        ;;
    msys* | cygwin* | mingw*)
        # or possible 'bash on windows'
        OSTYPE='windows'
        ;;
    nt | win*)
        OSTYPE='windows'
        ;;
    *)
        OSTYPE='unknown'
        ;;
    esac
    export $OSTYPE
}

function versions() {
    ECHO_KEY_VALUE "- docker: " "$(docker --version | awk '{print $3}' | sed -e 's/,//g')"
    ECHO_KEY_VALUE "- compose:" "$(docker-compose --version | awk '{print $3}' | sed -e 's/,//g')"
    ECHO_KEY_VALUE "- nodejs: " "$(node --version)"
}

function is_file() {
    local file=$1
    [[ -f $file ]]
}

function is_dir() {
    local dir=$1
    [[ -d $dir ]]
}
