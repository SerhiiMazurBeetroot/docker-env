#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/core/core_loader.sh"

source_files_in "$ENV_DIR/.env-core/sh/core"
source_files_in "$ENV_DIR/.env-core/sh/menus"

# sh/dev is intentionally excluded (local scratch — see sh/dev/README.md).
# project/ and system/ load on demand via load_project_modules / load_system_modules.

export ENV_CORE_INITIALIZED=1
set -o nounset
