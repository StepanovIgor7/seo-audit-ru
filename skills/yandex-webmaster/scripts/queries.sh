#!/bin/bash
# Get popular search queries from Yandex
# Usage: queries.sh <domain> [order_by] [limit]
# order_by: TOTAL_SHOWS (default), TOTAL_CLICKS
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"
load_config

domain="${1:?Usage: queries.sh <domain> [order_by] [limit]}"
order_by="${2:-TOTAL_SHOWS}"
limit="${3:-100}"

base=$(host_path "$domain") || exit 1
response=$(webmaster_get "${base}/search-queries/popular/?order_by=${order_by}&limit=${limit}")
echo "$response"
