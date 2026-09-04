#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

# https://patorjk.com/software/taag/#p=display&v=0&f=miniwi&t=docker-env
export ENV_LOGO=docker_env_logo_2

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
