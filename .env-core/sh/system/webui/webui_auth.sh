#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

webui_read_token() {
	[[ -f "${FILE_SETTINGS:-}" ]] || return 0
	awk -F= '/^WEBUI_TOKEN=/{print $2; exit}' "$FILE_SETTINGS" | tr -d '[:space:]'
}

# Create WEBUI_TOKEN in settings.log when missing; sync into nginx compose .env.
webui_ensure_auth_token() {
	local token

	token=$(webui_read_token)
	if [[ -z "$token" ]]; then
		if command -v openssl >/dev/null 2>&1; then
			token=$(openssl rand -hex 24)
		else
			token=$(LC_CTYPE=C tr -dc 'A-Za-z0-9' </dev/urandom | head -c 48)
		fi
		save_settings "WEBUI_TOKEN=$token"
		ECHO_INFO "Web UI token saved. Show it with 1 System → 2 Web UI → 4 Show sign-in token."
	fi

	if [[ -n "${DIR_NGINX:-}" ]]; then
		docker_nginx_set_env_key "$DIR_NGINX/.env" "WEBUI_TOKEN" "$token"
	fi

	printf '%s' "$token"
}

# Print the sign-in token. Callers use this instead of opening settings.log.
webui_show_token() {
	local token

	token=$(webui_read_token)
	if [[ -z "$token" ]]; then
		webui_ensure_auth_token >/dev/null
		token=$(webui_read_token)
	fi
	if [[ -z "$token" ]]; then
		ECHO_ERROR "Could not create the Web UI token"
		return 1
	fi

	EMPTY_LINE
	ECHO_INFO "Paste this on the Web UI login page ($(webui_url)/login)"
	ECHO_KEY_VALUE "WEBUI_TOKEN" "$token"
}

webui_sync_auth_env() {
	[[ -n "${DIR_NGINX:-}" ]] || return 0
	[[ -f "${DIR_NGINX}/docker-compose.yml" ]] || return 0
	grep -qE '^[[:space:]]*webui:' "$DIR_NGINX/docker-compose.yml" || return 0

	webui_ensure_auth_token >/dev/null
}
