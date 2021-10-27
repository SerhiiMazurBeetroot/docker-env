#!/bin/bash

EMPTY_LINE () {
    ECHO_TEXT ""
}

ECHO_TEXT () {
    echo -e "${1}"
}

ECHO_KEY_VALUE () {
    echo -e "${WHITE}${1} ${GREEN}${2} ${NC}"
}

ECHO_INFO () {
    echo -e "${CYAN}${1} ${NC}"
}

ECHO_YELLOW () {
    echo -e "${YELLOW}${1} ${NC}"
}

ECHO_GREEN() {
    echo -e "${GREEN}${1} ${NC}"
}

ECHO_ATTENTION () {
    echo -e "${RED}${1} ${NC}"
}

ECHO_SUCCESS () {
    echo -e "${GREEN}[SUCCESS]" "${NC}""${1}"
}

ECHO_WARN_YELLOW () {
    echo -e "${YELLOW}[WARNING]" "${NC}""${1}"
}

ECHO_WARN_RED () {
    echo -e "\033[0;101m[WARNING]${RED}" "${1}""${NC}"
}

ECHO_ERROR () {
    EMPTY_LINE
    echo -e "\033[0;101m[ERROR]${RED}" "${1}""${NC}"
    EMPTY_LINE
}
