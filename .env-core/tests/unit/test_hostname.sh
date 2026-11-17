#!/bin/bash

unit_source "core/core_security.sh"
unit_source "project/setup/setup_helpers.sh"
unit_source "system/nginx/nginx_hosts_file.sh"

assert_eq "dev.blog.local" "$(sanitize_host_input 'dev.blog.local')" "sanitize keeps simple host"
assert_eq "my-site" "$(sanitize_host_input 'my_site')" "sanitize maps underscore to dash"
assert_eq "abc" "$(sanitize_host_input 'a b c')" "sanitize strips spaces"

assert_true "valid hostname" is_safe_hostname "dev.wordpress.local"
assert_true "single label" is_safe_hostname "blog"
assert_false "reject empty" is_safe_hostname ""
assert_false "reject trailing dot" is_safe_hostname "blog.local."
assert_false "reject double dot" is_safe_hostname "a..b.local"

hosts_sample="$UNIT_TMP/hosts"
printf '%s\n' '127.0.0.1 dev.dddd.local.pgadmin' >"$hosts_sample"
assert_false "pgadmin name is not the site" _hosts_has_token "$hosts_sample" "dev.dddd.local"
printf '%s\n' '127.0.0.1 dev.dddd.local dev.dddd.local.pgadmin' >"$hosts_sample"
assert_true "site token matches" _hosts_has_token "$hosts_sample" "dev.dddd.local"

# Removing a site keeps lines for names that only contain it, and keeps comments.
cat >"$hosts_sample" <<'HOSTS'
# dev.blog.local was added by docker-env
127.0.0.1 localhost
127.0.0.1 dev.blog.local dev.blog.local.phpmyadmin dev.blog.local.mail
127.0.0.1 blog.local
127.0.0.1 my.dev.blog.local
	127.0.0.1	dev.blog.local   # indented with tabs
HOSTS
without=$(_hosts_without_token "$hosts_sample" "dev.blog.local")
expected=$(printf '%s\n' '# dev.blog.local was added by docker-env' '127.0.0.1 localhost' '127.0.0.1 blog.local' '127.0.0.1 my.dev.blog.local')
assert_eq "$expected" "$without" "remove drops only lines listing the site"

without=$(_hosts_without_token "$hosts_sample" "blog.local")
if printf '%s\n' "$without" | grep -q 'dev.blog.local.phpmyadmin'; then
	assert_eq "kept" "kept" "removing blog.local keeps dev.blog.local"
else
	assert_eq "kept" "removed" "removing blog.local keeps dev.blog.local"
fi

_hosts_remove_line "$hosts_sample" "dev.blog.local" 0
assert_false "site is gone after remove" _hosts_has_token "$hosts_sample" "dev.blog.local"
assert_true "other site stays after remove" _hosts_has_token "$hosts_sample" "blog.local"
assert_false "no .bak file is left" test -e "$hosts_sample.bak"
