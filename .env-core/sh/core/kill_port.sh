#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

port_is_number() {
	local value="${1:-}"
	[[ "$value" =~ ^[0-9]+$ ]] || return 1
	local number=$((10#$value))
	((number >= 1 && number <= 65535))
}

port_listen_pids() {
	local port="$1"
	lsof -nP -t -iTCP:"$port" -sTCP:LISTEN 2>/dev/null | awk 'NF && !seen[$0]++' || true
}

port_command() {
	local pid="$1"
	ps -p "$pid" -o command= 2>/dev/null || true
}

port_emit() {
	local pid="$1"
	local name="$2"
	local port command key

	[[ -z "$pid" || -z "$name" ]] && return 0
	port="${name##*:}"
	key="${port}:${pid}"
	case " ${PORT_SEEN:-} " in
	*" ${key} "*)
		return 0
		;;
	esac
	PORT_SEEN="${PORT_SEEN:-} ${key}"
	command="$(port_command "$pid")"
	command="${command#"${command%%[![:space:]]*}"}"
	printf '%s %s %s\n' "$port" "$pid" "$command"
}

port_collect() {
	local line pid="" name=""
	local PORT_SEEN=""
	while IFS= read -r line; do
		case "$line" in
		p*)
			port_emit "$pid" "$name"
			pid="${line:1}"
			name=""
			;;
		n*)
			name="${line:1}"
			;;
		esac
	done < <(lsof -nP -iTCP -sTCP:LISTEN -F pn 2>/dev/null || true)

	port_emit "$pid" "$name"
}

port_print_rows() {
	local rows="${1:-}"
	if [[ -z "$rows" ]]; then
		ECHO_CYAN "Nothing is listening."
		return 0
	fi

	printf '%-8s %-8s %s\n' "PORT" "PID" "COMMAND"
	local port pid command
	while read -r port pid command; do
		[[ -z "${port:-}" ]] && continue
		printf '%-8s %-8s %s\n' "$port" "$pid" "$command"
	done <<<"$rows"
}

port_cwd() {
	local pid="$1"
	local dir
	dir="$(lsof -a -p "$pid" -d cwd -Fn 2>/dev/null | awk '/^n/ { sub(/^n/, ""); print; exit }' || true)"
	dir="${dir/#$HOME/~}"
	printf '%s' "$dir"
}

port_short_command() {
	local command="$1"
	local bin
	case "$command" in
	*next-server*)
		printf 'next-server'
		;;
	*)
		bin="${command%% *}"
		printf '%s' "$(basename "$bin")"
		;;
	esac
}

port_dev_rows() {
	port_collect | awk '$1+0 >= 3000 && $1+0 <= 3999' | sort -n
}

port_pick_3000() {
	local rows port pid command cwd label choice token
	local -a ports=()
	local -a labels=()
	local -a chosen=()

	if ! command -v lsof >/dev/null 2>&1; then
		ECHO_ERROR "lsof is not installed."
		return 1
	fi

	rows="$(port_dev_rows)"
	if [[ -z "$rows" ]]; then
		ECHO_CYAN "Nothing is listening on ports 3000–3999."
		return 0
	fi

	while read -r port pid command; do
		[[ -z "${port:-}" ]] && continue
		cwd="$(port_cwd "$pid")"
		label="${port}  $(port_short_command "$command")"
		[[ -n "$cwd" ]] && label="${label}  ${cwd}"
		ports+=("$port")
		labels+=("$label")
	done <<<"$rows"

	EMPTY_LINE
	ECHO_CYAN "==== Ports 3000–3999 ==="
	ECHO_YELLOW "[0] Return"
	print_list "${labels[@]}"
	ECHO_NOTE "Enter numbers like 1 3, a port like 3001, or all."

	choice=$(GET_USER_INPUT "enter" "Which ports to stop?")
	choice="${choice:-0}"
	choice="${choice//,/ }"

	if [[ "$choice" == "0" ]]; then
		return 0
	fi

	if [[ "$choice" == "all" ]]; then
		chosen=("${ports[@]}")
	else
		local seen=" "
		for token in $choice; do
			if [[ "$token" =~ ^[0-9]+$ ]] && ((token >= 1 && token <= ${#ports[@]})); then
				port="${ports[$((token - 1))]}"
			elif port_is_number "$token"; then
				port="$token"
				local listed=0 item
				for item in "${ports[@]}"; do
					[[ "$item" == "$port" ]] && listed=1
				done
				if [[ "$listed" -ne 1 ]]; then
					ECHO_ERROR "Port ${port} is not in the 3000–3999 list."
					return 1
				fi
			else
				ECHO_ERROR "Not a choice: ${token}"
				return 1
			fi
			case "$seen" in
			*" $port "*) ;;
			*)
				seen+="$port "
				chosen+=("$port")
				;;
			esac
		done
	fi

	if [[ ${#chosen[@]} -eq 0 ]]; then
		return 0
	fi

	local yn summary
	summary=$(
		IFS=', '
		printf '%s' "${chosen[*]}"
	)
	yn=$(GET_USER_INPUT "question" "Stop ${summary}?" "n")
	case "$yn" in
	[Yy]*)
		local item rc=0
		for item in "${chosen[@]}"; do
			port_stop "$item" 1 || rc=1
		done
		return "$rc"
		;;
	[Nn]*)
		return 0
		;;
	*)
		ECHO_RED "Please answer [y/n]"
		return 1
		;;
	esac
}

port_list() {
	if ! command -v lsof >/dev/null 2>&1; then
		ECHO_ERROR "lsof is not installed."
		return 1
	fi

	local rows
	rows="$(port_collect | sort -n)"
	port_print_rows "$rows"
}

port_show() {
	local port="$1"
	if ! port_is_number "$port"; then
		ECHO_ERROR "Not a port: ${port:-}"
		return 1
	fi

	local rows="" pid command
	while IFS= read -r pid; do
		[[ -z "$pid" ]] && continue
		command="$(port_command "$pid")"
		rows+="${port} ${pid} ${command}"$'\n'
	done < <(port_listen_pids "$port")

	port_print_rows "$rows"
}

port_stop() {
	local port="$1"
	local force="${2:-0}"
	local pid pids

	if ! command -v lsof >/dev/null 2>&1; then
		ECHO_ERROR "lsof is not installed."
		return 1
	fi

	if ! port_is_number "$port"; then
		ECHO_ERROR "Not a port: ${port:-}"
		return 1
	fi

	if ((10#$port < 1024)) && [[ "$force" != "1" ]]; then
		ECHO_ERROR "Port ${port} is below 1024. Confirm in the menu, or pass --force."
		return 1
	fi

	pids="$(port_listen_pids "$port")"
	if [[ -z "$pids" ]]; then
		ECHO_CYAN "Nothing is listening on ${port}."
		return 0
	fi

	while IFS= read -r pid; do
		[[ -z "$pid" ]] && continue
		ECHO_YELLOW "Stopping ${pid}: $(port_command "$pid")"
		kill "$pid" 2>/dev/null || true
	done <<<"$pids"

	sleep 0.4

	pids="$(port_listen_pids "$port")"
	if [[ -n "$pids" ]]; then
		while IFS= read -r pid; do
			[[ -z "$pid" ]] && continue
			ECHO_YELLOW "Force stopping ${pid}"
			kill -9 "$pid" 2>/dev/null || true
		done <<<"$pids"
		sleep 0.2
	fi

	if [[ -n "$(port_listen_pids "$port")" ]]; then
		ECHO_ERROR "Port ${port} is still in use."
		return 1
	fi

	ECHO_SUCCESS "Port ${port} is free."
}

port_menu() {
	local action port yn

	while true; do
		EMPTY_LINE
		ECHO_CYAN "==== Ports ==="
		ECHO_YELLOW "[0] Return to the previous menu"
		ECHO_GREEN "[1] Show listening ports"
		ECHO_GREEN "[2] Stop ports 3000–3999"
		ECHO_GREEN "[3] Stop any port"

		action=$(GET_USER_INPUT "select_one_of")

		case "$action" in
		0)
			return 0
			;;
		1)
			port_list
			;;
		2)
			port_pick_3000
			;;
		3)
			port=$(GET_USER_INPUT "enter" "Port number")
			if ! port_is_number "${port:-}"; then
				ECHO_ERROR "Not a port: ${port:-}"
				continue
			fi
			port_show "$port"
			if [[ -z "$(port_listen_pids "$port")" ]]; then
				continue
			fi
			yn=$(GET_USER_INPUT "question" "Stop everything listening on ${port}?" "n")
			case "$yn" in
			[Yy]*)
				port_stop "$port" 1
				;;
			[Nn]*) ;;
			*)
				ECHO_RED "Please answer [y/n]"
				;;
			esac
			;;
		*)
			ECHO_RED "Invalid option. Try again."
			;;
		esac
	done
}

cli_port() {
	local sub="${1:-list}"
	if [[ $# -gt 0 ]]; then
		shift
	fi

	case "$sub" in
	list)
		port_list
		;;
	kill | stop)
		local force=0
		local ports=()
		local item rc=0

		while [[ $# -gt 0 ]]; do
			case "$1" in
			--force)
				force=1
				shift
				;;
			*)
				ports+=("$1")
				shift
				;;
			esac
		done

		if [[ ${#ports[@]} -eq 0 ]]; then
			port_pick_3000
			return
		fi

		for item in "${ports[@]}"; do
			port_stop "$item" "$force" || rc=1
		done
		return "$rc"
		;;
	*)
		ECHO_ERROR "Usage: docker-env port [list | kill <port>]"
		return 1
		;;
	esac
}
