#!/bin/bash
# Get site summary: SQI, indexed pages, problems
# Usage: summary.sh <domain>
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"
load_config

domain="${1:?Usage: summary.sh <domain>}"
base=$(host_path "$domain") || exit 1
response=$(webmaster_get_safe "${base}/summary/")
echo "$response"
