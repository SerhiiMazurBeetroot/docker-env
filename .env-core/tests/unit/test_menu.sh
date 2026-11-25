#!/bin/bash

# Menus build their rows from the current state (Stop only while running, dev-only rows),
# so the number a user types maps to a key through menu_pick_key, not a fixed case list.

unit_source "core/utils/colors.sh"
unit_source "core/utils/menu.sh"

keys=(restart stop rebuild reset)
assert_eq "restart" "$(menu_pick_key "1" "${keys[@]}")" "first row maps to the first key"
assert_eq "reset" "$(menu_pick_key "4" "${keys[@]}")" "last row maps to the last key"
assert_eq "stop" "$(menu_pick_key " 2 " "${keys[@]}")" "surrounding spaces are ignored"
assert_eq "" "$(menu_pick_key "0" "${keys[@]}")" "0 maps to no key (back is handled by the menu)"
assert_eq "" "$(menu_pick_key "5" "${keys[@]}")" "a number past the last row maps to no key"
assert_eq "" "$(menu_pick_key "x" "${keys[@]}")" "non-numeric input maps to no key"
assert_eq "" "$(menu_pick_key "" "${keys[@]}")" "empty input maps to no key"

row=$(menu_row 3 "Rebuild" "recreate the containers" | sed -E 's/\x1b\[[0-9;]*m//g')
assert_eq "[3] Rebuild          recreate the containers" "$row" "rows pad the label so hints line up"
