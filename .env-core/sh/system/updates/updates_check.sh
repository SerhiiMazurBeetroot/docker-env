#!/bin/bash

# Developer updates check. Compares what the repo pins (compose images,
# Dockerfile ARGs, package-lock.json, CORE_VERSION) with what is running and
# with the newest published release, and writes .env-core/data/updates.json.
#
# Read-only: it never edits a pin, pulls an image, or restarts a container.
# The Web UI shows the result on /updates (ENV_MODE=development only).
#
#   bash updates_check.sh          check when the file is not from today
#   bash updates_check.sh force    check now
#
# catalog_refresh.sh loop calls `updates_check_refresh` once a day.
# Bash 3.2 compatible: no associative arrays, no namerefs.

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

UPDATES_STALE_DAYS=730
UPDATES_EOL_WARN_DAYS=90

updates_file() {
	printf '%s' "${UPDATES_FILE:-${ENV_DIR}/.env-core/data/updates.json}"
}

_updates_log() {
	[[ "${TEST_RUNNING:-0}" == "1" ]] && return 0
	printf '%s %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "updates: $*" >&2
}

_updates_curl() {
	curl -fsS --max-time 20 -A 'docker-env-updates' "$1"
}

# Path relative to ENV_DIR, for the "edit here" hint.
_updates_rel() {
	local path="$1"
	printf '%s' "${path#"${ENV_DIR%/}"/}"
}

# ---------------------------------------------------------------------------
# Version helpers (pure; covered by tests/unit/test_updates_check.sh)
# ---------------------------------------------------------------------------

# updates_newer A B: success when version A is newer than B.
updates_newer() {
	local a="${1#v}" b="${2#v}"
	[[ -n "$a" && -n "$b" && "$a" != "$b" ]] || return 1
	[[ "$(printf '%s\n%s\n' "$a" "$b" | sort -V | tail -n 1)" == "$a" ]]
}

updates_major() {
	local v="${1#v}"
	printf '%s' "${v%%.*}"
}

# updates_split_image REF -> "repo<TAB>tag" (tag defaults to latest).
updates_split_image() {
	local ref="$1" repo tag
	repo="${ref%%@*}"
	if [[ "${repo##*/}" == *:* ]]; then
		tag="${repo##*:}"
		repo="${repo%:*}"
	else
		tag="latest"
	fi
	printf '%s\t%s' "$repo" "$tag"
}

# Docker Hub API path for an image repo: node -> library/node.
updates_hub_repo() {
	local repo="$1"
	if [[ "$repo" != */* ]]; then
		printf 'library/%s' "$repo"
	else
		printf '%s' "$repo"
	fi
}

# Numeric part of a pin tag: v11 -> 11, 1.11 -> 1.11, 29-cli -> 29,
# 24-bookworm-slim -> 24, latest -> "".
updates_tag_number() {
	local tag="${1#v}"
	if [[ "$tag" =~ ^([0-9]+(\.[0-9]+)*) ]]; then
		printf '%s' "${BASH_REMATCH[1]}"
	fi
}

# What follows the number: 29-cli -> -cli, 1.11 -> "".
updates_tag_suffix() {
	local tag="${1#v}" num
	num=$(updates_tag_number "$tag")
	[[ -n "$num" ]] || return 0
	printf '%s' "${tag#"$num"}"
}

# stdin: tag names. Print the newest full X.Y.Z release (v prefix dropped)
# that has SUFFIX and, when PIN is given, sits in that series (1.11 -> 1.11.x).
updates_pick_release() {
	local pin="${1:-}" suffix="${2:-}" line num best=""
	while IFS= read -r line; do
		line="${line%$'\r'}"
		line="${line#v}"
		[[ "$line" == *"$suffix" ]] || continue
		num="${line%"$suffix"}"
		[[ "$num" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || continue
		if [[ -n "$pin" && "$num" != "$pin" && "$num" != "$pin".* ]]; then
			continue
		fi
		if [[ -z "$best" ]] || updates_newer "$num" "$best"; then
			best="$num"
		fi
	done
	printf '%s' "$best"
}

# updates_days_between YYYY-MM-DD YYYY-MM-DD -> whole days (b - a).
updates_days_between() {
	local a b
	a=$(_updates_epoch "$1") || return 1
	b=$(_updates_epoch "$2") || return 1
	printf '%s' $(((b - a) / 86400))
}

_updates_epoch() {
	local day="${1:0:10}"
	date -u -d "$day" +%s 2>/dev/null || date -u -j -f '%Y-%m-%d' "$day" +%s 2>/dev/null
}

# ---------------------------------------------------------------------------
# Pin readers (pure; read repo files only)
# ---------------------------------------------------------------------------

# updates_compose_images FILE -> "service|container|image|line" (| keeps empty fields)
updates_compose_images() {
	awk '
		{ sub(/\r$/, "") }
		/^services:/ { in_services = 1; next }
		/^[^ #]/ { in_services = 0 }
		!in_services { next }
		/^  [A-Za-z0-9_.-]+:[ \t]*$/ {
			flush()
			service = $1; sub(/:$/, "", service)
			next
		}
		/^    container_name:/ { container = $2 }
		/^    image:/ { image = $2; line = NR }
		END { flush() }
		function flush() {
			if (service != "" && image != "") print service "|" container "|" image "|" line
			service = ""; container = ""; image = ""; line = ""
		}
	' "$1"
}

# updates_dockerfile_arg FILE NAME -> "value<TAB>line"
updates_dockerfile_arg() {
	awk -v name="$2" '
		{ sub(/\r$/, "") }
		$1 == "ARG" && index($2, name "=") == 1 {
			print substr($2, length(name) + 2) "\t" NR
			exit
		}
	' "$1"
}

# updates_npm_pins PACKAGE_JSON LOCK_JSON -> "name|spec|locked|line"
updates_npm_pins() {
	local pkg="$1" lock="$2" name spec locked line
	while IFS=$'\t' read -r name spec; do
		[[ -n "$name" ]] || continue
		locked=""
		if [[ -f "$lock" ]]; then
			locked=$(jq -r --arg key "node_modules/$name" '.packages[$key].version // empty' "$lock" 2>/dev/null || true)
		fi
		line=$(grep -n -F "\"$name\":" "$pkg" | head -n 1 | cut -d: -f1)
		printf '%s|%s|%s|%s\n' "$name" "$spec" "$locked" "${line:-}"
	done < <(jq -r '(.dependencies // {}) + (.devDependencies // {}) | to_entries[] | "\(.key)\t\(.value)"' "$pkg")
}

# Repo slug for release checks: UPDATES_REPO, the git remote, then MAIN_REPO.
updates_repo_slug() {
	local url=""
	if [[ -n "${UPDATES_REPO:-}" ]]; then
		printf '%s' "$UPDATES_REPO"
		return 0
	fi
	url=$(git -C "$ENV_DIR" remote get-url origin 2>/dev/null || true)
	if [[ "$url" =~ github\.com[:/]([^/]+/[^/]+)$ ]]; then
		printf '%s' "${BASH_REMATCH[1]%.git}"
		return 0
	fi
	printf '%s' "${MAIN_REPO:-}"
}

# ---------------------------------------------------------------------------
# Remote lookups. Each prints a value or nothing; a failure adds to errors.
# ---------------------------------------------------------------------------

UPDATES_ERRORS=()
UPDATES_FETCHED=0

_updates_fail() {
	UPDATES_ERRORS+=("$1")
	_updates_log "$1"
}

# _updates_hub_tags REPO NAME_FILTER -> "name<TAB>last_updated" lines, newest first.
_updates_hub_tags() {
	local repo="$1" filter="$2" body
	body=$(_updates_curl "https://hub.docker.com/v2/repositories/$(updates_hub_repo "$repo")/tags?page_size=100&ordering=last_updated&name=${filter}") || {
		_updates_fail "Docker Hub tags for ${repo} could not be fetched"
		return 1
	}
	UPDATES_FETCHED=$((UPDATES_FETCHED + 1))
	printf '%s' "$body" | jq -r '.results[] | "\(.name)\t\(.last_updated // "")"'
}

UPDATES_NODE_INDEX=""
UPDATES_NODE_SCHEDULE=""

_updates_node_feeds() {
	[[ -n "$UPDATES_NODE_INDEX" ]] && return 0
	UPDATES_NODE_INDEX=$(_updates_curl 'https://nodejs.org/dist/index.json') || {
		UPDATES_NODE_INDEX=""
		_updates_fail "nodejs.org release list could not be fetched"
		return 1
	}
	UPDATES_FETCHED=$((UPDATES_FETCHED + 1))
	UPDATES_NODE_SCHEDULE=$(_updates_curl 'https://raw.githubusercontent.com/nodejs/Release/main/schedule.json') || {
		UPDATES_NODE_SCHEDULE='{}'
		_updates_fail "Node.js release schedule could not be fetched"
	}
}

# ---------------------------------------------------------------------------
# Local Docker state
# ---------------------------------------------------------------------------

# Cached for one check: docker info is slow and is asked once per row.
UPDATES_DOCKER_OK=""

_updates_docker() {
	if [[ -z "$UPDATES_DOCKER_OK" ]]; then
		if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
			UPDATES_DOCKER_OK=1
		else
			UPDATES_DOCKER_OK=0
		fi
	fi
	[[ "$UPDATES_DOCKER_OK" == "1" ]]
}

# _updates_container CONTAINER -> "imageId|configImage|versionLabel"
_updates_container() {
	docker inspect -f '{{.Image}}|{{.Config.Image}}|{{index .Config.Labels "org.opencontainers.image.version"}}' "$1" 2>/dev/null || true
}

_updates_container_env() {
	docker inspect -f '{{range .Config.Env}}{{println .}}{{end}}' "$1" 2>/dev/null | awk -F= -v k="$2" '$1 == k { print substr($0, length(k) + 2); exit }'
}

# ---------------------------------------------------------------------------
# Rows. Each appends one JSON object to UPDATES_ROWS_FILE.
# ---------------------------------------------------------------------------

# _updates_row group id name kind pinned file line running inSeries newest status note apply
_updates_row() {
	jq -cn \
		--arg group "$1" --arg id "$2" --arg name "$3" --arg kind "$4" \
		--arg pinned "$5" --arg file "$6" --arg line "$7" --arg running "$8" \
		--arg inSeries "$9" --arg newest "${10}" --arg status "${11}" \
		--arg note "${12}" --arg apply "${13}" \
		'{group:$group, id:$id, name:$name, kind:$kind, pinned:$pinned,
		  file:$file, line:(($line | tonumber?) // null), running:$running,
		  latestInSeries:$inSeries, latestMajor:$newest, status:$status,
		  note:$note, apply:$apply}' >>"$UPDATES_ROWS_FILE"
}

# Status for a pinned series: newer major beats newer patch beats ok.
# CURRENT is the running version. Without it there is no patch to report:
# a series pin (1.11) already pulls the newest 1.11.x on the next pull.
_updates_series_status() {
	local current="$1" in_series="$2" newest="$3"
	if [[ -n "$newest" && -n "$in_series" ]] && updates_newer "$(updates_major "$newest")" "$(updates_major "$in_series")"; then
		printf 'major'
	elif [[ -n "$in_series" && -n "$current" ]] && updates_newer "$in_series" "$current"; then
		printf 'update'
	elif [[ -z "$in_series" && -z "$newest" ]]; then
		printf 'unknown'
	else
		printf 'ok'
	fi
}

updates_check_images() {
	local compose="${DIR_NGINX:-${ENV_DIR}/.env-core/system/nginx}/docker-compose.yml"
	local service container image line repo tag num suffix tags in_series newest newest_date
	local state running_id running_ref running_ver pinned_id status note days apply rel

	[[ -f "$compose" ]] || return 0
	rel=$(_updates_rel "$compose")
	apply="System → Nginx → Rebuild (recreates nginx, mkcert and dozzle)"

	while IFS='|' read -r service container image line; do
		[[ "$service" == "webui" ]] && continue
		IFS=$'\t' read -r repo tag <<<"$(updates_split_image "$image")"
		num=$(updates_tag_number "$tag")
		suffix=$(updates_tag_suffix "$tag")
		in_series="" newest="" newest_date="" note=""

		if [[ -n "$num" ]]; then
			tags=$(_updates_hub_tags "$repo" "$num") || tags=""
			in_series=$(printf '%s\n' "$tags" | cut -f1 | updates_pick_release "$num" "$suffix")
		fi
		tags=$(_updates_hub_tags "$repo" "${suffix:-.}") || tags=""
		newest=$(printf '%s\n' "$tags" | cut -f1 | updates_pick_release "" "$suffix")
		newest_date=$(printf '%s\n' "$tags" | head -n 1 | cut -f2)

		running_ver="" status=""
		if _updates_docker && [[ -n "$container" ]]; then
			state=$(_updates_container "$container")
			if [[ -z "$state" ]]; then
				note="Container ${container} is not created."
			else
				IFS='|' read -r running_id running_ref running_ver <<<"$state"
				running_ver="${running_ver#v}"
				pinned_id=$(docker image inspect -f '{{.Id}}' "$image" 2>/dev/null || true)
				if [[ "$running_ref" != "$image" || -z "$pinned_id" || "$running_id" != "$pinned_id" ]]; then
					status="recreate"
					note="Running ${running_ref}; the repo pins ${image}."
				fi
				[[ -n "$running_ver" ]] || running_ver="${running_ref##*:}"
			fi
		fi

		if [[ -z "$num" ]]; then
			status="${status:-unpinned}"
			note="${note:+$note }Pin a version instead of ${tag}."
		elif [[ -z "$status" ]]; then
			status=$(_updates_series_status "$running_ver" "$in_series" "$newest")
		fi

		if [[ -n "$newest_date" ]]; then
			days=$(updates_days_between "$newest_date" "$(date -u +%F)" || true)
			if [[ -n "$days" && "$days" -gt "$UPDATES_STALE_DAYS" ]]; then
				note="${note:+$note }No new release since ${newest_date:0:10}."
				[[ "$status" == "ok" ]] && status="stale"
			fi
		fi

		_updates_row images "image:${service}" "$service ($repo)" image "$image" "$rel" "$line" \
			"$running_ver" "$in_series" "$newest" "$status" "$note" "$apply"
	done < <(updates_compose_images "$compose")
}

updates_check_webui_base() {
	local dockerfile="${ENV_DIR}/.env-core/webui/Dockerfile" rel apply
	local value line repo tag major running in_series newest status note end days lts_majors

	[[ -f "$dockerfile" ]] || return 0
	rel=$(_updates_rel "$dockerfile")
	apply="System → Web UI → Rebuild image"

	# Node.js
	IFS=$'\t' read -r value line <<<"$(updates_dockerfile_arg "$dockerfile" NODE_IMAGE)"
	if [[ -n "$value" ]]; then
		IFS=$'\t' read -r repo tag <<<"$(updates_split_image "$value")"
		major=$(updates_tag_number "$tag")
		major="${major%%.*}"
		running="" in_series="" newest="" status="" note=""
		if _updates_docker; then
			running=$(_updates_container_env "${WEBUI_CONTAINER:-nginx-webui}" NODE_VERSION || true)
		fi
		if _updates_node_feeds; then
			in_series=$(printf '%s' "$UPDATES_NODE_INDEX" | jq -r --arg m "v${major}." 'first(.[] | select(.version | startswith($m)) | .version) // empty' | sed 's/^v//')
			# Newest major that is LTS today and not past end of life.
			lts_majors=$(printf '%s' "$UPDATES_NODE_SCHEDULE" | jq -r --arg today "$(date -u +%F)" '
				to_entries[] | select(.value.lts != null and .value.lts <= $today and .value.end > $today) | .key | sub("^v"; "")')
			newest=$(printf '%s\n' "$lts_majors" | grep -E '^[0-9]+$' | sort -n | tail -n 1)
			[[ -n "$newest" ]] && newest="${newest}.x"
			end=$(printf '%s' "$UPDATES_NODE_SCHEDULE" | jq -r --arg k "v${major}" '.[$k].end // empty')
		fi

		if [[ -n "$running" && "$(updates_major "$running")" != "$major" ]]; then
			status="rebuild"
			note="The running Web UI uses Node ${running}; the repo pins ${major}."
		elif [[ -n "$newest" && "${newest%.x}" -gt "$major" ]]; then
			status="major"
		elif [[ -n "$in_series" && -n "$running" ]] && updates_newer "$in_series" "$running"; then
			status="update"
		elif [[ -z "$in_series" ]]; then
			status="unknown"
		else
			status="ok"
		fi
		if [[ -n "${end:-}" ]]; then
			days=$(updates_days_between "$(date -u +%F)" "$end" || true)
			if [[ -n "$days" && "$days" -lt 0 ]]; then
				status="eol"
				note="${note:+$note }Node ${major} reached end of life on ${end}."
			elif [[ -n "$days" && "$days" -lt "$UPDATES_EOL_WARN_DAYS" ]]; then
				note="${note:+$note }Node ${major} reaches end of life on ${end}."
				[[ "$status" == "ok" ]] && status="eol-soon"
			else
				note="${note:+$note }Supported until ${end}."
			fi
		fi

		_updates_row webui "node" "Node.js (Web UI)" node "$value" "$rel" "$line" \
			"$running" "$in_series" "$newest" "$status" "$note" "$apply"
	fi

	# Docker CLI copied into the Web UI image
	IFS=$'\t' read -r value line <<<"$(updates_dockerfile_arg "$dockerfile" DOCKER_CLI_IMAGE)"
	if [[ -n "$value" ]]; then
		local num suffix tags
		IFS=$'\t' read -r repo tag <<<"$(updates_split_image "$value")"
		num=$(updates_tag_number "$tag")
		suffix=$(updates_tag_suffix "$tag")
		running="" in_series="" newest="" note=""
		if _updates_docker; then
			running=$(docker exec "${WEBUI_CONTAINER:-nginx-webui}" docker version --format '{{.Client.Version}}' 2>/dev/null || true)
		fi
		tags=$(_updates_hub_tags "$repo" "${num}.") || tags=""
		in_series=$(printf '%s\n' "$tags" | cut -f1 | updates_pick_release "$num" "$suffix")
		tags=$(_updates_hub_tags "$repo" "${suffix:-.}") || tags=""
		newest=$(printf '%s\n' "$tags" | cut -f1 | updates_pick_release "" "$suffix")

		if [[ -n "$running" && "$(updates_major "$running")" != "$(updates_major "$num")" ]]; then
			status="rebuild"
			note="The running Web UI has Docker CLI ${running}; the repo pins ${num}."
		else
			status=$(_updates_series_status "$running" "$in_series" "$newest")
		fi

		_updates_row webui "docker-cli" "Docker CLI (Web UI)" image "$value" "$rel" "$line" \
			"$running" "$in_series" "$newest" "$status" "$note" "$apply"
	fi
}

updates_check_npm() {
	local dir="${ENV_DIR}/.env-core/webui" rel name spec locked line body latest status note apply encoded

	[[ -f "$dir/package.json" ]] || return 0
	rel=$(_updates_rel "$dir/package.json")

	while IFS='|' read -r name spec locked line; do
		encoded="${name/\//%2f}"
		latest="" note=""
		if body=$(_updates_curl "https://registry.npmjs.org/${encoded}/latest"); then
			UPDATES_FETCHED=$((UPDATES_FETCHED + 1))
			latest=$(printf '%s' "$body" | jq -r '.version // empty')
		else
			_updates_fail "npm registry entry for ${name} could not be fetched"
		fi

		if [[ -z "$latest" || -z "$locked" ]]; then
			status="unknown"
			apply=""
		elif updates_newer "$(updates_major "$latest")" "$(updates_major "$locked")"; then
			status="major"
			apply="cd .env-core/webui && npm install ${name}@${latest}, check the changelog, then System → Web UI → Rebuild image"
		elif updates_newer "$latest" "$locked"; then
			status="update"
			apply="cd .env-core/webui && npm install ${name}@${latest}, then System → Web UI → Rebuild image"
		else
			status="ok"
			apply=""
		fi
		[[ -z "$locked" ]] && note="Not in package-lock.json."

		_updates_row npm "npm:${name}" "$name" npm "$spec" "$rel" "$line" \
			"$locked" "" "$latest" "$status" "$note" "$apply"
	done < <(updates_npm_pins "$dir/package.json" "$dir/package-lock.json")
}

updates_check_release() {
	local setup="${ENV_DIR}/setup.sh" current line slug body latest status note=""

	[[ -f "$setup" ]] || return 0
	line=$(grep -n '^export CORE_VERSION=' "$setup" | head -n 1 | cut -d: -f1)
	current=$(grep -m1 '^export CORE_VERSION=' "$setup" | cut -d= -f2 | tr -d "\"' \r")
	slug=$(updates_repo_slug)
	latest=""

	if [[ -n "$slug" ]]; then
		if body=$(_updates_curl "https://api.github.com/repos/${slug}/releases/latest"); then
			UPDATES_FETCHED=$((UPDATES_FETCHED + 1))
			latest=$(printf '%s' "$body" | jq -r '.tag_name // empty' | sed 's/^v//')
		else
			_updates_fail "Latest GitHub release of ${slug} could not be fetched"
		fi
	else
		note="No GitHub repository found for this checkout."
	fi

	if [[ -z "$latest" ]]; then
		status="unknown"
	elif updates_newer "$latest" "$current"; then
		status="update"
	elif updates_newer "$current" "$latest"; then
		status="ok"
		note="This checkout is ahead of the latest release (${latest})."
	else
		status="ok"
	fi

	_updates_row docker-env "docker-env" "docker-env" release "$current" "setup.sh" "$line" \
		"$current" "" "$latest" "$status" "$note" "git pull in the docker-env folder, then restart docker-env"
}

# ---------------------------------------------------------------------------
# Write, lock, schedule
# ---------------------------------------------------------------------------

updates_check_due() {
	local file stamp
	file=$(updates_file)
	[[ -f "$file" ]] || return 0
	stamp=$(jq -r '.checked // empty' "$file" 2>/dev/null || true)
	[[ "${stamp:0:10}" != "$(date -u +%F)" ]]
}

_updates_lock_dir() {
	printf '%s.lock' "$(updates_file)"
}

_updates_lock() {
	local lock now modified
	lock=$(_updates_lock_dir)
	mkdir -p "$(dirname "$lock")"
	if [[ -d "$lock" ]]; then
		now=$(date +%s)
		modified=$(stat -c %Y "$lock" 2>/dev/null || stat -f %m "$lock" 2>/dev/null || echo "$now")
		if ((now - modified > 600)); then
			rm -rf "$lock"
		fi
	fi
	mkdir "$lock" 2>/dev/null
}

_updates_unlock() {
	rm -rf "$(_updates_lock_dir)"
}

updates_check_write() {
	local file tmp errors_json owner=""

	file=$(updates_file)
	UPDATES_ERRORS=()
	UPDATES_FETCHED=0
	UPDATES_NODE_INDEX=""
	UPDATES_NODE_SCHEDULE=""
	UPDATES_DOCKER_OK=""
	UPDATES_ROWS_FILE=$(mktemp "${TMPDIR:-/tmp}/docker-env-updates.XXXXXX")

	_updates_log "checking pinned versions"
	updates_check_images || true
	updates_check_webui_base || true
	updates_check_npm || true
	updates_check_release || true

	if [[ "$UPDATES_FETCHED" -eq 0 && -f "$file" ]]; then
		_updates_log "every remote lookup failed; keeping the previous file"
		rm -f "$UPDATES_ROWS_FILE"
		return 1
	fi

	if ((${#UPDATES_ERRORS[@]} > 0)); then
		errors_json=$(printf '%s\n' "${UPDATES_ERRORS[@]}" | jq -R . | jq -s .)
	else
		errors_json='[]'
	fi

	tmp=$(mktemp "${TMPDIR:-/tmp}/docker-env-updates-out.XXXXXX")
	if ! jq -s \
		--arg checked "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
		--argjson errors "$errors_json" \
		--argjson docker "$(_updates_docker && echo true || echo false)" \
		'{checked:$checked, docker:$docker, errors:$errors, items:.}' "$UPDATES_ROWS_FILE" >"$tmp"; then
		rm -f "$tmp" "$UPDATES_ROWS_FILE"
		return 1
	fi
	rm -f "$UPDATES_ROWS_FILE"

	if [[ -f "$file" ]]; then
		owner=$(stat -c '%u:%g' "$file" 2>/dev/null || stat -f '%u:%g' "$file" 2>/dev/null || true)
	fi
	mkdir -p "$(dirname "$file")"
	mv "$tmp" "$file"
	chmod 644 "$file" 2>/dev/null || true
	[[ -n "$owner" ]] && chown "$owner" "$file" 2>/dev/null
	_updates_log "wrote ${file} ($(jq '.items | length' "$file") items, ${#UPDATES_ERRORS[@]} errors)"
	return 0
}

# updates_check_refresh [force]
updates_check_refresh() {
	local rc=0
	if [[ "${1:-}" != "force" ]] && ! updates_check_due; then
		return 0
	fi
	if ! _updates_lock; then
		_updates_log "check already running"
		# "Check now" waits for that run, so the caller reads a fresh file.
		if [[ "${1:-}" == "force" ]]; then
			local waited=0
			while [[ -d "$(_updates_lock_dir)" && "$waited" -lt 180 ]]; do
				sleep 1
				waited=$((waited + 1))
			done
		fi
		return 0
	fi
	updates_check_write || rc=$?
	_updates_unlock
	return "$rc"
}

# Daily runs are for developers only.
updates_check_enabled() {
	local settings="${FILE_SETTINGS:-${ENV_DIR}/.env-core/data/settings.log}"
	[[ -f "$settings" ]] || return 1
	grep -qE '^ENV_MODE=["'"'"']?development' "$settings"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
	case "${1:-}" in
	force) updates_check_refresh force ;;
	*) updates_check_refresh ;;
	esac
fi
