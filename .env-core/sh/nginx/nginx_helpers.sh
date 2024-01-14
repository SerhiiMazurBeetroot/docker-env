#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

clear_nginx_logs() {
  max_size=1000 # 1mb

  for filename in "$DIR_NGINX/logs"/*; do
    # Check the size of each file
    file_size=$(du -k "$filename" | cut -f1)

    if [ "$file_size" -gt "$max_size" ]; then
      echo -n >"$filename"
      ECHO_TEXT "File $filename cleared."
    fi
  done
}
