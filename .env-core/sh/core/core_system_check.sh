#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

check_package_availability() {
    require_command docker "Docker is not installed."
    require_command jq "jq is required."
    require_command node "Node.js is required."
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

env_mode() {
    export ENV_MODE=$(awk '/ENV_MODE/{print $1}' "$FILE_SETTINGS" | sed 's/'ENV_MODE='//')
}

get_cmd_version() {
    local cmd="$1"
    local version_cmd="$2"

    if command -v "$cmd" >/dev/null 2>&1; then
        eval "$version_cmd"
    else
        echo "not installed"
    fi
}

require_command() {
    local cmd="$1"
    local message="$2"

    if ! command -v "$cmd" >/dev/null 2>&1; then
        ECHO_ERROR "$message"
        exit 1
    fi
}

versions() {
    ECHO_CYAN "===== Versions ===="

    ECHO_KEY_VALUE "- docker:" \
        "$(get_cmd_version docker "docker --version | awk '{print \$3}' | sed 's/,//g'")"

    ECHO_KEY_VALUE "- compose:" \
        "$(get_cmd_version docker "docker compose version --short 2>/dev/null || docker-compose --version | awk '{print \$3}'")"

    if [[ -s "$HOME/.nvm/nvm.sh" ]]; then
        source "$HOME/.nvm/nvm.sh"
    fi

    ECHO_KEY_VALUE "- nodejs:" \
        "$(get_cmd_version node "node --version")"

    ECHO_KEY_VALUE "- bash:" \
        "${BASH_VERSION-unknown}"
}


function is_file() {
    local file=$1
    [[ -f $file ]]
}

function is_dir() {
    local dir=$1
    [[ -d $dir ]]
}
