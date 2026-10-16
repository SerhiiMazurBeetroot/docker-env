#!/bin/bash

# Append Web UI bug-report lines and the per-site failure notice.
# Sourced with the rest of sh/core. Safe to call when jq is missing.

_diagnostic_root() {
	if [[ -n "${DIR_DATA:-}" ]]; then
		printf '%s' "$DIR_DATA"
		return 0
	fi
	printf '%s' "${ENV_DIR:-.}/.env-core/data"
}

_diagnostic_redact() {
	printf '%s' "$1" | sed -E \
		-e 's/(WEBUI_TOKEN|NGROK_AUTH|MYSQL_PWD|MYSQL_ROOT_PASSWORD|PASSWORD|TOKEN|SECRET|GIT_ASKPASS_TOKEN)=[^[:space:]'\''"]+/\1=[redacted]/g' \
		-e 's/Bearer [^[:space:]]+/Bearer [redacted]/g'
}

_diagnostic_lock() {
	local lock="$1"
	local i

	for ((i = 0; i < 40; i++)); do
		if mkdir "$lock" 2>/dev/null; then
			return 0
		fi
		if _diagnostic_lock_stale "$lock"; then
			rmdir "$lock" 2>/dev/null || true
		fi
		sleep 0.05
	done
	return 1
}

_diagnostic_lock_stale() {
	local lock="$1"
	local now mtime

	[[ -d "$lock" ]] || return 1
	now=$(date +%s)
	mtime=$(stat -f %m "$lock" 2>/dev/null || stat -c %Y "$lock" 2>/dev/null || printf '%s' "$now")
	[[ $((now - mtime)) -gt 5 ]]
}

_diagnostic_unlock() {
	rmdir "$1" 2>/dev/null || true
}

_diagnostic_now() {
	date -u +%Y-%m-%dT%H:%M:%SZ
}

_diagnostic_epoch() {
	local stamp="$1"
	local epoch

	epoch=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$stamp" +%s 2>/dev/null || true)
	if [[ -z "$epoch" ]]; then
		epoch=$(date -d "$stamp" +%s 2>/dev/null || true)
	fi
	printf '%s' "${epoch:-0}"
}

# record_diagnostic MESSAGE [ACTION] [TARGET] [DETAIL]
record_diagnostic() {
	local message action target detail file lock now last last_msg last_target last_ts now_epoch last_epoch line

	[[ ${TEST_RUNNING:-0} -eq 1 ]] && return 0
	command -v jq >/dev/null 2>&1 || return 0

	message=$(_diagnostic_redact "${1:-}")
	action=$(_diagnostic_redact "${2:-cli}")
	target=$(_diagnostic_redact "${3:-}")
	detail=$(_diagnostic_redact "${4:-}")
	[[ -n "$message" ]] || return 0

	file="$(_diagnostic_root)/diagnostics.jsonl"
	mkdir -p "$(dirname "$file")" || return 0
	lock="${file}.lock"
	_diagnostic_lock "$lock" || return 0

	now=$(_diagnostic_now)
	now_epoch=$(date +%s)
	if [[ -s "$file" ]]; then
		last=$(tail -n 1 "$file" 2>/dev/null || true)
		last_msg=$(printf '%s' "$last" | jq -r '.message // empty' 2>/dev/null || true)
		last_target=$(printf '%s' "$last" | jq -r '.target // empty' 2>/dev/null || true)
		last_ts=$(printf '%s' "$last" | jq -r '.ts // empty' 2>/dev/null || true)
		last_epoch=$(printf '%s' "$last" | jq -r '.epoch // empty' 2>/dev/null || true)
		if [[ -z "$last_epoch" || "$last_epoch" == "null" ]]; then
			last_epoch=$(_diagnostic_epoch "$last_ts")
		fi
		if [[ "$last_msg" == "$message" && "$last_target" == "$target" && $((now_epoch - last_epoch)) -lt 600 ]]; then
			_diagnostic_unlock "$lock"
			return 0
		fi
	fi

	line=$(jq -nc \
		--arg ts "$now" \
		--argjson epoch "$now_epoch" \
		--arg action "$action" \
		--arg target "$target" \
		--arg message "$message" \
		--arg detail "$detail" \
		'{ts:$ts,epoch:$epoch,level:"error",source:"cli",action:$action,target:$target,message:$message,detail:$detail}') || {
		_diagnostic_unlock "$lock"
		return 0
	}
	printf '%s\n' "$line" >>"$file"
	chmod 600 "$file" 2>/dev/null || true
	_diagnostic_unlock "$lock"

	[[ -n "$target" ]] && record_site_notice "$target" "$action" "$message"
	return 0
}

record_site_notice() {
	local domain="$1"
	local action="$2"
	local message="$3"
	local file lock tmp now

	[[ ${TEST_RUNNING:-0} -eq 1 ]] && return 0
	[[ -n "$domain" ]] || return 0
	command -v jq >/dev/null 2>&1 || return 0

	file="$(_diagnostic_root)/webui-last-actions.json"
	mkdir -p "$(dirname "$file")" || return 0
	lock="${file}.lock"
	_diagnostic_lock "$lock" || return 0
	[[ -f "$file" ]] || printf '%s\n' '{}' >"$file"
	now=$(_diagnostic_now)
	tmp=$(mktemp "${TMPDIR:-/tmp}/docker-env-notice.XXXXXX") || {
		_diagnostic_unlock "$lock"
		return 0
	}
	if jq --arg domain "$domain" --arg action "$action" --arg message "$message" --arg at "$now" \
		'.[$domain] = {action:$action, ok:false, message:$message, at:$at}' "$file" >"$tmp"; then
		mv "$tmp" "$file"
		chmod 600 "$file" 2>/dev/null || true
	else
		rm -f "$tmp"
	fi
	_diagnostic_unlock "$lock"
	return 0
}

clear_site_notice() {
	local domain="$1"
	local action="${2:-ok}"
	local file lock tmp now

	[[ ${TEST_RUNNING:-0} -eq 1 ]] && return 0
	[[ -n "$domain" ]] || return 0
	command -v jq >/dev/null 2>&1 || return 0

	file="$(_diagnostic_root)/webui-last-actions.json"
	[[ -f "$file" ]] || return 0
	lock="${file}.lock"
	_diagnostic_lock "$lock" || return 0
	now=$(_diagnostic_now)
	tmp=$(mktemp "${TMPDIR:-/tmp}/docker-env-notice.XXXXXX") || {
		_diagnostic_unlock "$lock"
		return 0
	}
	if jq --arg domain "$domain" --arg action "$action" --arg at "$now" \
		'.[$domain] = {action:$action, ok:true, message:"", at:$at}' "$file" >"$tmp"; then
		mv "$tmp" "$file"
	else
		rm -f "$tmp"
	fi
	_diagnostic_unlock "$lock"
	return 0
}
