#!/bin/bash
# Get site diagnostics (problems and recommendations)
# Usage: diagnostics.sh <domain>
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"
load_config

domain="${1:?Usage: diagnostics.sh <domain>}"
base=$(host_path "$domain") || exit 1
response=$(webmaster_get "${base}/diagnostics/")
echo "$response"
