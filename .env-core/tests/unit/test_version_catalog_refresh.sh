#!/bin/bash

unit_source "project/setup/versions/catalog.sh"
unit_source "project/setup/versions/catalog_refresh.sh"

picked=$(printf '%s\n' 1.0.0 1.2.0 1.2.1 2.0.1-beta 2.0.0 3.1.0 | version_catalog_pick_majors 2)
assert_eq "$(printf '%s\n' 3.1.0 2.0.0)" "$picked" "newest two majors"

picked=$(printf '%s\n' 7.1.1 7.1.3 7.0.0 6.8.2 6.7.2 6.6.1 | version_catalog_pick_minors 4)
assert_eq "$(printf '%s\n' 7.1.3 7.0.0 6.8.2 6.7.2)" "$picked" "newest four minors"

export VERSION_CATALOG_FILE="$UNIT_TMP/catalog.json"
today=$(date -u +%F)
printf '%s\n' "{\"updated\":\"${today}\",\"php\":[\"8.4\"]}" >"$VERSION_CATALOG_FILE"
assert_false "same day is not due" version_catalog_due

printf '%s\n' '{"updated":"2000-01-01","php":["8.4"]}' >"$VERSION_CATALOG_FILE"
assert_true "old stamp is due" version_catalog_due

rm -f "$VERSION_CATALOG_FILE"
assert_true "missing file is due" version_catalog_due
unset VERSION_CATALOG_FILE
