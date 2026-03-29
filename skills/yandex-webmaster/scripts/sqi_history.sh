#!/bin/bash
# Get SQI (Site Quality Index / ИКС) history
# Usage: sqi_history.sh <domain> [date_from] [date_to]
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"
load_config

domain="${1:?Usage: sqi_history.sh <domain> [date_from] [date_to]}"
date_from="${2:-$(date -v-90d +%Y-%m-%d 2>/dev/null || date -d '90 days ago' +%Y-%m-%d)}"
date_to="${3:-$(date +%Y-%m-%d)}"

base=$(host_path "$domain") || exit 1
response=$(webmaster_get "${base}/sqi-history/?date_from=${date_from}&date_to=${date_to}")
echo "$response"
