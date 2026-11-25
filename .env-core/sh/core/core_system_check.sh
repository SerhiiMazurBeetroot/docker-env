#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

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
	export OSTYPE
}

# Major version from "v5.7.1", "2.29.7" or "docker-compose version 1.29.2, build …".
_compose_major() {
	local text="${1:-}"
	if [[ "$text" =~ ([0-9]+)\.[0-9]+ ]]; then
		printf '%s' "${BASH_REMATCH[1]}"
	fi
}

# Sets DOCKER_COMPOSE_CMD and COMPOSE_VERSION (major, empty when unknown).
# The `docker compose` plugin wins at any version (v2 … v5 and later); the
# standalone docker-compose binary is only a fallback. Comparing the major
# with 2 sent Compose v5 to a docker-compose binary the Web UI image lacks.
docker_compose_version() {
	local out=""

	if out=$(docker compose version --short 2>/dev/null) && [[ -n "$out" ]]; then
		DOCKER_COMPOSE_CMD="docker compose"
		COMPOSE_VERSION=$(_compose_major "$out")
	elif command -v docker-compose >/dev/null 2>&1; then
		DOCKER_COMPOSE_CMD="docker-compose"
		out=$(docker-compose version --short 2>/dev/null || docker-compose --version 2>/dev/null || true)
		COMPOSE_VERSION=$(_compose_major "$out")
	else
		DOCKER_COMPOSE_CMD="docker compose"
		COMPOSE_VERSION=""
	fi
}

# settings_get KEY [FILE]: value of the first KEY=value line in settings.log.
# Only a line that starts with KEY= counts, so comments and other keys that contain
# KEY are ignored. The value stops at the first space, as the old reads did.
settings_get() {
	local key="${1:-}"
	local file="${2:-${FILE_SETTINGS:-}}"

	[[ -n "$key" && -f "$file" ]] || return 0

	awk -v k="$key" '
		index($0, k "=") == 1 {
			v = substr($0, length(k) + 2)
			sub(/\r$/, "", v)
			split(v, parts, /[ \t]/)
			print parts[1]
			exit
		}
	' "$file"
}

env_mode_accepted() {
	case "${1:-}" in
	"" | development) return 0 ;;
	*) return 1 ;;
	esac
}

env_mode() {
	ENV_MODE=$(settings_get ENV_MODE)
	ENV_MODE="${ENV_MODE#\"}"
	ENV_MODE="${ENV_MODE%\"}"
	ENV_MODE="${ENV_MODE#\'}"
	ENV_MODE="${ENV_MODE%\'}"
	export ENV_MODE

	if [[ ${TEST_RUNNING:-0} -eq 1 ]]; then
		return 0
	fi
	if env_mode_accepted "$ENV_MODE"; then
		return 0
	fi
	if [[ ${ENV_MODE_WARNED:-0} -eq 1 ]]; then
		return 0
	fi
	ENV_MODE_WARNED=1
	# ECHO_WARN_RED "Unknown ENV_MODE '${ENV_MODE}'."
}

versions() {
	EMPTY_LINE
	ECHO_CYAN "===== Versions ===="

	if command -v docker >/dev/null 2>&1; then
		ECHO_KEY_VALUE "- docker:" "$(docker --version | awk '{print $3}' | sed 's/,//g')"
		ECHO_KEY_VALUE "- compose:" "$(docker compose version --short 2>/dev/null || docker-compose --version | awk '{print $3}')"
	else
		ECHO_KEY_VALUE "- docker:" "not installed"
		ECHO_KEY_VALUE "- compose:" "not installed"
	fi

	if [[ -s "$HOME/.nvm/nvm.sh" ]]; then
		# shellcheck disable=SC1090
		source "$HOME/.nvm/nvm.sh"
	fi

	if command -v node >/dev/null 2>&1; then
		ECHO_KEY_VALUE "- nodejs:" "$(node --version)"
	else
		ECHO_KEY_VALUE "- nodejs:" "not installed"
	fi

	ECHO_KEY_VALUE "- bash:" "${BASH_VERSION-unknown}"
}

require_command() {
	local cmd="$1"
	local message="$2"

	if ! command -v "$cmd" >/dev/null 2>&1; then
		ECHO_ERROR "$message"
		exit 1
	fi
}
