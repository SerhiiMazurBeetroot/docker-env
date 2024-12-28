#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

export CORE_VERSION=2.0.4
export ENV_DIR="${DOCKER_ENV_DIR:-.}"

# shellcheck disable=SC1091
source "$ENV_DIR"/.env-core/sh/autoloader.sh

main_actions() {
	healthcheck
	primary_menu
}

main_actions
