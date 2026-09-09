#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

is_safe_hostname() {
	local name="${1:-}"
	[[ "$name" =~ ^[A-Za-z0-9]([A-Za-z0-9.-]{0,251}[A-Za-z0-9])?$ ]]
}

is_safe_ident() {
	local name="${1:-}"
	[[ "$name" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]
}

is_https_or_git_url() {
	local url="${1:-}"
	[[ "$url" =~ ^(https://|git@) ]]
}

protect_settings_file() {
	if [[ -f "$FILE_SETTINGS" ]]; then
		chmod 600 "$FILE_SETTINGS" 2>/dev/null || true
	fi
}

# Load KEY=VAL files without executing shell in values (no source).
env_load_file() {
	local file="${1:-}"
	local key value

	[[ -f "$file" ]] || return 1

	while IFS= read -r line || [[ -n "$line" ]]; do
		[[ "$line" =~ ^[[:space:]]*# ]] && continue
		[[ "$line" =~ ^[[:space:]]*$ ]] && continue
		[[ "$line" == *"="* ]] || continue

		key="${line%%=*}"
		value="${line#*=}"
		key="${key%"${key##*[![:space:]]}"}"
		key="${key#"${key%%[![:space:]]*}"}"

		is_safe_ident "$key" || continue
		case "$key" in
		PATH | LD_PRELOAD | LD_LIBRARY_PATH | BASH_ENV | ENV | SHELLOPTS | IFS)
			continue
			;;
		esac

		value="${value#"${value%%[![:space:]]*}"}"
		case "$value" in
		\'*\')
			value="${value#\'}"
			value="${value%\'}"
			;;
		\"*\")
			value="${value#\"}"
			value="${value%\"}"
			;;
		esac

		printf -v "$key" '%s' "$value"
		export "$key"
	done <"$file"
}

mysql_root() {
	local extra="${1:-}"

	docker exec -e MYSQL_PWD="${MYSQL_ROOT_PASSWORD:-}" -i "$DOCKER_CONTAINER_DB" \
		sh -c "${MYSQL_CMD:-mysql} -uroot --silent ${extra}"
}

git_push_origin_with_token() {
	local token="$1"
	local askpass

	askpass=$(mktemp "${TMPDIR:-/tmp}/git-askpass.XXXXXX")
	chmod 700 "$askpass"
	cat >"$askpass" <<'EOF'
#!/bin/sh
case "$1" in
*Username*|*username*) echo "x-access-token" ;;
*) echo "$GIT_ASKPASS_TOKEN" ;;
esac
EOF

	GIT_ASKPASS_TOKEN="$token" GIT_ASKPASS="$askpass" GIT_TERMINAL_PROMPT=0 \
		git push -u origin master
	rm -f "$askpass"
}
