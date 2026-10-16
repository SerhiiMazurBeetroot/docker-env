#!/bin/bash

unit_source "project/database/database_create_dump.sh"

rotate_dir="$UNIT_TMP/backups"
mkdir -p "$rotate_dir"

printf 'old\n' >"$rotate_dir/old.sql"
printf 'mid\n' >"$rotate_dir/mid.sql"
printf 'new\n' >"$rotate_dir/new.sql"

if touch -t 202401010000 "$rotate_dir/old.sql" 2>/dev/null; then
	touch -t 202402010000 "$rotate_dir/mid.sql"
	touch -t 202403010000 "$rotate_dir/new.sql"
else
	touch -d '2024-01-01' "$rotate_dir/old.sql"
	touch -d '2024-02-01' "$rotate_dir/mid.sql"
	touch -d '2024-03-01' "$rotate_dir/new.sql"
fi

BACKUP_KEEP=2
database_backup_rotate "$rotate_dir"

assert_false "oldest removed" test -f "$rotate_dir/old.sql"
assert_true "newest kept" test -f "$rotate_dir/new.sql"
assert_true "second newest kept" test -f "$rotate_dir/mid.sql"
