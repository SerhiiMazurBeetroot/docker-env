#!/bin/bash

unit_source "project/docker/docker_helpers.sh"

names=$(printf '%s\n' blog_db_data x-blog_db_data myblog_db_data blog_db_data_old other | docker_names_matching "blog_db_data")
assert_eq "$(printf '%s\n' blog_db_data x-blog_db_data)" "$names" "volume matches name and Compose prefix only"

ids=$(printf '%s\n' 'blog-wordpress aaa111' 'docker_blog-wordpress bbb222' 'blog-wordpress aaa111' 'blogXwordpress ccc333' 'old-blog-wordpress2 ddd444' | docker_names_matching "blog-wordpress")
assert_eq "$(printf '%s\n' aaa111 bbb222)" "$ids" "image ids are unique and dots/letters are not wildcards"

dotted=$(printf '%s\n' 'devXblogXlocal-app' 'dev.blog.local-app' | docker_names_matching "dev.blog.local-app")
assert_eq "dev.blog.local-app" "$dotted" "dots in the name match only dots"

assert_eq "" "$(printf 'blog\n' | docker_names_matching "")" "empty name matches nothing"
