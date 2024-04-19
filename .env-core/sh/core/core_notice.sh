#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

notice_windows_host() {
	QUESTION=$1

	if [[ $OSTYPE == "windows" ]]; then
		if [[ $QUESTION == "add" ]]; then
			ECHO_INFO "For Windows User"
			ECHO_GREEN "127.0.0.1 $DOMAIN_FULL"
			ECHO_GREEN "kindly add it to your Windows host file"
			ECHO_GREEN "Open file in editor path below (ctrl + click)"
			realpath "C:\Windows\System32\drivers\etc\hosts"
		fi

		if [[ $QUESTION == "rem" ]]; then
			ECHO_INFO "For Windows User"
			ECHO_GREEN "127.0.0.1 $DOMAIN_FULL"
			ECHO_GREEN "please remember to remove it from the host file"
			ECHO_GREEN "Open file in editor path below (ctrl + click)"
			realpath "C:\Windows\System32\drivers\etc\hosts"
		fi
	fi
}

notice_project_urls() {
	OPEN_LINK=$1

	if [[ "$OPEN_LINK" == 'open' ]]; then
		ECHO_INFO "Project URLs:"

		URLkeys=("DOMAIN_FULL" "DOMAIN_FRONT" "DOMAIN_ADMIN" "DOMAIN_DB" "DOMAIN_MAIL")
		for key in "${URLkeys[@]}"; do
			value="${!key}"

			if [[ -n "$value" ]]; then
				ECHO_KEY_VALUE "$key:" "https://$value"
			fi
		done

		notice_project_ips "$OPEN_LINK"

		if command -v google-chrome &>/dev/null; then
			google-chrome "https://$DOMAIN_FULL" || true
		else
			echo "Google Chrome is not installed. Skipping opening URL."
		fi
	fi
}

notice_project_ips() {
	OPEN_LINK=$1

	ECHO_INFO "Project IPs:"

	case $PROJECT_TYPE in
	"wordpress" | "projects")
		services=(
			"wordpress:" #don't need port here
		)
		;;
	"elasticsearch")
		services=(
			"elasticsearch:9200"
			"kibana:5601"
		)
		;;
	esac

	for service_info in "${services[@]}"; do
		service=${service_info%%:*}
		port=${service_info#*:}

		get_docker_ip "$DOMAIN_NAME-$service"

		if [[ -n "$DOCKER_IP" ]]; then
			DOMAIN=$(echo "$service" | tr '[:lower:]' '[:upper:]')

			if [ -n "$port" ]; then
				URL="$DOCKER_IP:$port"
			else
				URL="$DOCKER_IP"
			fi
			ECHO_KEY_VALUE "DOMAIN_$DOMAIN:" "http://$URL"
		fi
	done

	env_file_load "update"
}

notice_project_vars() {
	local OPEN_LINK=$1
	ECHO_INFO "Project variables:"

	ECHO_KEY_VALUE "PROJECT_TYPE:" "$PROJECT_TYPE"
	ECHO_KEY_VALUE "DOMAIN_NAME:" "$DOMAIN_NAME"

	for arg in "${ARGS[@]}"; do
		value="${!arg}"

		if [[ -n "$value" ]]; then
			ECHO_KEY_VALUE "$arg:" "$value"
		fi
	done

	notice_project_urls "$OPEN_LINK"
	notice_windows_project_vars

	ECHO_YELLOW "You can find this info in the file ["$PROJECT_DOCKER_DIR"/.env"]
	EMPTY_LINE
}

notice_windows_project_vars() {
	if [[ $OSTYPE == "windows" ]]; then
		ECHO_KEY_VALUE "HOST_NAME:" "127.0.0.1 $DOMAIN_FULL"
		realpath "C:\Windows\System32\drivers\etc\hosts"

	fi
}

notice_composer() {
	if [[ $COMPOSER_ISSUE ]]; then
		ECHO_ERROR "There are problems with composer.json"
		ECHO_INFO "Please update composer.json file in your theme."
		ECHO_INFO "Choose Docker actions and update composer"
		EMPTY_LINE
	fi
}

notice_compose_v2() {
	docker_compose_version

	if [[ $COMPOSE_VERSION == 1 ]]; then
		ECHO_INFO "Please install docker compose V2."
		ECHO_INFO "Help readme 6.5"
		EMPTY_LINE
	fi
}
