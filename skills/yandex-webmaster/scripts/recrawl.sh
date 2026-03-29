#!/bin/bash
# Submit URL for recrawl or check quota
# Usage: recrawl.sh <domain> [url_to_recrawl]
# Without url_to_recrawl — shows quota only
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"
load_config

domain="${1:?Usage: recrawl.sh <domain> [url_to_recrawl]}"
url="$2"
base=$(host_path "$domain") || exit 1

echo "=== RECRAWL QUOTA ==="
webmaster_get "${base}/recrawl/quota/"

if [[ -n "$url" ]]; then
    echo ""
    echo "=== SUBMITTING URL FOR RECRAWL ==="
    webmaster_post "${base}/recrawl/queue/" "{\"url\":\"${url}\"}"
fi
