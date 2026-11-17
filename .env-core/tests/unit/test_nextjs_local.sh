#!/bin/bash

unit_source "core/core_security.sh"
unit_source "project/instances/instances.sh"
unit_source "project/setup/nextjs_local.sh"

app="$UNIT_TMP/app"
mkdir -p "$app"
printf '%s\n' '{"name":"app"}' >"$app/package.json"

PROJECT_TYPE="nextjs"
PROJECT_ROOT_DIR="$app"
DOMAIN_NAME="interview"
DOMAIN_FULL="dev.interview.local"
assert_true "package.json site is local" nextjs_is_local

mkdir -p "$app/docker"
printf '%s\n' 'FROM node:22' >"$app/docker/Dockerfile.dev"
assert_false "Dockerfile.dev is the docker template" nextjs_is_local
rm -f "$app/docker/Dockerfile.dev"

printf '%s\n' 'services: {}' >"$app/docker/docker-compose.yml"
assert_true "generated compose without Dockerfile.dev stays local" nextjs_is_local
rm -rf "$app/docker"

PROJECT_TYPE="wordpress"
assert_false "other types are not local" nextjs_is_local

PROJECT_TYPE="nextjs"
DOMAIN_NAME="interview"
COMPOSE_PROJECT_NAME="dev_interview_local"
NODE_VERSION=""
PORT=""
printf '%s\n' '{"sites":[{"port":3313,"status":"active","domain_name":"interview","domain_full":"dev.interview.local","db_name":"db","db_type":"0","project_type":"nextjs","port_front":3313}]}' >"$FILE_INSTANCES"

assert_eq "$app/docker" "$(nextjs_local_compose_dir)" "compose dir is the project docker folder"
nextjs_local_ensure
assert_true "compose file written" test -f "$app/docker/docker-compose.yml"
assert_true "virtual host is set" grep -q "VIRTUAL_HOST" "$app/docker/docker-compose.yml"
assert_true "container joins dockerwp" grep -q "dockerwp" "$app/docker/docker-compose.yml"
assert_true "app dir is mounted" grep -q "\.\./:/app" "$app/docker/docker-compose.yml"
assert_true "hosts name is in env" grep -q "dev.interview.local" "$app/docker/.env"
assert_true "published port comes from instances" grep -q "PORT_FRONT=3313" "$app/docker/.env"
assert_true "still treated as local after compose is written" nextjs_is_local
