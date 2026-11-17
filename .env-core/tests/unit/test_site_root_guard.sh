#!/bin/bash

unit_source "project/setup/setup_helpers.sh"

PROJECT_DIR=wordpress
DOMAIN_FULL=dev.blog.local
PROJECT_ROOT_DIR="$ENV_DIR/wordpress/dev.blog.local"
assert_true "normal site root is safe" site_root_is_safe

DOMAIN_FULL=""
PROJECT_ROOT_DIR="$ENV_DIR/wordpress/"
assert_false "empty domain is refused" site_root_is_safe

DOMAIN_FULL=dev.blog.local
PROJECT_DIR=""
PROJECT_ROOT_DIR="$ENV_DIR//dev.blog.local"
assert_false "empty type dir is refused" site_root_is_safe

PROJECT_DIR=.env-core
PROJECT_ROOT_DIR="$ENV_DIR/.env-core/dev.blog.local"
assert_false "hidden type dir is refused" site_root_is_safe

PROJECT_DIR=wordpress
DOMAIN_FULL=..
PROJECT_ROOT_DIR="$ENV_DIR/wordpress/.."
assert_false "parent domain is refused" site_root_is_safe

DOMAIN_FULL=dev.blog.local
PROJECT_ROOT_DIR="/tmp/elsewhere"
assert_false "root outside ENV_DIR is refused" site_root_is_safe

PROJECT_DIR=""
DOMAIN_FULL=""
PROJECT_ROOT_DIR=""
