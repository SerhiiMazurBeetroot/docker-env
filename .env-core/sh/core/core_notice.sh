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
	get_unique_frontport

	ECHO_INFO "Project URLs:"
	ECHO_KEY_VALUE "DOMAIN_FULL:" "https://$DOMAIN_FULL"

	if [[ $PORT_FRONT =~ ^[0-9]+$ && $PORT_FRONT -ne 0 ]]; then
		ECHO_KEY_VALUE "DOMAIN_FRONT:" "http://localhost:$PORT_FRONT"
	fi

	if [[ $DOMAIN_ADMIN != "" ]]; then
		ECHO_KEY_VALUE "DOMAIN_ADMIN:" "https://$DOMAIN_ADMIN"
	fi

	if [[ $DOMAIN_DB != "" ]]; then
		ECHO_KEY_VALUE "DOMAIN_DB:" "https://$DOMAIN_DB"
	fi

	if [[ $DOMAIN_MAIL != "" ]]; then
		ECHO_KEY_VALUE "DOMAIN_MAIL:" "https://$DOMAIN_MAIL"
	fi

	if [[ $OPEN_LINK == 'open' ]]; then
		google-chrome $DOMAIN_FULL || true
	fi
}

notice_project_vars() {
	OPEN_LINK=$1
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
