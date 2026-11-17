#!/bin/bash

# Shared setup for unit tests (no Docker, no menus).

UNIT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
UNIT_TMP=$(mktemp -d "${TMPDIR:-/tmp}/docker-env-unit.XXXXXX")

export ENV_DIR="$UNIT_ROOT"
export DOCKER_ENV_DIR="$UNIT_ROOT"
export TEST_RUNNING=1

cleanup_unit_tmp() {
	rm -rf "$UNIT_TMP"
}

trap cleanup_unit_tmp EXIT

# shellcheck disable=SC1091
source "$UNIT_ROOT/.env-core/sh/common.sh"
set +o errexit
# shellcheck disable=SC1091
source "$UNIT_ROOT/.env-core/sh/core/const.sh"
# shellcheck disable=SC1091
source "$UNIT_ROOT/.env-core/sh/core/utils/colors.sh"
# shellcheck disable=SC1091
source "$UNIT_ROOT/.env-core/sh/core/utils/echo.sh"

export DIR_DATA="$UNIT_TMP/data"
mkdir -p "$DIR_DATA"
export FILE_SETTINGS="$DIR_DATA/settings.log"
export FILE_INSTANCES="$DIR_DATA/instances.json"

unit_source() {
	local rel="$1"
	# shellcheck disable=SC1090,SC1091
	source "$UNIT_ROOT/.env-core/sh/$rel"
	# Sourced files load common.sh, which turns errexit back on.
	# Keep it off so one failed assertion does not end the whole run.
	set +o errexit
}
