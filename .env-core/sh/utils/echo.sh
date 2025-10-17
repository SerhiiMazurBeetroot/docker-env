#!/bin/bash

EMPTY_LINE() {
	ECHO_TEXT ""
}

ECHO_TEXT() {
	echo -e "${1}"
}

ECHO_KEY_VALUE() {
	echo -e "${WHITE}${1} ${GREEN}${2} ${NC}"
}

ECHO_CYAN() {
	echo -e "${CYAN}${1} ${NC}"
}

ECHO_YELLOW() {
	echo -e "${YELLOW}${1} ${NC}"
}

ECHO_GREEN() {
	echo -e "${GREEN}${1} ${NC}"
}

ECHO_RED() {
	echo -e "${RED}${1} ${NC}"
}

ECHO_INFO() {
	EMPTY_LINE
	echo -e "➤ ${CYAN}${1} ${NC}"
}

ECHO_NOTE() {
	EMPTY_LINE
	echo -e "ℹ️ ${LIGHTGRAY}${1} ${NC}"
}

ECHO_LOGO() {
	echo -e "${BLUE}${1} ${NC}"
}

ECHO_ENTER() {
	EMPTY_LINE
	echo -e "✍️ ${YELLOW} ${1} ${NC}"
}

ECHO_ATTENTION() {
	EMPTY_LINE
	echo -e "⚠️ ${RED} ${1} ${NC}"
	EMPTY_LINE
}

ECHO_SUCCESS() {
	echo -e "✅ ${GREEN}[SUCCESS]" "${NC}""${1}"
	EMPTY_LINE
}

ECHO_WARN_YELLOW() {
	echo -e "📦 ${YELLOW}[WARNING]" "${NC}""${1}"
	EMPTY_LINE
}

ECHO_WARN_RED() {
	EMPTY_LINE
	echo -e "📦 \033[0;101m[WARNING]${RED}" "${1}""${NC}"
	EMPTY_LINE
}

ECHO_ERROR() {
	EMPTY_LINE
	echo -e "🛑 \033[0;101m[ERROR]${RED}" "${1}""${NC}"
	EMPTY_LINE
}

GET_USER_INPUT() {
	local prompt_type=$1
	local msg=$2
	local default_choice=$3
	local choice

	if [[ $TEST_RUNNING -eq 1 ]]; then
		choice=${choice:-$default_choice}
	else
		case $prompt_type in
		'select_one_of')
			read -rp "$(ECHO_YELLOW "Please select one of:")" choice
			;;
		'question')
			read -rp "$(ECHO_YELLOW "❓ $msg") [y/n] " choice
			;;
		'enter')
			read -rp "$(ECHO_ENTER "$msg")" choice
			;;
		*) # Default case
			read -rp "$(ECHO_YELLOW "$msg")" choice
			;;
		esac
	fi

	echo "$choice"
}
