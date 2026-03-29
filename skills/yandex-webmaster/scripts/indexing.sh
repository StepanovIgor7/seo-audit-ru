#!/bin/bash
# Get indexing status: history and page samples
# Usage: indexing.sh <domain> [date_from] [date_to]
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"
load_config

domain="${1:?Usage: indexing.sh <domain> [date_from] [date_to]}"
date_from="${2:-$(date -v-90d +%Y-%m-%d 2>/dev/null || date -d '90 days ago' +%Y-%m-%d)}"
date_to="${3:-$(date +%Y-%m-%d)}"

base=$(host_path "$domain") || exit 1

echo "=== INDEXING HISTORY ==="
webmaster_get "${base}/indexing/history/?date_from=${date_from}&date_to=${date_to}"

echo ""
echo "=== INDEXED PAGE SAMPLES ==="
webmaster_get "${base}/indexing/samples/?limit=50&offset=0"
