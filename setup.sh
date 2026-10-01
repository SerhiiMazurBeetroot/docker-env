#!/bin/bash

# shellcheck disable=SC1091

export CORE_VERSION=3.0.0
export ENV_DIR="${DOCKER_ENV_DIR:-.}"

source "${ENV_DIR}/.env-core/sh/common.sh"

source "$ENV_DIR"/.env-core/sh/autoloader.sh

main_actions() {
	healthcheck
	primary_menu
}

if [[ $# -gt 0 ]]; then
	cli_dispatch "$@"
else
	main_actions
fi
