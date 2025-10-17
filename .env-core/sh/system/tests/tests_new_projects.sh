#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

tests_create_all_projects() {
	EMPTY_LINE
	ECHO_WARN_YELLOW "Start testing: Create all projects"

	for ((i = 0; i < ${#AVAILABLE_PROJECTS[@]}; i++)); do
		PROJECT_TYPE="${AVAILABLE_PROJECTS[i]}"

		TEST_RUNNING=1
		SETUP_TYPE=1
		DOMAIN_NAME="$PROJECT_TYPE-test"
		DOMAIN_FULL="dev.$PROJECT_TYPE-test.local"
		get_project_dir "skip_question"

		INSTANCES_STATUS="remove"
		docker_delete

		case $PROJECT_TYPE in
		"wordpress")
			docker_create_wp
			;;
		"bedrock")
			docker_create_bedrock
			;;
		"php")
			docker_create_php
			;;
		"nextjs")
			docker_create_nextjs
			;;
		"directus")
			docker_create_directus
			;;
		"elasticsearch")
			docker_create_elastic
			;;
		esac

		TEST_RUNNING=0
		unset_variables "PROJECT_TYPE"
	done

	ECHO_SUCCESS "Testing: Create all projects"
}

tests_delete_all_projects() {
	EMPTY_LINE
	ECHO_WARN_YELLOW "Start testing: Delete all projects"

	for ((i = 0; i < ${#AVAILABLE_PROJECTS[@]}; i++)); do
		PROJECT_TYPE="${AVAILABLE_PROJECTS[i]}"

		TEST_RUNNING=1
		SETUP_TYPE=1
		DOMAIN_NAME="$PROJECT_TYPE-test"
		DOMAIN_FULL="dev.$PROJECT_TYPE-test.local"
		get_project_dir "skip_question"

		INSTANCES_STATUS="remove"
		docker_delete

		TEST_RUNNING=0
		unset_variables "PROJECT_TYPE"
	done

	ECHO_SUCCESS "Testing: Delete all projects"
}
