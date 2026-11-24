#!/bin/bash

# SC2016: the Dockerfile fixture keeps a literal ${...}.
# SC2329: the _updates_curl / _updates_docker stubs are called by the code under test.
# shellcheck disable=SC2016,SC2329

unit_source "system/updates/updates_check.sh"

# --- version helpers --------------------------------------------------------

assert_true "1.11.6 is newer than 1.11.5" updates_newer "1.11.6" "1.11.5"
assert_true "1.10.0 is newer than 1.9.9" updates_newer "1.10.0" "1.9.9"
assert_false "equal versions are not newer" updates_newer "24.1.0" "24.1.0"
assert_false "older is not newer" updates_newer "20.0.0" "24.0.0"
assert_true "v prefix is ignored" updates_newer "v11.5.0" "11.4.3"
assert_false "empty is never newer" updates_newer "" "1.0.0"
assert_eq "24" "$(updates_major "24.22.3")" "major of 24.22.3"
assert_eq "11" "$(updates_major "v11.5.0")" "major drops the v"

assert_eq "nginxproxy/nginx-proxy	1.11" "$(updates_split_image "nginxproxy/nginx-proxy:1.11")" "split repo and tag"
assert_eq "jwilder/nginx-proxy	latest" "$(updates_split_image "jwilder/nginx-proxy")" "no tag means latest"
assert_eq "localhost:5000/app	2" "$(updates_split_image "localhost:5000/app:2")" "registry port is not the tag"
assert_eq "library/node" "$(updates_hub_repo "node")" "official image goes to library/"
assert_eq "amir20/dozzle" "$(updates_hub_repo "amir20/dozzle")" "user image keeps its path"

assert_eq "11" "$(updates_tag_number "v11")" "number of v11"
assert_eq "29" "$(updates_tag_number "29-cli")" "number of 29-cli"
assert_eq "24" "$(updates_tag_number "24-bookworm-slim")" "number of 24-bookworm-slim"
assert_eq "" "$(updates_tag_number "latest")" "latest has no number"
assert_eq "-cli" "$(updates_tag_suffix "29-cli")" "suffix of 29-cli"
assert_eq "" "$(updates_tag_suffix "1.11")" "1.11 has no suffix"

tags=$'1.11.6\n1.11.5\n1.12.0-rc1\n1.11-alpine\nlatest\n1.10.9\n2.0.0'
assert_eq "1.11.6" "$(printf '%s\n' "$tags" | updates_pick_release "1.11")" "newest in the 1.11 series"
assert_eq "2.0.0" "$(printf '%s\n' "$tags" | updates_pick_release "")" "newest release overall"
assert_eq "1.1.0" "$(printf '1.1.0\n1.11.0\n' | updates_pick_release "1.1")" "1.1 does not match 1.11"
assert_eq "29.10.0" "$(printf '29.9.3-cli\n29.10.0-cli\n29.10.0\n30.0.0-dind\n' | updates_pick_release "29" "-cli")" "suffix must match"
assert_eq "11.5.0" "$(printf 'v11.4.3\nv11.5.0\nv11.5.0-alpine\n' | updates_pick_release "11")" "v-prefixed tags"
assert_eq "365" "$(updates_days_between "2025-01-01" "2026-01-01")" "days between two dates"

# --- pin readers ------------------------------------------------------------

fixture="$UNIT_TMP/updates"
mkdir -p "$fixture/.env-core/system/nginx" "$fixture/.env-core/webui"

# CRLF on purpose, like the real compose file. dozzle has no container_name.
printf '%s\r\n' \
	'name: test' \
	'services:' \
	'  nginx:' \
	'    image: nginxproxy/nginx-proxy:1.11' \
	'    container_name: nginx-proxy' \
	'  dozzle:' \
	'    image: amir20/dozzle:latest' \
	'  webui:' \
	'    build: .' \
	'    container_name: nginx-webui' \
	'networks:' \
	'  default:' \
	'    name: dockerwp' >"$fixture/.env-core/system/nginx/docker-compose.yml"

images=$(updates_compose_images "$fixture/.env-core/system/nginx/docker-compose.yml")
assert_eq "nginx|nginx-proxy|nginxproxy/nginx-proxy:1.11|4" "$(sed -n 1p <<<"$images")" "compose image with container and line"
assert_eq "dozzle||amir20/dozzle:latest|7" "$(sed -n 2p <<<"$images")" "empty container_name keeps its field"
assert_eq "2" "$(grep -c . <<<"$images")" "services without image are skipped"

printf '%s\n' \
	'ARG NODE_IMAGE=node:24-bookworm-slim' \
	'ARG DOCKER_CLI_IMAGE=docker:29-cli' \
	'FROM ${DOCKER_CLI_IMAGE} AS dockercli' >"$fixture/.env-core/webui/Dockerfile"
assert_eq "node:24-bookworm-slim	1" "$(updates_dockerfile_arg "$fixture/.env-core/webui/Dockerfile" NODE_IMAGE)" "Dockerfile ARG value and line"
assert_eq "" "$(updates_dockerfile_arg "$fixture/.env-core/webui/Dockerfile" MISSING)" "missing ARG is empty"

cat >"$fixture/.env-core/webui/package.json" <<'JSON'
{
  "dependencies": {
    "next": "^16.4.5",
    "@scope/lib": "1.0.0"
  },
  "devDependencies": {
    "tailwindcss": "^3.4.17"
  }
}
JSON
cat >"$fixture/.env-core/webui/package-lock.json" <<'JSON'
{
  "packages": {
    "node_modules/next": { "version": "16.4.5" },
    "node_modules/tailwindcss": { "version": "3.4.19" }
  }
}
JSON
pins=$(updates_npm_pins "$fixture/.env-core/webui/package.json" "$fixture/.env-core/webui/package-lock.json")
assert_eq "next|^16.4.5|16.4.5|3" "$(sed -n 1p <<<"$pins")" "npm pin with locked version"
assert_eq "@scope/lib|1.0.0||4" "$(sed -n 2p <<<"$pins")" "package missing from the lock keeps its fields"
assert_eq "tailwindcss|^3.4.17|3.4.19|7" "$(sed -n 3p <<<"$pins")" "devDependencies are included"

# --- full check, offline ----------------------------------------------------
# Stub the network and Docker so the whole write path runs without either.

printf '%s\n' 'export CORE_VERSION=3.0.0' >"$fixture/setup.sh"

_updates_docker() { return 1; }
_updates_curl() {
	case "$1" in
	*nginxproxy/nginx-proxy/tags*name=1.11*) printf '%s' '{"results":[{"name":"1.11.6","last_updated":"2026-07-16T00:00:00Z"},{"name":"1.11.5","last_updated":"2026-07-13T00:00:00Z"}]}' ;;
	*nginxproxy/nginx-proxy/tags*) printf '%s' '{"results":[{"name":"latest","last_updated":"2026-11-23T00:00:00Z"},{"name":"1.11.6","last_updated":"2026-07-16T00:00:00Z"}]}' ;;
	*amir20/dozzle/tags*) printf '%s' '{"results":[{"name":"v11.5.0","last_updated":"2026-11-19T00:00:00Z"}]}' ;;
	*docker/tags*name=29.*) printf '%s' '{"results":[{"name":"29.10.0-cli","last_updated":"2026-11-16T00:00:00Z"}]}' ;;
	*docker/tags*) printf '%s' '{"results":[{"name":"30.1.0-cli","last_updated":"2026-11-20T00:00:00Z"},{"name":"29.10.0-cli","last_updated":"2026-11-16T00:00:00Z"}]}' ;;
	*nodejs.org/dist/index.json) printf '%s' '[{"version":"v26.13.1"},{"version":"v24.22.3"},{"version":"v24.22.2"}]' ;;
	*schedule.json) printf '%s' '{"v24":{"lts":"2025-10-28","end":"2028-04-30"},"v26":{"lts":"2026-10-28","end":"2029-04-30"},"v20":{"lts":"2023-10-24","end":"2026-04-30"}}' ;;
	*registry.npmjs.org/next/latest) printf '%s' '{"version":"16.4.6"}' ;;
	*registry.npmjs.org/@scope%2flib/latest) printf '%s' '{"version":"1.0.0"}' ;;
	*registry.npmjs.org/tailwindcss/latest) printf '%s' '{"version":"4.3.5"}' ;;
	*api.github.com/repos/example/docker-env/releases/latest) printf '%s' '{"tag_name":"v3.1.0"}' ;;
	*) return 22 ;;
	esac
}

saved_env_dir="$ENV_DIR"
ENV_DIR="$fixture"
UPDATES_FILE="$fixture/updates.json"
UPDATES_REPO="example/docker-env"
DIR_NGINX="$fixture/.env-core/system/nginx"

assert_true "offline check writes the file" updates_check_refresh force
status_of() { jq -r --arg id "$1" '.items[] | select(.id == $id) | .status' "$UPDATES_FILE"; }
field_of() { jq -r --arg id "$1" --arg f "$2" '.items[] | select(.id == $id) | .[$f] // ""' "$UPDATES_FILE"; }

assert_eq "ok" "$(status_of image:nginx)" "nginx 1.11 is current"
assert_eq "1.11.6" "$(field_of image:nginx latestInSeries)" "nginx latest in series"
assert_eq ".env-core/system/nginx/docker-compose.yml" "$(field_of image:nginx file)" "pin file is relative"
assert_eq "4" "$(field_of image:nginx line)" "pin line is a number"
assert_eq "unpinned" "$(status_of image:dozzle)" "dozzle:latest is flagged"
assert_eq "major" "$(status_of node)" "newer Node LTS is offered"
assert_eq "26.x" "$(field_of node latestMajor)" "newest Node LTS major"
assert_eq "24.22.3" "$(field_of node latestInSeries)" "newest Node 24 patch"
assert_eq "major" "$(status_of docker-cli)" "Docker CLI 30 is a new major"
assert_eq "update" "$(status_of npm:next)" "next has a patch update"
assert_eq "1.0.0" "$(field_of npm:@scope/lib latestMajor)" "scoped package name is encoded"
assert_eq "unknown" "$(status_of npm:@scope/lib)" "package missing from the lock is unknown"
assert_eq "major" "$(status_of npm:tailwindcss)" "tailwind 4 is a new major"
assert_eq "update" "$(status_of docker-env)" "newer docker-env release"
assert_eq "false" "$(jq -r '.docker' "$UPDATES_FILE")" "docker state is recorded"
assert_eq "0" "$(jq -r '.errors | length' "$UPDATES_FILE")" "no lookup errors"
assert_false "check is not due again today" updates_check_due

# Every lookup failing keeps the previous file.
_updates_curl() { return 22; }
before=$(jq -r '.checked' "$UPDATES_FILE")
assert_false "all lookups failing returns an error" updates_check_refresh force
assert_eq "$before" "$(jq -r '.checked' "$UPDATES_FILE")" "previous file is kept"

# Dev-only daily run.
printf '%s\n' 'ENV_MODE=development' >"$FILE_SETTINGS"
assert_true "enabled in development" updates_check_enabled
printf '%s\n' 'ENV_MODE=production' >"$FILE_SETTINGS"
assert_false "disabled outside development" updates_check_enabled
: >"$FILE_SETTINGS"

ENV_DIR="$saved_env_dir"
unset UPDATES_FILE UPDATES_REPO DIR_NGINX
unset -f _updates_docker _updates_curl status_of field_of
