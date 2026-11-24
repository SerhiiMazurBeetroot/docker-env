#!/bin/bash

# SC2329: the docker / docker-compose stubs are called by docker_compose_version.
# shellcheck disable=SC2329

unit_source "core/core_system_check.sh"

saved_path="$PATH"
empty_bin="$UNIT_TMP/empty-bin"
mkdir -p "$empty_bin"

assert_eq "5" "$(_compose_major "v5.7.1")" "major of v5.7.1"
assert_eq "2" "$(_compose_major "2.29.7")" "major of 2.29.7"
assert_eq "1" "$(_compose_major "docker-compose version 1.29.2, build 5becea4c")" "major of a v1 banner"
assert_eq "" "$(_compose_major "")" "empty input"

# Compose plugin v5 (the Web UI image): must use `docker compose`, not the
# docker-compose binary the image does not have.
docker() { [[ "$1 $2 $3" == "compose version --short" ]] && printf 'v5.7.1\n'; }
PATH="$empty_bin"
docker_compose_version
PATH="$saved_path"
assert_eq "docker compose" "$DOCKER_COMPOSE_CMD" "plugin v5 uses docker compose"
assert_eq "5" "$COMPOSE_VERSION" "plugin v5 major"

# Plugin v2 still works.
docker() { [[ "$1 $2 $3" == "compose version --short" ]] && printf '2.29.7\n'; }
docker_compose_version
assert_eq "docker compose" "$DOCKER_COMPOSE_CMD" "plugin v2 uses docker compose"

# Plugin present and a docker-compose shim too (Docker Desktop): plugin wins.
docker-compose() { printf '5.5.0\n'; }
docker() { [[ "$1 $2 $3" == "compose version --short" ]] && printf '5.5.0\n'; }
docker_compose_version
assert_eq "docker compose" "$DOCKER_COMPOSE_CMD" "plugin wins over the shim"

# No plugin, standalone v1 binary: fall back to it and report 1 for the notice.
docker() { return 1; }
docker-compose() { [[ "${1:-}" == "--version" ]] && printf 'docker-compose version 1.29.2, build 5becea4c\n' || return 1; }
docker_compose_version
assert_eq "docker-compose" "$DOCKER_COMPOSE_CMD" "no plugin falls back to docker-compose"
assert_eq "1" "$COMPOSE_VERSION" "v1 major for notice_compose_v2"

# Neither: keep `docker compose` so the error names the modern command.
unset -f docker-compose
PATH="$empty_bin"
docker_compose_version
PATH="$saved_path"
assert_eq "docker compose" "$DOCKER_COMPOSE_CMD" "nothing installed keeps docker compose"
assert_eq "" "$COMPOSE_VERSION" "unknown version stays empty"

unset -f docker
DOCKER_COMPOSE_CMD="docker compose"
COMPOSE_VERSION=""
