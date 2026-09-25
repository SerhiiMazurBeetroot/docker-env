#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

webui_system_service() {
	local id="${1:-}"
	local name="${2:-}"
	local container="${3:-}"
	local urls="${4:-[]}"
	local actions="${5:-[]}"
	local running=false
	local state="missing"
	local health=""
	local status=""

	if webui_service_running "$container"; then
		running=true
	fi

	if docker inspect "$container" >/dev/null 2>&1; then
		state=$(docker inspect -f '{{.State.Status}}' "$container" 2>/dev/null | tr '[:upper:]' '[:lower:]')
		health=$(docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{end}}' "$container" 2>/dev/null | tr '[:upper:]' '[:lower:]')
		status=$(docker inspect -f '{{.State.Status}}{{if .State.Health}} ({{.State.Health.Status}}){{end}}' "$container" 2>/dev/null)
	fi

	jq -nc \
		--arg id "$id" \
		--arg name "$name" \
		--arg container "$container" \
		--arg state "$state" \
		--arg health "$health" \
		--arg status "$status" \
		--argjson running "$running" \
		--argjson urls "$urls" \
		--argjson actions "$actions" \
		'{id:$id,name:$name,container:$container,running:$running,state:$state,health:$health,status:$status,urls:$urls,actions:$actions}'
}

webui_list_system() {
	local http="http://127.0.0.1:8080"
	local https="https://127.0.0.1"
	local dozzle="http://127.0.0.1:7007"
	local webui
	local actions
	webui=$(webui_url)
	actions='["start","stop","restart"]'

	jq -nc \
		--argjson nginx "$(webui_system_service "nginx" "Nginx" "nginx-proxy" "$(jq -nc --arg http "$http" --arg https "$https" '[{key:"HTTP",url:$http},{key:"HTTPS",url:$https}]')" "$actions")" \
		--argjson dozzle "$(webui_system_service "dozzle" "Dozzle" "nginx-dozzle" "$(jq -nc --arg url "$dozzle" '[{key:"UI",url:$url}]')" "$actions")" \
		--argjson webui "$(webui_system_service "webui" "Web UI" "${WEBUI_CONTAINER:-nginx-webui}" "$(jq -nc --arg url "$webui" '[{key:"UI",url:$url}]')" "[]")" \
		'[$nginx,$dozzle,$webui]'
}

webui_list_payload() {
	local system_json
	system_json=$(webui_list_system)

	if [[ $# -eq 0 ]]; then
		jq -n --argjson system "$system_json" '{ok:true,projects:[],system:$system}'
		return 0
	fi

	printf '%s\n' "$@" | jq -s --argjson system "$system_json" '{ok:true,projects:.,system:$system}' || {
		jq -n --argjson system "${system_json:-[]}" '{ok:false,error:"Could not build project list",projects:[],system:$system}'
	}
}

webui_list_projects() {
	local domain status type full running url row
	local rows=()

	webui_cli_boot

	while IFS= read -r domain; do
		[[ -n "$domain" ]] || continue

		status=$(instances_get status "$domain")
		type=$(instances_get project_type "$domain")
		full=$(instances_get domain_full "$domain")
		running=false

		DOMAIN_NAME="$domain"
		PROJECT_TYPE="${type:-}"
		PROJECT_ROOT_DIR=""
		PROJECT_DOCKER_DIR=""
		DOCKER_CONTAINER_APP=""
		DOMAIN_FRONT=""
		DOMAIN_ADMIN=""
		DOMAIN_DB=""
		DOMAIN_MAIL=""
		DOMAIN_KIBANA=""
		DOMAIN_LOGSTASH=""

		if get_project_dir "skip_question" >/dev/null 2>&1; then
			if container_is_running; then
				running=true
			fi
		fi

		url=""
		[[ -n "$full" ]] && url="https://${full}"

		row=$(jq -nc \
			--arg domain "$domain" \
			--arg status "${status:-}" \
			--arg type "${type:-}" \
			--arg domainFull "${full:-}" \
			--argjson running "$running" \
			--arg url "$url" \
			--argjson urls "$(webui_collect_urls)" \
			--argjson services "$(webui_collect_services)" \
			'{domain:$domain,status:$status,type:$type,domainFull:$domainFull,running:$running,url:$url,urls:$urls,services:$services}')
		rows+=("$row")
	done < <(instances_domain_names)

	webui_list_payload "${rows[@]}"
}

webui_list_types() {
	local i json="[]"
	webui_cli_boot
	env_mode
	build_visible_projects

	for ((i = 0; i < ${#AVAILABLE_PROJECTS[@]}; i++)); do
		json=$(jq -nc --argjson acc "$json" --arg id "${AVAILABLE_PROJECTS[$i]}" --arg title "${PROJECT_TITLES[$i]}" \
			'$acc + [{id:$id,title:$title}]')
	done

	jq -n --argjson types "$json" --arg mode "${ENV_MODE:-}" '{ok:true,types:$types,mode:$mode}'
}
