#!/bin/bash
# Get external links and broken internal links
# Usage: links.sh <domain>
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"
load_config

domain="${1:?Usage: links.sh <domain>}"
base=$(host_path "$domain") || exit 1

echo "=== EXTERNAL LINKS (samples) ==="
webmaster_get "${base}/links/external/samples/?limit=50&offset=0"

echo ""
echo "=== BROKEN INTERNAL LINKS (samples) ==="
webmaster_get "${base}/links/internal/broken/samples/?limit=50&offset=0"
