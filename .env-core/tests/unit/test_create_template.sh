#!/bin/bash

# SC2329: the git / create-step stubs are called by the code under test.
# shellcheck disable=SC2329

unit_source "core/available_projects.sh"
unit_source "project/docker/docker_create.sh"

# --- catalog ----------------------------------------------------------------

assert_false "nodejs type is gone" project_field id nodejs
assert_eq "nodejs_api" "$(project_field id nodejs_api)" "nodejs_api stays"
assert_eq "" "$(project_field flags directus_nextjs)" "directus_nextjs clones its GitHub template"
assert_false "no catalog row sets CREATE_TEMPLATE" grep -q 'CREATE_TEMPLATE=' <<<"${PROJECT_CREATE_FLAGS[*]}"

# --- local template lookup --------------------------------------------------

saved_env_dir="$ENV_DIR"
root="$UNIT_TMP/create_template"
ENV_DIR="$root/docker-env"
sibling="$root/docker-env-templates/docker-env-template-demo"
bundled="$ENV_DIR/.env-core/templates/demo"
mkdir -p "$sibling/.git" "$bundled"
printf 'x\n' >"$sibling/.git/HEAD"

assert_false "empty folders are not a template" docker_create_local_template_dir demo
printf 'services: {}\n' >"$bundled/docker-compose.yml"
assert_eq "$bundled" "$(docker_create_local_template_dir demo)" "bundled copy when the sibling has only .git"
printf 'services: {}\n' >"$sibling/docker-compose.yml"
assert_eq "$(cd "$sibling" && pwd)" "$(cd "$(docker_create_local_template_dir demo)" && pwd)" "sibling checkout wins"

CREATE_TEMPLATE_SOURCE=local
assert_true "local check passes with a template" docker_create_template_check demo
assert_false "local check fails without one" docker_create_template_check missing
unset CREATE_TEMPLATE_SOURCE

# --- GitHub check (git stubbed, no network) ---------------------------------

TEMPLATES_REPO="https://github.com/example/docker-env-template"
assert_eq "https://github.com/example/docker-env-template-demo.git" "$(docker_create_template_url demo)" "template URL"

git() {
	[[ "$1" == "ls-remote" ]] || return 1
	[[ "$*" == *"docker-env-template-demo.git"* ]]
}
assert_true "reachable repo passes" docker_create_template_check demo
assert_false "missing repo fails before any question" docker_create_template_check nodejs
unset -f git

# --- a failed template step rolls the site back ------------------------------

rolled_back=0
get_all_ports() { PORT=3000; }
get_project_dir() { :; }
print_to_file_instances() { :; }
docker_create_rollback() { rolled_back=1; }
docker_create_clone_template() { return 128; }

PROJECT_TYPE="demo"
DOMAIN_FULL="demo.local"
PROJECT_ROOT_DIR="$root/site"
assert_false "create stops when the clone fails" docker_create_project
assert_eq "1" "$rolled_back" "failed clone removes the half-made site"

rolled_back=0
CREATE_TEMPLATE_SOURCE=local
PROJECT_TYPE="missing"
assert_false "create stops when the local copy fails" docker_create_project
assert_eq "1" "$rolled_back" "failed local copy removes the half-made site"
unset CREATE_TEMPLATE_SOURCE

unset -f get_all_ports get_project_dir print_to_file_instances docker_create_rollback docker_create_clone_template
unset TEMPLATES_REPO PROJECT_TYPE DOMAIN_FULL PROJECT_ROOT_DIR
ENV_DIR="$saved_env_dir"
