#!/bin/bash
# Get sitemaps info
# Usage: sitemaps.sh <domain>
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"
load_config

domain="${1:?Usage: sitemaps.sh <domain>}"
base=$(host_path "$domain") || exit 1

echo "=== AUTO-DETECTED SITEMAPS ==="
webmaster_get "${base}/sitemaps/"

echo ""
echo "=== USER-ADDED SITEMAPS ==="
webmaster_get "${base}/user-added-sitemaps/"
