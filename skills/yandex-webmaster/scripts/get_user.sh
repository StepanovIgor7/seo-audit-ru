#!/bin/bash
# Get current user ID from Yandex Webmaster API
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"
load_config

response=$(webmaster_get "/user/")
echo "$response"
