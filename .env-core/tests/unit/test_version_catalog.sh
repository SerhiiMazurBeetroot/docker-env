#!/bin/bash

unit_source "project/setup/versions/catalog.sh"

# Fixed catalog so the result does not depend on data/catalog.json, which the
# daily refresh rewrites and CI does not have.
export VERSION_CATALOG_FILE="$UNIT_TMP/catalog_fixture.json"
cat >"$VERSION_CATALOG_FILE" <<'JSON'
{
  "updated": "2026-01-01",
  "php": ["8.5", "8.4", "8.3"],
  "wordpress": ["7.1.3", "6.8.2"],
  "wordpressPhp": {
    "7.1.3": ["8.5", "8.4", "8.3"],
    "6.8.2": ["8.4", "8.3"]
  },
  "laravel": ["13.11.0"],
  "node": ["24", "22"]
}
JSON

assert_true "php 8.4 is published" version_catalog_has php "8.4"
assert_false "php 11111 is rejected" version_catalog_has php "11111"
assert_true "empty preset is allowed" version_catalog_has php ""
assert_true "wordpress 7.1.3 is published" version_catalog_has wordpress "7.1.3"
assert_false "wordpress 222222 is rejected" version_catalog_has wordpress "222222"
assert_true "7.1.3 with php 8.4 has an image" version_catalog_wordpress_php "7.1.3" "8.4"
assert_false "6.8.2 with php 8.5 has no image" version_catalog_wordpress_php "6.8.2" "8.5"
assert_true "laravel 13.11.0 is published" version_catalog_has laravel "13.11.0"
assert_true "node 22 is published" version_catalog_has node "22"
assert_false "unknown family is rejected" version_catalog_has ruby "3.3"

rm -f "$VERSION_CATALOG_FILE"
assert_false "missing catalog rejects a preset" version_catalog_has php "8.4"

unset VERSION_CATALOG_FILE
