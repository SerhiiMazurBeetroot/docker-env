#!/bin/bash

unit_source "core/available_projects.sh"
unit_source "project/instances/instances.sh"
unit_source "project/instances/get_archived_projects.sh"

assert_eq "0" "$(project_index wordpress)" "wordpress index"
assert_eq "wp-docker" "$(project_field compose wordpress)" "wordpress compose dir"
assert_eq "wordpress" "$(project_field id projects)" "projects alias maps to wordpress"
assert_eq "1" "$(project_field nginx directus)" "directus requires nginx"

assert_false "unknown type" project_index "not_a_real_type"

printf '%s\n' '{"sites":[{"port":1,"status":"archive","domain_name":"blog","domain_full":"dev.blog.local","db_name":"db","db_type":"MYSQL","project_type":"wordpress","port_front":0}]}' >"$FILE_INSTANCES"
assert_true "archive row detected" instances_has_archived_sites

printf '%s\n' '{"sites":[{"port":1,"status":"active","domain_name":"blog","domain_full":"dev.blog.local","db_name":"db","db_type":"MYSQL","project_type":"wordpress","port_front":0}]}' >"$FILE_INSTANCES"
assert_false "active only" instances_has_archived_sites

zip="/tmp/archive_wordpress_dev.wordpress.local_03-10-26.zip"
assert_true "parse wordpress archive" project_archive_parse_zip "$zip"
assert_eq "wordpress" "$PROJECT_TYPE" "archive type"
assert_eq "dev.wordpress.local" "$DOMAIN_FULL" "archive domain_full"

assert_false "bogus archive name" project_archive_parse_zip "/tmp/not-an-archive.zip"
