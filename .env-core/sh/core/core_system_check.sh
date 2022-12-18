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

docker_compose_version() {
  if [[ -z $(docker info --format '{{range .ClientInfo.Plugins}}{{if eq .Name "compose"}}{{.Path}}{{end}}{{end}}') ]]; then
    # V1
    COMPOSE_VERSION="$(docker-compose --version | awk '{print $3}' | sed -e 's/,//g' | grep -Eo '[0-9]\.' | head -n 1 | tr -d .)"
  else
    # V2
    COMPOSE_VERSION="$(docker compose version | awk '{print $4}' | sed -e 's/,//g' | grep -Eo '[0-9]\.' | head -n 1 | tr -d .)"
  fi

  [[ $COMPOSE_VERSION == 2 ]] && DOCKER_COMPOSE_CMD="docker compose" || DOCKER_COMPOSE_CMD="docker-compose"
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
