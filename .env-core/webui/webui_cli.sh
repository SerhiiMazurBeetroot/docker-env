#!/bin/bash

if [[ -z "${ENV_DIR:-}" ]]; then
	ENV_DIR="${DOCKER_ENV_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
fi
export ENV_DIR
export DOCKER_ENV_DIR="${DOCKER_ENV_DIR:-$ENV_DIR}"

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"
# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/autoloader.sh"

load_project_modules
load_system_modules

webui_dispatch "$@"
