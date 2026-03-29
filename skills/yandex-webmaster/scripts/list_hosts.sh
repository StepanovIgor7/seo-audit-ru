#!/bin/bash
# List all sites in Yandex Webmaster account
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"
load_config

uid=$(get_user_id) || exit 1
response=$(webmaster_get "/user/${uid}/hosts/")
echo "$response"
