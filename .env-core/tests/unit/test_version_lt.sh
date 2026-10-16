#!/bin/bash

unit_source "core/migration/core_migration.sh"

assert_version_lt "2.0.8" "3.0.0" "patch migration threshold"
assert_version_lt "1.0.0" "2.0.0" "major bump"
assert_not_version_lt "3.0.0" "3.0.0" "equal versions"
assert_not_version_lt "3.1.0" "3.0.0" "greater left"
assert_version_lt "2.0.3" "2.0.4" "minor bump"
