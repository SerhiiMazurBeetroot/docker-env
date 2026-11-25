#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

# https://patorjk.com/software/taag/#p=display&v=0&f=miniwi&t=docker-env
export ENV_LOGO=docker_env_logo_31

_logo_7_still() {
	ECHO_LOGO '
host                         site
 |                            |
 |============================|
 |   [ blog ]  [ api ]  [db]  |
 |============================|
~~~~  ~    ~     ~    ~  ~~~~
         docker-env'
}

# A container crosses the bridge, then the still picture remains.
_logo_7_play() {
	local i pos lane wave frame

	printf '\033[?25l'
	echo
	for ((i = 0; i <= 7; i++)); do
		if ((i > 0)); then
			printf '\033[7A'
		fi

		if ((i < 7)); then
			pos=$((i * 4))
			lane=$(printf '%*s' "$pos" '')
			lane=$(printf '%-28s' "${lane}[]")
			lane=" |${lane}|"
		else
			lane=' |   [ blog ]  [ api ]  [db]  |'
		fi

		if ((i % 2 == 0 || i == 7)); then
			wave='~~~~  ~    ~     ~    ~  ~~~~'
		else
			wave='~  ~~~~    ~   ~    ~  ~~~~  ~'
		fi

		frame=$(
			printf '%-33s\n' \
				'host                         site' \
				' |                            |' \
				' |============================|' \
				"$lane" \
				' |============================|' \
				"$wave" \
				'         docker-env'
		)
		echo -e "${BLUE}${frame}${NC}"
		sleep 0.08
	done
	printf '\033[?25h'
}

docker_env_logo_7() {
	if [[ ! -t 1 || ${CLI_NONINTERACTIVE:-0} -eq 1 || ${TEST_RUNNING:-0} -eq 1 ]]; then
		_logo_7_still
		return
	fi

	_logo_7_play
}

_logo_31_still() {
	printf '\n    %bdocker%b.env%b\n' \
		"${LIGHTBLUE:-${BLUE:-}}" \
		"${LIGHTCYAN:-${CYAN:-}}" \
		"${NC:-}"
}

_logo_31_play() {
	local i
	local docker_text='docker'
	local env_text='.env'
	local docker_part=''
	local env_part=''
	local docker_color="${LIGHTBLUE:-${BLUE:-}}"
	local env_color="${LIGHTCYAN:-${CYAN:-}}"

	printf '\n\033[?25l'
	for ((i = 1; i <= 10; i++)); do
		if ((i <= 6)); then
			docker_part="${docker_text:0:i}"
			env_part=''
		else
			docker_part="$docker_text"
			env_part="${env_text:0:i-6}"
		fi

		printf '\r\033[2K    %b%s%b%s%b_' \
			"$docker_color" "$docker_part" \
			"$env_color" "$env_part" \
			"${NC:-}"
		sleep 0.07
	done

	printf '\r\033[2K    %bdocker%b.env%b\n\033[?25h' \
		"$docker_color" "$env_color" \
		"${NC:-}"
}

# Menus call env_logo_draw each redraw — keep $ENV_LOGO static.
docker_env_logo_31() {
	_logo_31_still
}

# Set after env_logo_startup so the first menu pass does not print the logo twice.
export ENV_LOGO_SKIP_NEXT=0

env_logo_draw() {
	if [[ ${ENV_LOGO_SKIP_NEXT:-0} -eq 1 ]]; then
		ENV_LOGO_SKIP_NEXT=0
		return 0
	fi

	"${ENV_LOGO:-docker_env_logo_31}"
}

# Once per interactive session startup (see setup.sh main_actions).
env_logo_startup() {
	if [[ ! -t 1 || ${CLI_NONINTERACTIVE:-0} -eq 1 || ${TEST_RUNNING:-0} -eq 1 ]]; then
		return 0
	fi

	case "${ENV_LOGO:-}" in
	docker_env_logo_31)
		_logo_31_play
		;;
	docker_env_logo_7)
		_logo_7_play
		;;
	*)
		"${ENV_LOGO:-docker_env_logo_31}"
		;;
	esac

	ENV_LOGO_SKIP_NEXT=1
}
