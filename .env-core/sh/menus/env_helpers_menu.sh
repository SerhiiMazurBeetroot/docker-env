#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

env_helpers_menu() {
	while true; do
		EMPTY_LINE
		ECHO_CYAN "==== Helpers menu ==="
		ECHO_YELLOW "[0] Return to main menu"
		ECHO_GREEN "[1] Docker"
		ECHO_GREEN "[2] Permissions"
		ECHO_GREEN "[3] Git Tools"
		ECHO_GREEN "[4] Disk Usage"
		ECHO_GREEN "[5] Mac cleanup"

		actions=$(GET_USER_INPUT "select_one_of")

		case $actions in
		0)
			main_actions
			;;
		1)
			env_helpers_docker_menu
			;;
		2)
			if [[ $OSTYPE != "windows" ]]; then
				env_helpers_permisions_menu
			else
				ECHO_TEXT "Oooops. Not allowed."
			fi
			;;
		3)
			env_helpers_git_menu
			;;
		4)
			env_helpers_disk_menu
			;;
		5)
			env_mac_developer_cleanup
			;;
		esac
	done
}

env_helpers_disk_menu() {
	while true; do
		EMPTY_LINE
		ECHO_CYAN "==== Disk Usage menu ==="
		ECHO_YELLOW "[0] Return to main menu"
		ECHO_GREEN "[1] Find large files (300M+)"
		ECHO_GREEN "[2] Show top largest folders"

		actions=$(GET_USER_INPUT "select_one_of")

		case $actions in
		0)
			main_actions
			;;
		1)
			find . -type f -size +300M
			;;
		2)
			if [[ "$(uname)" == "Darwin" ]]; then
				du -h -d 1 | sort -hr | head -n 10
			else
				du -h --max-depth=1 | sort -hr | head -n 10
			fi
			;;
		*)
			ECHO_RED "Invalid option. Try again."
			;;
		esac
	done
}

env_helpers_git_menu() {
	while true; do
		EMPTY_LINE
		ECHO_CYAN "==== GIT menu ==="
		ECHO_YELLOW "[0] Return to main menu"
		ECHO_GREEN "[1] git config core.fileMode false"
		ECHO_GREEN "[2] git_user_info"
		ECHO_GREEN "[3] empty commit"

		actions=$(GET_USER_INPUT "select_one_of")

		case $actions in
		0)
			main_actions
			;;
		1)
			git config core.fileMode false
			EMPTY_LINE
			ECHO_SUCCESS "Git config updated"
			;;
		2)
			git_user_info
			;;
		3)
			git commit --allow-empty -m "Trigger deploy"
			;;
		*)
			ECHO_RED "Invalid option. Try again."
			;;
		esac
	done
}

function git_user_info() {
	local current_user
	# support two or more initials, set by 'git pair' plugin
	current_user="$(git config user.initials | sed 's% %+%')"
	# if `user.initials` weren't set, attempt to extract initials from `user.name`
	[[ -z "${current_user}" ]] && current_user=$(printf "%s" "$(for word in $(git config user.name | PERLIO=:utf8 perl -pe '$_=lc'); do printf "%s" "${word:0:1}"; done)")
	[[ -n "${current_user}" ]] && printf "%s" "${SCM_THEME_CURRENT_USER_PREFFIX-}${current_user}${SCM_THEME_CURRENT_USER_SUFFIX-}"
}

env_helpers_permisions_menu() {
	while true; do
		EMPTY_LINE
		ECHO_CYAN "==== Permissions menu ==="
		ECHO_YELLOW "[0] Return to main menu"
		ECHO_GREEN "[1] Set current dir to 755"
		ECHO_GREEN "[2] Set current dir to 775"
		ECHO_GREEN "[3] Set all files to 644 recursively"
		ECHO_GREEN "[4] Set all dirs to 755 recursively"
		ECHO_GREEN "[5] chmod ug+rwX recursively (current dir)"

		actions=$(GET_USER_INPUT "select_one_of")

		case $actions in
		0)
			main_actions
			;;
		1)
			chmod 755 .
			ECHO_SUCCESS "Set current directory to 755"
			;;
		2)
			chmod 775 .
			ECHO_SUCCESS "Set permissions to 775 for $(pwd)"
			;;
		3)
			find . -type f -exec chmod 644 {} +
			ECHO_SUCCESS "All files set to 644 recursively"
			;;
		4)
			find . -type d -exec chmod 755 {} +
			ECHO_SUCCESS "All directories set to 755 recursively"
			;;
		5)
			sudo chmod -R ug+rwX .
			ECHO_SUCCESS "Set ug+rwX recursively on $(pwd)"
			;;
		*)
			ECHO_RED "Invalid option. Try again."
			;;
		esac
	done
}

env_helpers_docker_menu() {
	while true; do
		EMPTY_LINE
		ECHO_CYAN "==== Docker menu ==="
		ECHO_YELLOW "[0] Return to main menu"
		ECHO_GREEN "[1] Stop and Remove All Containers"
		ECHO_GREEN "[2] Remove All Volumes"
		ECHO_GREEN "[3] Remove All Networks"
		ECHO_GREEN "[4] Remove All Images"
		ECHO_GREEN "[5] Prune All Unused Resources"

		actions=$(GET_USER_INPUT "select_one_of")

		case $actions in
		0)
			main_actions
			;;
		1)
			ECHO_YELLOW "Stopping and removing all containers..."
			if docker ps -aq | grep -q .; then
				docker ps -aq | xargs docker stop >/dev/null 2>&1 || true
				docker ps -aq | xargs docker rm >/dev/null 2>&1 || true
				ECHO_GREEN "✅ All containers stopped and removed."
			else
				ECHO_CYAN "No containers found."
			fi
			;;
		2)
			ECHO_YELLOW "Removing all Docker volumes..."
			volumes=$(docker volume ls -q)
			if [[ -n "$volumes" ]]; then
				echo "$volumes" | xargs -r docker volume rm >/dev/null 2>&1 || true
				ECHO_GREEN "✅ All volumes removed."
			else
				ECHO_CYAN "No volumes found."
			fi
			;;
		3)
			ECHO_YELLOW "Removing all Docker networks..."
			networks=$(docker network ls -q | grep -vE '^(bridge|host|none)$')
			if [[ -n "$networks" ]]; then
				echo "$networks" | xargs -r docker network rm >/dev/null 2>&1 || true
				ECHO_GREEN "✅ All custom networks removed."
			else
				ECHO_CYAN "No custom networks found."
			fi
			;;
		4)
			ECHO_YELLOW "Removing all Docker images..."
			if docker images -q | grep -q .; then
				docker images -q | xargs docker rmi -f >/dev/null 2>&1 || true
				ECHO_GREEN "✅ All images removed."
			else
				ECHO_CYAN "No images found."
			fi
			;;
		5)
			ECHO_YELLOW "Pruning all unused Docker resources..."
			docker system prune -a --volumes --force >/dev/null 2>&1
			ECHO_GREEN "✅ All unused resources pruned."
			;;
		*)
			ECHO_RED "Invalid option. Try again."
			;;
		esac
	done
}

env_mac_developer_cleanup() {
	echo "=== Mac developer cleanup ==="

	# macOS application caches
	rm -rf ~/Library/Caches/Google
	rm -rf ~/Library/Caches/Firefox
	rm -rf ~/Library/Caches/vscode-cpptools

	# Homebrew downloads/cache
	brew cleanup

	# npm cache
	npm cache verify >/dev/null 2>&1 || true
	npm cache clean --force >/dev/null 2>&1 || true

	# Yarn cache (if installed)
	if command -v yarn >/dev/null 2>&1; then
		yarn cache clean >/dev/null 2>&1 || true
	fi

	# pnpm store - prune packages no longer referenced
	if command -v pnpm >/dev/null 2>&1; then
		pnpm store prune >/dev/null 2>&1 || true
	fi

	# Playwright downloaded browsers
	rm -rf ~/.cache/ms-playwright

	echo ""
	echo "=== Cleanup complete ==="
	echo ""
	echo "Largest remaining caches:"
	du -sh ~/Library/Caches/* 2>/dev/null | sort -h | tail -20
}
