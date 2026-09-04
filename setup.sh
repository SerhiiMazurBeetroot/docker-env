#!/bin/bash

# shellcheck disable=SC1091

export CORE_VERSION=2.0.8
export ENV_DIR="${DOCKER_ENV_DIR:-.}"

source "${ENV_DIR}/.env-core/sh/common.sh"

source "$ENV_DIR"/.env-core/sh/autoloader.sh

main_actions() {
	healthcheck
	primary_menu
}

main_actions
