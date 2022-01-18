#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

get_existing_domains () {
    ACTION=$1

    if [ -z "$DOMAIN_NAME" ];
    then
        string=$(awk '{print $5}' wp-instances.log | tail -n +2);
        OptionList=($string)

        if [ "$string" ];
        then
            while true;
            do
                EMPTY_LINE
                ECHO_INFO "$ACTION"
                ECHO_YELLOW "[0] Return to the previous menu"
                for i in "${!OptionList[@]}";
                do
                    ECHO_KEY_VALUE "[$(($i+1))]" "${OptionList[$i]}"
                done

                ((++i))
                read -rp "$(ECHO_YELLOW "Please select one of:")" choice

                [ -z "$choice" ] && choice=-1
                if (( "$choice" > 0 && "$choice" <= $i )); then
                    DOMAIN_NAME="${OptionList[$(($choice-1))]}"
                    break
                else
                    if [ "$choice" == 0 ];
                    then
                        existing_site_actions
                    else
                        ECHO_WARN_RED "Wrong option"
                    fi
                fi
            done
        else
            ECHO_ERROR "Wordpress sites don't exists"
            main_actions
        fi
    fi
}

existing_projects_list() {
    EMPTY_LINE
    awk 'NR==FNR{for(i=1;i<=NF;i++) 
        max[i] = length($i) > max[i] ? length($i) : max[i]; next} 
    { for(i=1;i<=NF;i++) printf "%-"max[i]"s  ", $i; printf "\n"}' wp-instances.log wp-instances.log
}

running_projects_list() {
    unset_variables
    unset running_container
    ACTION=$1

    string=$(docker ps -a --format "table {{.Names}}" | grep -w "wordpress" | sed -r 's/'-wordpress'/''/') || true;
    running_container=($string)

    if [ "$string" ];
    then
        while true;
        do
            EMPTY_LINE
            ECHO_INFO "$ACTION"
            ECHO_YELLOW "[0] Return to the previous menu"

            for i in "${!running_container[@]}";
            do
                ECHO_KEY_VALUE "[$(($i+1))]" "${running_container[$i]}"
            done

            ((++i))
            read -rp "$(ECHO_YELLOW "Please select one of:")" choice

            [ -z "$choice" ] && choice=-1
            if (( "$choice" > 0 && "$choice" <= $i )); then
                DOMAIN_NAME="${running_container[$(($choice-1))]}"
                break
            else
                if [ "$choice" == 0 ];
                then
                    existing_site_actions
                else
                    ECHO_WARN_RED "Wrong option"
                fi
            fi
        done
    else
        ECHO_ERROR "Wordpress sites not running"
        existing_site_actions
    fi
}

stopped_projects_list() {
    unset existing_container
    unset stopped_container
    ACTION=$1

    running_string=$(docker ps -a --format "table {{.Names}}" | grep -w "wordpress") || true;
    existing_string=$(awk '{print $5}' wp-instances.log | tail -n +2);

    for I in $existing_string
    do
        existing_container=${existing_container:+$existing_container }$I"-wordpress"
    done

    if [[ "$running_string" || "$existing_container" ]];
    then
        running_container=($running_string)
        running_container=$(printf "%s\|" "${running_container[@]}")

        stopped_container=$(echo "$existing_container" | sed "s/\($running_container\)//g")
        stopped_container=($(echo "$stopped_container" | sed -r 's/'-wordpress'/''/g' ))

        while true;
        do
            EMPTY_LINE
            ECHO_INFO "$ACTION"
            ECHO_YELLOW "[0] Return to the previous menu"

            for i in "${!stopped_container[@]}";
            do
                ECHO_KEY_VALUE "[$(($i+1))]" "${stopped_container[$i]}"
            done

            ((++i))
            read -rp "$(ECHO_YELLOW "Please select one of:")" choice

            [ -z "$choice" ] && choice=-1
            if (( "$choice" > 0 && "$choice" <= $i )); then
                DOMAIN_NAME="${stopped_container[$(($choice-1))]}"
                break
            else
                if [ "$choice" == 0 ];
                then
                    existing_site_actions
                else
                    ECHO_WARN_RED "Wrong option"
                fi
            fi
        done
    else
        ECHO_ERROR "Wordpress sites not running"
        existing_site_actions
    fi
}
