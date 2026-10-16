#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

# https://patorjk.com/software/taag/#p=display&v=0&f=miniwi&t=docker-env
export ENV_LOGO=docker_env_logo_31

docker_env_logo() {
	ECHO_LOGO '
 ▌    ▌             
▛▌▛▌▛▘▙▘█▌▛▘▄▖█▌▛▌▌▌
▙▌▙▌▙▖▛▖▙▖▌   ▙▖▌▌▚▘'
}

docker_env_logo_2() {
	ECHO_LOGO '
___  ____ ____ _  _ ____ ____    ____ _  _ _  _ 
|  \ |  | |    |_/  |___ |__/ __ |___ |\ | |  | 
|__/ |__| |___ | \_ |___ |  \    |___ | \|  \/  
'
}

docker_env_logo_3() {
	ECHO_LOGO '
 +-+-+-+-+-+-+-+-+-+-+
 |d|o|c|k|e|r|-|e|n|v|
 +-+-+-+-+-+-+-+-+-+-+
'
}

docker_env_logo_4() {
	echo '
 __   __   __        ___  __      ___           
|  \ /  \ /  ` |__/ |__  |__) __ |__  |\ | \  / 
|__/ \__/ \__, |  \ |___ |  \    |___ | \|  \/  
'
}

docker_env_logo_5() {
	ECHO_LOGO '
 ⢀⣸ ⢀⡀ ⢀⣀ ⡇⡠ ⢀⡀ ⡀⣀    ⢀⡀ ⣀⡀ ⡀⢀
 ⠣⠼ ⠣⠜ ⠣⠤ ⠏⠢ ⠣⠭ ⠏  ⠉⠉ ⠣⠭ ⠇⠸ ⠱⠃'
}

docker_env_logo_6() {
	ECHO_LOGO '
                    *
    ||
    ||____________
    ||          ||
   /||    ______||______
  //||    | docker-env |
 // ||    |____________|

        ________________
      ~~| [] | [] | [] |~~
      ~~|______________|~~
        ~   ~    ~   ~'
}

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

_logo_8_still() {
	ECHO_LOGO '
        ||
        ||
  .==============.
  |  docker-env  |
  `==============`
        ||
    ____||____
| (o)  (o)  (o) |
|_______________|

  ~    ~    ~'
}

# Bulbs chase, then the sign stays lit.
_logo_8_play() {
	local i bulbs glow bar wave frame

	printf '\033[?25l'
	echo
	for ((i = 0; i <= 4; i++)); do
		if ((i > 0)); then
			printf '\033[11A'
		fi

		case $i in
		0)
			bulbs='| (o)  ( )  ( ) |'
			glow='='
			wave='  ~    ~    ~'
			;;
		1)
			bulbs='| ( )  (o)  ( ) |'
			glow='-'
			wave=' ~    ~    ~ '
			;;
		2)
			bulbs='| ( )  ( )  (o) |'
			glow='='
			wave='  ~    ~    ~'
			;;
		3)
			bulbs='| (o)  (o)  ( ) |'
			glow='-'
			wave='    ~    ~   ~'
			;;
		*)
			bulbs='| (o)  (o)  (o) |'
			glow='='
			wave='  ~    ~    ~'
			;;
		esac

		bar=$(printf '%14s' '' | tr ' ' "$glow")
		frame=$(
			printf '%-18s\n' \
				'        ||' \
				'        ||' \
				"  .${bar}." \
				'  |  docker-env  |' \
				"  \`${bar}\`" \
				'        ||' \
				'    ____||____' \
				"$bulbs" \
				'|_______________|' \
				'' \
				"$wave"
		)
		echo -e "${BLUE}${frame}${NC}"
		sleep 0.1
	done
	printf '\033[?25h'
}

docker_env_logo_8() {
	if [[ ! -t 1 || ${CLI_NONINTERACTIVE:-0} -eq 1 || ${TEST_RUNNING:-0} -eq 1 ]]; then
		_logo_8_still
		return
	fi

	_logo_8_play
}

_logo_10_still() {
	ECHO_LOGO '
        ______         ______
       | blog |~~~~~~~| api  |
       |______|       |______|
          ~  \       /  ~
              \ ___ /
           ~~~| nginx |~~~
              |_______|
                 ~
             docker-env'
}

# One ripple crosses the channel, then the still picture remains.
_logo_10_play() {
	local i wave side sparkle frame

	printf '\033[?25l'
	echo
	for ((i = 0; i <= 7; i++)); do
		if ((i > 0)); then
			printf '\033[9A'
		fi

		wave='~~~~~~~'
		if ((i < 7)); then
			wave="${wave:0:i}o${wave:i+1}"
		fi

		case $((i % 3)) in
		0)
			side='          ~  \       /  ~'
			sparkle='                 ~'
			;;
		1)
			side='         ~   \       /   ~'
			sparkle='                ~ '
			;;
		*)
			side='          ~  \       /  ~'
			sparkle='                  ~'
			;;
		esac

		frame=$(
			printf '%-30s\n' \
				'        ______         ______' \
				"       | blog |${wave}| api  |" \
				'       |______|       |______|' \
				"$side" \
				'              \ ___ /' \
				'           ~~~| nginx |~~~' \
				'              |_______|' \
				"$sparkle" \
				'             docker-env'
		)
		echo -e "${BLUE}${frame}${NC}"
		sleep 0.08
	done
	printf '\033[?25h'
}

docker_env_logo_10() {
	if [[ ! -t 1 || ${CLI_NONINTERACTIVE:-0} -eq 1 || ${TEST_RUNNING:-0} -eq 1 ]]; then
		_logo_10_still
		return
	fi

	_logo_10_play
}

docker_env_logo_11() {
	ECHO_LOGO '
            ||
            ||
      .==============.
      |  docker-env  |
      `==============`
            ||
        ____||____
    | (o)  (o)  (o) |
    |_______________|

      ~    ~    ~'
}

# A product window: title bar with the version, a prompt, and the stack
# status. 10 lines; the terminal boots the services one by one.
_logo_17_frame() {
	local status="$1"
	local width=36
	local bar title
	local version="v${CORE_VERSION:-}"

	bar=$(printf '%*s' "$width" '' | tr ' ' '─')
	title=$(printf '%s%*s' 'docker-env' $((width - 10)) "$version")

	printf '%s\n' \
		"  ╭─${bar}─╮" \
		"$(printf '  │ %-*s │' "$width" "$title")" \
		"  ├─${bar}─┤" \
		"$(printf '  │ %-*s │' "$width" '')" \
		"$(printf '  │ %-*s │' "$width" '  > up')" \
		"$(printf '  │ %-*s │' "$width" '')" \
		"$(printf '  │ %-*s │' "$width" "$status")" \
		"$(printf '  │ %-*s │' "$width" '')" \
		"  ╰─${bar}─╯" \
		'      local docker, one command'
}

_logo_17_still() {
	local frame
	frame=$(_logo_17_frame '  [ok] nginx    [ok] db    [ok] app')
	echo -e "${BLUE}\n${frame}${NC}"
}

_logo_17_play() {
	local i frame status

	printf '\033[?25l'
	echo
	for ((i = 0; i <= 3; i++)); do
		if ((i > 0)); then
			printf '\033[10A'
		fi
		case $i in
		0) status='  [..] nginx    [..] db    [..] app' ;;
		1) status='  [ok] nginx    [..] db    [..] app' ;;
		2) status='  [ok] nginx    [ok] db    [..] app' ;;
		*) status='  [ok] nginx    [ok] db    [ok] app' ;;
		esac
		frame=$(_logo_17_frame "$status")
		echo -e "${BLUE}${frame}${NC}"
		sleep 0.18
	done
	printf '\033[?25h'
}

docker_env_logo_17() {
	if [[ ! -t 1 || ${CLI_NONINTERACTIVE:-0} -eq 1 || ${TEST_RUNNING:-0} -eq 1 ]]; then
		_logo_17_still
		return
	fi

	_logo_17_play
}

docker_env_logo_18() {
	ECHO_LOGO '
  ┌──┬──╮    ┌──┬──┬──┐
  ├──┼──┤    ├──┴──┴──┘
  ├──┼──┤    ├──┬──┐
  ├──┼──┤    ├──┴──┘
  ├──┼──┤    ├──┬──┬──┐
  └──┴──╯    └──┴──┴──┘

       docker-env'
}

docker_env_logo_21() {
	ECHO_LOGO '
   ╭──   ┌──┬──┐   ──╮
   │     ├──┼──┤     │
  ─┤     ├──┼──┤     ├─
   │     ├──┼──┤     │
   ╰──   └──┴──┘   ──╯

      docker-env'
}

docker_env_logo_22() {
	ECHO_LOGO '
                 ╭──[ web ]
    { .env }─────┼──[ app ]
                 ╰──[ db  ]

        docker-env'
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
