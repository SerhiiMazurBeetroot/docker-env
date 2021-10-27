#!/bin/bash

if [[ -f ./env-core/settings.log ]];
then
    theme=$(awk '/''/{print $1}' ./env-core/settings.log | tail -n 1);
fi

BLACK='\033[0;30m'
WHITE='\033[0;37m'
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[0;93m'
ORANGE='\033[0;33m'
PURPLE='\033[0;35m'
LIGHTGRAY='\033[0;37m'
DARKGRAY='\033[1;30m'
LIGHTRED='\033[1;31m'
LIGHTGREEN='\033[1;32m'
LIGHTBLUE='\033[1;34m'
LIGHTPURPLE='\033[1;35m'
LIGHTCYAN='\033[1;36m'
NC='\033[0m'

if [ "$theme" = 'light' ];
then
    BLACK="$BLACK"
    WHITE="$BLACK"
    RED="$RED"
    GREEN="$GREEN"
    BLUE="$BLUE"
    CYAN="$CYAN"
    YELLOW="$BLACK"
    ORANGE="$BLACK"
    PURPLE="$BLACK"
    LIGHTGRAY="$BLACK"
    DARKGRAY="$BLACK"
    LIGHTRED="$BLACK"
    LIGHTGREEN="$BLACK"
    LIGHTBLUE=BLUE
    LIGHTPURPLE="$BLACK"
    LIGHTCYAN="$BLACK"
fi
