#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

# Bash 3.2 compatible (macOS /bin/bash): no mapfile, no associative arrays.

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
		ECHO_GREEN "[6] Ports"

		actions=$(GET_USER_INPUT "select_one_of")

		case $actions in
		0)
			return 0
			;;
		1)
			env_helpers_docker_menu
			;;
		2)
			if [[ $OSTYPE != "windows" ]]; then
				env_helpers_permissions_menu
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
			env_mac_cleanup_menu
			;;
		6)
			port_menu
			;;
		*)
			ECHO_RED "Invalid option. Try again."
			;;
		esac
	done
}

# ---------------------------------------------------------------------------
# Shared helpers
# ---------------------------------------------------------------------------

# Ask a y/n question, default "no". Returns 0 on yes.
helpers_confirm() {
	local answer
	answer=$(GET_USER_INPUT "question" "$1" "n")
	[[ "$answer" =~ ^[Yy]$ ]]
}

# Size of a path in KB (0 when missing).
helpers_size_kb() {
	local kb
	if [[ ! -e "$1" ]]; then
		echo 0
		return 0
	fi
	kb=$(du -sk "$1" 2>/dev/null | awk '{print $1}' || true)
	echo "${kb:-0}"
}

# KB -> human readable (e.g. 1.4G).
helpers_human_kb() {
	awk -v kb="${1:-0}" 'BEGIN {
		split("K M G T", u, " "); i = 1; s = kb
		while (s >= 1024 && i < 4) { s /= 1024; i++ }
		if (i == 1) printf "%d%s", s, u[i]; else printf "%.1f%s", s, u[i]
	}'
}

helpers_free_space() {
	df -h "${1:-$HOME}" 2>/dev/null | awk 'NR==2 {print $4 " free of " $2}' || true
}

# Prompt for a directory, falling back to a default. Echoes the path.
helpers_ask_dir() {
	local default_dir="$1" dir
	dir=$(GET_USER_INPUT "enter" "Directory [default '${default_dir}']: " "")
	dir="${dir:-$default_dir}"
	dir="${dir/#\~/$HOME}"
	echo "$dir"
}

# ---------------------------------------------------------------------------
# Disk usage
# ---------------------------------------------------------------------------

env_helpers_disk_menu() {
	local dir size
	while true; do
		EMPTY_LINE
		ECHO_CYAN "==== Disk Usage menu ==="
		ECHO_YELLOW "[0] Return to the previous menu"
		ECHO_GREEN "[1] Find large files"
		ECHO_GREEN "[2] Show top largest folders"
		ECHO_GREEN "[3] Disk overview (home, caches, Docker, apps)"
		ECHO_GREEN "[4] Find build artifacts (node_modules, .pio, build, ...)"

		actions=$(GET_USER_INPUT "select_one_of")

		case $actions in
		0)
			return 0
			;;
		1)
			dir=$(helpers_ask_dir ".")
			size=$(GET_USER_INPUT "enter" "Min size [default '300M']: " "")
			size="${size:-300M}"
			ECHO_YELLOW "Searching files larger than ${size} in ${dir} ..."
			# -xdev: stay on one filesystem; permission errors are ignored.
			find "$dir" -xdev -type f -size +"${size}" -print0 2>/dev/null |
				xargs -0 du -h 2>/dev/null | sort -hr | head -n 30 || true
			;;
		2)
			dir=$(helpers_ask_dir ".")
			du -h -d 1 "$dir" 2>/dev/null | sort -hr | head -n 15 || true
			;;
		3)
			env_helpers_disk_overview
			;;
		4)
			env_helpers_build_artifacts
			;;
		*)
			ECHO_RED "Invalid option. Try again."
			;;
		esac
	done
}

env_helpers_disk_overview() {
	local path kb
	EMPTY_LINE
	ECHO_CYAN "Disk: $(helpers_free_space /)"
	ECHO_YELLOW "Measuring (may take a minute)..."
	for path in \
		"$HOME/Documents" \
		"$HOME/Downloads" \
		"$HOME/Desktop" \
		"$HOME/projects" \
		"$HOME/Applications" \
		"/Applications" \
		"$HOME/Library/Caches" \
		"$HOME/Library/Application Support" \
		"$HOME/Library/Developer" \
		"$HOME/Library/Group Containers/HUAQ24HBR6.dev.orbstack" \
		"$HOME/Library/Containers/com.docker.docker" \
		"$HOME/.Trash" \
		"$HOME/.npm" \
		"$HOME/.cache" \
		"$HOME/.platformio" \
		"$HOME/.espressif"; do
		[[ -e "$path" ]] || continue
		kb=$(helpers_size_kb "$path")
		printf '%8s  %s\n' "$(helpers_human_kb "$kb")" "${path/#$HOME/~}"
	done | sort -hr
	if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
		EMPTY_LINE
		ECHO_CYAN "Docker:"
		docker system df 2>/dev/null || true
	fi
}

# Find regenerable build output under a directory. Prints NUL-separated paths.
# A folder only counts when its parent has the matching project marker, so a
# random "build" folder with real content is never picked up.
helpers_find_artifacts() {
	local root="$1" path parent name
	find "$root" -xdev -type d \( \
		-name node_modules -o -name .pio -o -name build -o -name Debug \
		-o -name Release -o -name .next -o -name .nuxt -o -name target \
		-o -name .gradle -o -name __pycache__ \
		\) -prune -print0 2>/dev/null | while IFS= read -r -d '' path; do
		parent=$(dirname "$path")
		name=$(basename "$path")
		case "$name" in
		node_modules | .next | .nuxt) [[ -f "$parent/package.json" ]] || continue ;;
		.pio) [[ -f "$parent/platformio.ini" ]] || continue ;;
		build) [[ -f "$parent/CMakeLists.txt" || -f "$parent/sdkconfig" || -f "$parent/Makefile" || -f "$parent/build.gradle" ]] || continue ;;
		Debug | Release) [[ -f "$parent/.cproject" ]] || continue ;;
		target) [[ -f "$parent/Cargo.toml" || -f "$parent/pom.xml" ]] || continue ;;
		.gradle) [[ -f "$parent/build.gradle" || -f "$parent/settings.gradle" ]] || continue ;;
		esac
		printf '%s\0' "$path"
	done || true
}

env_helpers_build_artifacts() {
	local root days list_file all_file path kb total=0 count=0 recent=""
	root=$(helpers_ask_dir "$HOME/Documents")
	if [[ ! -d "$root" ]]; then
		ECHO_RED "Not a directory: $root"
		return 0
	fi
	days=$(GET_USER_INPUT "enter" "Only projects untouched for N days [default '0' = all]: " "")
	days="${days:-0}"
	[[ "$days" =~ ^[0-9]+$ ]] || days=0

	ECHO_YELLOW "Scanning ${root} ..."
	list_file=$(mktemp)
	all_file=$(mktemp)
	helpers_find_artifacts "$root" >"$all_file"

	while IFS= read -r -d '' path; do
		if ((days > 0)); then
			# Skip when the project has sources changed within N days.
			recent=$(find "$(dirname "$path")" -maxdepth 2 -not -path "$path" -not -path "$path/*" -type f -mtime -"$days" -print -quit 2>/dev/null || true)
			[[ -n "$recent" ]] && continue
		fi
		kb=$(helpers_size_kb "$path")
		((kb > 1024)) || continue # ignore < 1 MB
		total=$((total + kb))
		count=$((count + 1))
		printf '%s\t%s\0' "$kb" "$path" >>"$list_file"
	done <"$all_file"
	rm -f "$all_file"

	if ((count == 0)); then
		ECHO_CYAN "No build artifacts found."
		rm -f "$list_file"
		return 0
	fi

	tr '\0' '\n' <"$list_file" | sort -nr | while IFS=$'\t' read -r kb path; do
		printf '%8s  %s\n' "$(helpers_human_kb "$kb")" "${path/#$HOME/~}"
	done

	EMPTY_LINE
	ECHO_CYAN "Found ${count} folders, $(helpers_human_kb "$total") total. They are regenerated on the next build/install."
	if helpers_confirm "Delete all listed folders?"; then
		while IFS=$'\t' read -r -d '' kb path; do
			rm -rf "$path"
		done <"$list_file"
		ECHO_SUCCESS "Freed ~$(helpers_human_kb "$total"). Disk: $(helpers_free_space /)"
	fi
	rm -f "$list_file"
}

# ---------------------------------------------------------------------------
# Git
# ---------------------------------------------------------------------------

env_helpers_git_menu() {
	local git_dir before after
	while true; do
		EMPTY_LINE
		ECHO_CYAN "==== GIT menu ==="
		ECHO_YELLOW "[0] Return to the previous menu"
		ECHO_GREEN "[1] git config core.fileMode false"
		ECHO_GREEN "[2] git_user_info"
		ECHO_GREEN "[3] empty commit"
		ECHO_GREEN "[4] git gc (compact this repository)"

		actions=$(GET_USER_INPUT "select_one_of")

		case $actions in
		0)
			return 0
			;;
		1)
			git config core.fileMode false
			EMPTY_LINE
			ECHO_SUCCESS "Git config updated"
			;;
		2)
			git_user_info
			echo
			;;
		3)
			if helpers_confirm "Create an empty 'Trigger deploy' commit on $(git branch --show-current 2>/dev/null || true)?"; then
				git commit --allow-empty -m "Trigger deploy" || true
			fi
			;;
		4)
			git_dir=$(git rev-parse --git-dir 2>/dev/null || true)
			if [[ -z "$git_dir" ]]; then
				ECHO_RED "Not a git repository: $(pwd)"
				continue
			fi
			before=$(helpers_size_kb "$git_dir")
			git gc --prune=now || true
			after=$(helpers_size_kb "$git_dir")
			ECHO_SUCCESS ".git: $(helpers_human_kb "$before") -> $(helpers_human_kb "$after")"
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
	current_user="$(git config user.initials | sed 's% %+%' || true)"
	# if `user.initials` weren't set, attempt to extract initials from `user.name`
	[[ -z "${current_user}" ]] && current_user=$(printf "%s" "$(for word in $(git config user.name | PERLIO=:utf8 perl -pe '$_=lc'); do printf "%s" "${word:0:1}"; done)")
	[[ -n "${current_user}" ]] && printf "%s" "${SCM_THEME_CURRENT_USER_PREFFIX-}${current_user}${SCM_THEME_CURRENT_USER_SUFFIX-}"
	return 0
}

# ---------------------------------------------------------------------------
# Permissions
# ---------------------------------------------------------------------------

env_helpers_permissions_menu() {
	while true; do
		EMPTY_LINE
		ECHO_CYAN "==== Permissions menu ==="
		ECHO_YELLOW "[0] Return to the previous menu"
		ECHO_GREEN "[1] Set current dir to 755"
		ECHO_GREEN "[2] Set current dir to 775"
		ECHO_GREEN "[3] Set all files to 644 recursively"
		ECHO_GREEN "[4] Set all dirs to 755 recursively"
		ECHO_GREEN "[5] chmod ug+rwX recursively (current dir)"

		actions=$(GET_USER_INPUT "select_one_of")

		case $actions in
		0)
			return 0
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
			helpers_confirm "Set every file under $(pwd) to 644?" || continue
			find . -type f -exec chmod 644 {} +
			ECHO_SUCCESS "All files set to 644 recursively"
			;;
		4)
			helpers_confirm "Set every directory under $(pwd) to 755?" || continue
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

# ---------------------------------------------------------------------------
# Docker
# ---------------------------------------------------------------------------

helpers_docker_ready() {
	if ! command -v docker >/dev/null 2>&1 || ! docker info >/dev/null 2>&1; then
		ECHO_RED "Docker is not running."
		return 1
	fi
}

helpers_docker_safe_prune() {
	docker system prune --force | tail -n 1 || true
	docker builder prune --force | tail -n 1 || true
}

helpers_count_lines() {
	echo "$1" | grep -c . || true
}

env_helpers_docker_menu() {
	local ids
	while true; do
		EMPTY_LINE
		ECHO_CYAN "==== Docker menu ==="
		ECHO_YELLOW "[0] Return to the previous menu"
		ECHO_GREEN "[1] Stop and Remove All Containers"
		ECHO_GREEN "[2] Remove All Volumes (deletes site databases!)"
		ECHO_GREEN "[3] Remove All Networks"
		ECHO_GREEN "[4] Remove All Images"
		ECHO_GREEN "[5] Prune All Unused Resources (incl. unused volumes)"
		ECHO_GREEN "[6] Show Docker disk usage"
		ECHO_GREEN "[7] Safe prune (stopped containers, dangling images, build cache; keeps volumes)"
		ECHO_GREEN "[8] Remove all build cache"

		actions=$(GET_USER_INPUT "select_one_of")
		case $actions in
		0) return 0 ;;
		[1-8]) helpers_docker_ready || continue ;;
		*)
			ECHO_RED "Invalid option. Try again."
			continue
			;;
		esac

		case $actions in
		1)
			ids=$(docker ps -aq || true)
			if [[ -z "$ids" ]]; then
				ECHO_CYAN "No containers found."
				continue
			fi
			helpers_confirm "Stop and remove $(helpers_count_lines "$ids") containers?" || continue
			echo "$ids" | xargs docker rm -f >/dev/null || true
			ECHO_GREEN "✅ All containers stopped and removed."
			;;
		2)
			ids=$(docker volume ls -q || true)
			if [[ -z "$ids" ]]; then
				ECHO_CYAN "No volumes found."
				continue
			fi
			ECHO_WARN_RED "This deletes ALL volumes, including every site's database."
			helpers_confirm "Remove $(helpers_count_lines "$ids") volumes?" || continue
			# Volumes used by containers fail; say so instead of hiding errors.
			echo "$ids" | xargs docker volume rm >/dev/null || ECHO_YELLOW "Some volumes are in use and were kept."
			ECHO_GREEN "✅ Volumes removed."
			;;
		3)
			ids=$(docker network ls --format '{{.Name}}' | grep -vE '^(bridge|host|none)$' || true)
			if [[ -z "$ids" ]]; then
				ECHO_CYAN "No custom networks found."
				continue
			fi
			helpers_confirm "Remove $(helpers_count_lines "$ids") custom networks?" || continue
			echo "$ids" | xargs docker network rm >/dev/null || ECHO_YELLOW "Some networks are in use and were kept."
			ECHO_GREEN "✅ Custom networks removed."
			;;
		4)
			ids=$(docker images -q | sort -u || true)
			if [[ -z "$ids" ]]; then
				ECHO_CYAN "No images found."
				continue
			fi
			helpers_confirm "Remove $(helpers_count_lines "$ids") images?" || continue
			echo "$ids" | xargs docker rmi -f >/dev/null || true
			ECHO_GREEN "✅ All images removed."
			;;
		5)
			docker system df || true
			ECHO_WARN_RED "Unused volumes (databases of stopped/removed sites) will be deleted."
			helpers_confirm "Prune all unused images, containers, networks, volumes and build cache?" || continue
			docker system prune -a --volumes --force | tail -n 1 || true
			ECHO_GREEN "✅ All unused resources pruned."
			;;
		6)
			docker system df || true
			;;
		7)
			docker system df || true
			helpers_docker_safe_prune
			ECHO_GREEN "✅ Safe prune done. Volumes untouched."
			;;
		8)
			docker builder prune --all --force | tail -n 1 || true
			ECHO_GREEN "✅ Build cache removed."
			;;
		esac
	done
}

# ---------------------------------------------------------------------------
# Mac cleanup
# ---------------------------------------------------------------------------

# Regenerable caches: "label|path". Only folders that apps rebuild on demand.
helpers_mac_cache_targets() {
	cat <<EOF
Chrome cache|$HOME/Library/Caches/Google
Firefox cache|$HOME/Library/Caches/Firefox
Firefox cache (Mozilla)|$HOME/Library/Caches/Mozilla
VS Code C++ tools|$HOME/Library/Caches/vscode-cpptools
VS Code cache|$HOME/Library/Application Support/Code/Cache
VS Code cached data|$HOME/Library/Application Support/Code/CachedData
VS Code VSIX cache|$HOME/Library/Application Support/Code/CachedExtensionVSIXs
Cursor cache|$HOME/Library/Application Support/Cursor/Cache
Cursor cached data|$HOME/Library/Application Support/Cursor/CachedData
Slack cache|$HOME/Library/Application Support/Slack/Cache
Xcode DerivedData|$HOME/Library/Developer/Xcode/DerivedData
npm cache|$HOME/.npm/_cacache
Yarn cache|$HOME/Library/Caches/Yarn
pip cache|$HOME/Library/Caches/pip
Playwright browsers|$HOME/Library/Caches/ms-playwright
Playwright browsers (~/.cache)|$HOME/.cache/ms-playwright
PlatformIO download cache|$HOME/.platformio/.cache
ESP-IDF downloaded archives|$HOME/.espressif/dist
EOF
	if command -v brew >/dev/null 2>&1; then
		echo "Homebrew downloads|$(brew --cache 2>/dev/null || true)"
	fi
}

env_mac_cleanup_menu() {
	local kb
	while true; do
		EMPTY_LINE
		ECHO_CYAN "==== Mac cleanup menu === ($(helpers_free_space /))"
		ECHO_YELLOW "[0] Return to the previous menu"
		ECHO_GREEN "[1] Report: what can be cleaned (nothing is deleted)"
		ECHO_GREEN "[2] Clean developer caches"
		ECHO_GREEN "[3] Remove project build artifacts (node_modules, .pio, build, ...)"
		ECHO_GREEN "[4] Docker safe prune (keeps volumes)"
		ECHO_GREEN "[5] Empty Trash"
		ECHO_GREEN "[6] Delete unavailable iOS simulators"
		ECHO_GREEN "[7] Quick cleanup (report, caches, Docker safe prune)"

		actions=$(GET_USER_INPUT "select_one_of")

		case $actions in
		0)
			return 0
			;;
		1)
			env_mac_cleanup_report
			;;
		2)
			env_mac_developer_cleanup
			;;
		3)
			env_helpers_build_artifacts
			;;
		4)
			helpers_docker_ready || continue
			helpers_docker_safe_prune
			;;
		5)
			kb=$(helpers_size_kb "$HOME/.Trash")
			if ((kb == 0)); then
				ECHO_CYAN "Trash is empty."
				continue
			fi
			helpers_confirm "Permanently delete $(helpers_human_kb "$kb") in Trash? This cannot be undone." || continue
			osascript -e 'tell application "Finder" to empty trash' >/dev/null 2>&1 ||
				ECHO_YELLOW "Could not empty Trash (Finder permission?). Empty it from the Dock."
			;;
		6)
			if command -v xcrun >/dev/null 2>&1; then
				xcrun simctl delete unavailable || true
				ECHO_SUCCESS "Unavailable simulators deleted."
			else
				ECHO_CYAN "Xcode tools not installed."
			fi
			;;
		7)
			env_mac_cleanup_report
			env_mac_developer_cleanup
			if helpers_docker_ready >/dev/null 2>&1; then
				helpers_docker_safe_prune
			fi
			;;
		*)
			ECHO_RED "Invalid option. Try again."
			;;
		esac
	done
}

env_mac_cleanup_report() {
	local label path kb idf total=0
	EMPTY_LINE
	ECHO_CYAN "Cleanable caches:"
	while IFS='|' read -r label path; do
		[[ -n "$path" && -e "$path" ]] || continue
		kb=$(helpers_size_kb "$path")
		((kb > 0)) || continue
		total=$((total + kb))
		printf '%8s  %s\n' "$(helpers_human_kb "$kb")" "$label"
	done < <(helpers_mac_cache_targets)
	printf '%8s  %s\n' "$(helpers_human_kb "$total")" "TOTAL caches"

	kb=$(helpers_size_kb "$HOME/.Trash")
	if ((kb > 0)); then
		printf '%8s  %s\n' "$(helpers_human_kb "$kb")" "Trash (option 5)"
	fi

	for idf in "$HOME"/.espressif/v*; do
		[[ -d "$idf" ]] || continue
		printf '%8s  %s\n' "$(helpers_human_kb "$(helpers_size_kb "$idf")")" "ESP-IDF $(basename "$idf") (remove unused versions with EIM)"
	done

	if helpers_docker_ready >/dev/null 2>&1; then
		EMPTY_LINE
		ECHO_CYAN "Docker (see RECLAIMABLE):"
		docker system df || true
	fi
	EMPTY_LINE
	ECHO_INFO "Build artifacts inside projects: option 3. Disk: $(helpers_free_space /)"
}

env_mac_developer_cleanup() {
	local label path kb total=0 before_kb after_kb freed

	EMPTY_LINE
	ECHO_CYAN "=== Mac developer cleanup ==="
	helpers_confirm "Delete the caches from the report? Apps rebuild them on demand." || return 0

	before_kb=$(df -k / | awk 'NR==2 {print $4}')

	while IFS='|' read -r label path; do
		[[ -n "$path" && -e "$path" ]] || continue
		case "$path" in
		"$HOME"/?*) ;;
		*) continue ;; # never delete outside $HOME
		esac
		kb=$(helpers_size_kb "$path")
		total=$((total + kb))
		rm -rf "$path" 2>/dev/null || ECHO_YELLOW "Could not fully remove: $label (app running?)"
		printf '  %-32s %s\n' "$label" "$(helpers_human_kb "$kb")"
	done < <(helpers_mac_cache_targets)

	# Tools that manage their own caches.
	if command -v brew >/dev/null 2>&1; then
		brew cleanup --prune=all >/dev/null 2>&1 || true
		ECHO_TEXT "  Homebrew: old versions removed"
	fi
	if command -v pnpm >/dev/null 2>&1; then
		pnpm store prune >/dev/null 2>&1 || true
		ECHO_TEXT "  pnpm: unreferenced packages pruned"
	fi
	if command -v composer >/dev/null 2>&1; then
		composer clear-cache >/dev/null 2>&1 || true
		ECHO_TEXT "  Composer: cache cleared"
	fi

	after_kb=$(df -k / | awk 'NR==2 {print $4}')
	freed=$total
	((after_kb > before_kb)) && freed=$((after_kb - before_kb))
	EMPTY_LINE
	ECHO_SUCCESS "Cleanup complete. Freed ~$(helpers_human_kb "$freed"). Disk: $(helpers_free_space /)"
}
