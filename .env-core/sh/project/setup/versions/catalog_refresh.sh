#!/bin/bash

# Rebuild .env-core/data/catalog.json from the public release feeds.
# The Web UI container runs `catalog_refresh.sh loop` in the background and
# rewrites the file once a day. A failed fetch keeps the previous file.

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/project/setup/versions/catalog.sh"

version_catalog_log() {
	printf '%s %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*" >&2
}

version_catalog_due() {
	local file today stamp

	[[ "${1:-}" == "force" ]] && return 0
	file=$(version_catalog_file)
	[[ -f "$file" ]] || return 0
	today=$(date -u +%F)
	stamp=$(jq -r '.updated // empty' "$file" 2>/dev/null || true)
	[[ "$stamp" != "$today" ]]
}

# Newest stable release of each major, newest majors first.
version_catalog_pick_majors() {
	local count="$1"
	grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' \
		| sort -V \
		| awk -F. '{ latest[$1]=$0 } END { for (m in latest) print latest[m] }' \
		| sort -Vr \
		| awk -v n="$count" 'NR<=n { print }'
}

# Newest patch of each minor (7.1, 7.0, …), newest minors first.
version_catalog_pick_minors() {
	local count="$1"
	grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' \
		| sort -V \
		| awk -F. '{ latest[$1"."$2]=$0 } END { for (m in latest) print latest[m] }' \
		| sort -Vr \
		| awk -v n="$count" 'NR<=n { print }'
}

version_catalog_lines_json() {
	if (($# == 0)); then
		printf '[]'
		return 0
	fi
	printf '%s\n' "$@" | jq -R . | jq -s .
}

version_catalog_curl() {
	curl -fsS --max-time 30 -A 'docker-env-catalog' "$1"
}

version_catalog_fetch_php() {
	version_catalog_curl 'https://www.php.net/releases/index.php?json' \
		| jq -r '.[].supported_versions[]' \
		| grep -E '^[0-9]+\.[0-9]+$' \
		| sort -Vr \
		| uniq
}

version_catalog_fetch_wordpress() {
	local page body names=""
	for page in 1 2; do
		body=$(version_catalog_curl "https://api.github.com/repos/wordpress/wordpress/tags?per_page=100&page=${page}") || return 1
		names+=$(printf '%s\n' "$body" | jq -r '.[].name')
		names+=$'\n'
	done
	printf '%s\n' "$names" | version_catalog_pick_minors 4
}

version_catalog_fetch_laravel() {
	version_catalog_curl 'https://repo.packagist.org/p2/laravel/laravel.json' \
		| jq -r '.packages["laravel/laravel"][].version | sub("^v";"")' \
		| version_catalog_pick_majors 3
}

version_catalog_fetch_node() {
	version_catalog_curl 'https://raw.githubusercontent.com/nodejs/docker-node/main/versions.json' \
		| jq -r 'keys[]' \
		| grep -E '^[0-9]+$' \
		| sort -Vr \
		| awk 'NR<=3 { print }'
}

version_catalog_fetch_nextjs() {
	version_catalog_curl 'https://registry.npmjs.org/create-next-app' \
		| jq -r '.versions | keys[]' \
		| version_catalog_pick_majors 3
}

version_catalog_fetch_directus() {
	version_catalog_curl 'https://api.github.com/repos/directus/directus/tags?per_page=100' \
		| jq -r '.[].name | sub("^v";"")' \
		| version_catalog_pick_majors 2
}

version_catalog_fetch_elastic() {
	local url="https://hub.docker.com/v2/repositories/library/elasticsearch/tags?page_size=100" page=0 body names=""
	while [[ -n "$url" && "$page" -lt 4 ]]; do
		body=$(version_catalog_curl "$url") || return 1
		names+=$(printf '%s\n' "$body" | jq -r '.results[].name')
		names+=$'\n'
		url=$(printf '%s' "$body" | jq -r '.next // empty')
		page=$((page + 1))
	done
	printf '%s\n' "$names" | version_catalog_pick_majors 2
}

# Print apache image tags for the newest patch of this Git release that Docker Hub has published.
# Return 2 when that minor has no apache image.
version_catalog_wordpress_published() {
	local latest="$1"
	local major minor patch p body tags
	IFS=. read -r major minor patch <<< "$latest"
	for ((p = patch; p >= 0; p--)); do
		body=$(version_catalog_curl "https://hub.docker.com/v2/repositories/library/wordpress/tags?page_size=50&name=${major}.${minor}.${p}-php") || return 1
		tags=$(printf '%s\n' "$body" | jq -r '.results[].name' | grep -E "^${major}[.]${minor}[.]${p}-php[0-9]+[.][0-9]+-apache$" || true)
		if [[ -n "$tags" ]]; then
			printf '%s\n' "$tags"
			return 0
		fi
	done
	return 2
}

version_catalog_capture() {
	local _text _line
	VERSION_CATALOG_LINES=()
	_text=$("$1") || return 1
	while IFS= read -r _line; do
		[[ -n "$_line" ]] && VERSION_CATALOG_LINES+=("$_line")
	done <<< "$_text"
	((${#VERSION_CATALOG_LINES[@]} > 0))
}

version_catalog_lock_dir() {
	printf '%s' "${ENV_DIR}/.env-core/data/catalog-refresh.lock"
}

version_catalog_lock() {
	local lock now modified
	lock=$(version_catalog_lock_dir)
	mkdir -p "$(dirname "$lock")"
	if [[ -d "$lock" ]]; then
		now=$(date +%s)
		modified=$(stat -c %Y "$lock" 2>/dev/null || stat -f %m "$lock" 2>/dev/null || echo "$now")
		if ((now - modified > 900)); then
			rm -rf "$lock"
		fi
	fi
	mkdir "$lock" 2>/dev/null
}

version_catalog_unlock() {
	rm -rf "$(version_catalog_lock_dir)"
}

version_catalog_install() {
	local file tmp owner=""
	file=$(version_catalog_file)
	tmp=$(mktemp "${TMPDIR:-/tmp}/docker-env-catalog.XXXXXX")
	cat >"$tmp"
	if ! jq -e '
		(.php | type == "array" and length > 0)
		and (.wordpress | type == "array" and length > 0)
		and (.wordpressPhp | type == "object")
		and (.laravel | type == "array" and length > 0)
		and (.node | type == "array" and length > 0)
		and (.nextjs | type == "array" and length > 0)
		and (.directus | type == "array" and length > 0)
		and (.elasticsearch | type == "array" and length > 0)
		and (.updated | type == "string" and length > 0)
	' "$tmp" >/dev/null; then
		rm -f "$tmp"
		return 1
	fi
	if [[ -f "$file" ]]; then
		owner=$(stat -c '%u:%g' "$file" 2>/dev/null || stat -f '%u:%g' "$file" 2>/dev/null || true)
	fi
	mkdir -p "$(dirname "$file")"
	mv "$tmp" "$file"
	chmod 644 "$file" 2>/dev/null || true
	if [[ -n "$owner" ]]; then
		chown "$owner" "$file" 2>/dev/null || true
	fi
}

version_catalog_refresh_write() {
	local -a php_list=() wp_candidates=() wp_list=() laravel_list=() node_list=() next_list=() directus_list=() elastic_list=() matched=()
	local line php wp matched_json pairs='{}' today json tags rc

	version_catalog_log "refreshing version catalog"
	version_catalog_capture version_catalog_fetch_php || return 1
	php_list=("${VERSION_CATALOG_LINES[@]}")
	version_catalog_capture version_catalog_fetch_wordpress || return 1
	wp_candidates=("${VERSION_CATALOG_LINES[@]}")
	version_catalog_capture version_catalog_fetch_laravel || return 1
	laravel_list=("${VERSION_CATALOG_LINES[@]}")
	version_catalog_capture version_catalog_fetch_node || return 1
	node_list=("${VERSION_CATALOG_LINES[@]}")
	version_catalog_capture version_catalog_fetch_nextjs || return 1
	next_list=("${VERSION_CATALOG_LINES[@]}")
	version_catalog_capture version_catalog_fetch_directus || return 1
	directus_list=("${VERSION_CATALOG_LINES[@]}")
	version_catalog_capture version_catalog_fetch_elastic || return 1
	elastic_list=("${VERSION_CATALOG_LINES[@]}")

	for wp in "${wp_candidates[@]}"; do
		rc=0
		tags=$(version_catalog_wordpress_published "$wp") || rc=$?
		if [[ "$rc" -eq 1 ]]; then
			return 1
		fi
		if [[ "$rc" -ne 0 || -z "$tags" ]]; then
			continue
		fi
		wp="${tags%%$'\n'*}"
		wp="${wp%%-php*}"
		matched=()
		for php in "${php_list[@]}"; do
			if printf '%s\n' "$tags" | grep -qx "${wp}-php${php}-apache"; then
				matched+=("$php")
			fi
		done
		if ((${#matched[@]} == 0)); then
			continue
		fi
		wp_list+=("$wp")
		matched_json=$(version_catalog_lines_json "${matched[@]}")
		pairs=$(jq -n --argjson pairs "$pairs" --arg wp "$wp" --argjson php "$matched_json" '$pairs + {($wp): $php}')
	done
	((${#wp_list[@]} > 0)) || return 1

	today=$(date -u +%F)
	json=$(jq -n \
		--argjson php "$(version_catalog_lines_json "${php_list[@]}")" \
		--argjson wordpress "$(version_catalog_lines_json "${wp_list[@]}")" \
		--argjson wordpressPhp "$pairs" \
		--argjson laravel "$(version_catalog_lines_json "${laravel_list[@]}")" \
		--argjson node "$(version_catalog_lines_json "${node_list[@]}")" \
		--argjson nextjs "$(version_catalog_lines_json "${next_list[@]}")" \
		--argjson directus "$(version_catalog_lines_json "${directus_list[@]}")" \
		--argjson elasticsearch "$(version_catalog_lines_json "${elastic_list[@]}")" \
		--arg updated "$today" \
		'{php:$php, wordpress:$wordpress, wordpressPhp:$wordpressPhp, laravel:$laravel, node:$node, nextjs:$nextjs, directus:$directus, elasticsearch:$elasticsearch, updated:$updated}') || return 1

	printf '%s\n' "$json" | version_catalog_install || return 1
	version_catalog_log "wrote $(version_catalog_file) wordpress=${wp_list[*]} php=${php_list[*]}"
}

version_catalog_refresh() {
	local rc
	if [[ "${1:-}" != "force" ]] && ! version_catalog_due; then
		return 0
	fi
	if ! version_catalog_lock; then
		version_catalog_log "catalog refresh already running"
		return 0
	fi
	version_catalog_refresh_write
	rc=$?
	version_catalog_unlock
	return "$rc"
}

version_catalog_sleep_until_tomorrow() {
	local now target wait
	now=$(date +%s)
	if ! target=$(date -d 'tomorrow 00:05' +%s 2>/dev/null); then
		target=$(date -j -v+1d -v0H -v5M -v0S +%s)
	fi
	wait=$((target - now))
	if ((wait < 60)); then
		wait=86400
	fi
	version_catalog_log "next catalog refresh in ${wait}s"
	sleep "$wait"
}

version_catalog_refresh_loop() {
	while true; do
		if version_catalog_due; then
			if ! version_catalog_refresh force; then
				version_catalog_log "catalog refresh failed; keeping the previous file"
				sleep 3600
				continue
			fi
		else
			version_catalog_log "catalog is current ($(jq -r '.updated // empty' "$(version_catalog_file)"))"
		fi
		version_catalog_sleep_until_tomorrow
	done
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
	case "${1:-}" in
	loop) version_catalog_refresh_loop ;;
	force) version_catalog_refresh force ;;
	*) version_catalog_refresh ;;
	esac
fi
