#!/bin/bash
# Common functions for Yandex Webmaster API v4

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
CONFIG_FILE="$HOME/.claude/skills/yandex-wordstat/config/.env"
CACHE_DIR="$SKILL_DIR/cache"
API_BASE="https://api.webmaster.yandex.net/v4"

# Load config
load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        # shellcheck disable=SC1090
        source "$CONFIG_FILE"
    fi

    if [[ -z "$YANDEX_WEBMASTER_TOKEN" ]]; then
        echo "Error: YANDEX_WEBMASTER_TOKEN not found."
        echo "Add YANDEX_WEBMASTER_TOKEN=your_token to $CONFIG_FILE"
        exit 1
    fi
}

# GET request to Webmaster API
# Usage: webmaster_get "endpoint_path"
webmaster_get() {
    local path="$1"
    curl -s -X GET "${API_BASE}${path}" \
        -H "Authorization: OAuth $YANDEX_WEBMASTER_TOKEN" \
        -H "Content-Type: application/json"
}

# POST request to Webmaster API
# Usage: webmaster_post "endpoint_path" "json_body"
webmaster_post() {
    local path="$1"
    local body="$2"
    curl -s -X POST "${API_BASE}${path}" \
        -H "Authorization: OAuth $YANDEX_WEBMASTER_TOKEN" \
        -H "Content-Type: application/json" \
        -d "$body"
}

# DELETE request to Webmaster API
webmaster_delete() {
    local path="$1"
    curl -s -X DELETE "${API_BASE}${path}" \
        -H "Authorization: OAuth $YANDEX_WEBMASTER_TOKEN"
}

# Get user_id (cached)
get_user_id() {
    local cache_file="$CACHE_DIR/user_id"

    if [[ -f "$cache_file" ]]; then
        cat "$cache_file"
        return 0
    fi

    local response
    response=$(webmaster_get "/user/")
    local uid
    uid=$(echo "$response" | grep -o '"user_id":[0-9]*' | head -1 | sed 's/"user_id"://')

    if [[ -z "$uid" || "$uid" == "null" ]]; then
        echo "Error: Failed to get user_id. Response: $response" >&2
        return 1
    fi

    echo "$uid" > "$cache_file"
    echo "$uid"
}

# Find host_id by domain
# Usage: find_host_id "example.com"
find_host_id() {
    local domain="$1"
    local uid
    uid=$(get_user_id) || return 1

    local cache_file="$CACHE_DIR/host_${domain}"
    if [[ -f "$cache_file" ]]; then
        cat "$cache_file"
        return 0
    fi

    local response
    response=$(webmaster_get "/user/${uid}/hosts/")

    # Try exact match with different URL formats (prefer HTTPS main mirror)
    # host_id format in API: "https:domain:443" or "http:domain:80" (no //)
    local host_id=""
    for prefix in "https:${domain}:443" "http:${domain}:80" "https:www.${domain}:443" "http:www.${domain}:80"; do
        host_id=$(echo "$response" | grep -o "\"host_id\":\"${prefix}\"" | head -1 | sed 's/"host_id":"//' | tr -d '"')
        if [[ -n "$host_id" ]]; then
            break
        fi
    done

    # Fallback: search by domain substring (prefer HTTPS)
    if [[ -z "$host_id" ]]; then
        host_id=$(echo "$response" | grep -o "\"host_id\":\"https:[^\"]*${domain}[^\"]*\"" | head -1 | sed 's/"host_id":"//' | tr -d '"')
    fi
    if [[ -z "$host_id" ]]; then
        host_id=$(echo "$response" | grep -o "\"host_id\":\"[^\"]*${domain}[^\"]*\"" | head -1 | sed 's/"host_id":"//' | tr -d '"')
    fi

    if [[ -z "$host_id" ]]; then
        echo "Error: Site '$domain' not found in Yandex Webmaster." >&2
        echo "Available sites:" >&2
        echo "$response" | grep -o '"unicode_host_url":"[^"]*"' | sed 's/"unicode_host_url":"//;s/"//' >&2
        return 1
    fi

    echo "$host_id" > "$cache_file"
    echo "$host_id"
}

# Build base path for host endpoints
# Usage: host_path "example.com"
host_path() {
    local domain="$1"
    local uid
    uid=$(get_user_id) || return 1
    local hid
    hid=$(find_host_id "$domain") || return 1
    echo "/user/${uid}/hosts/${hid}"
}

# Rate-limit-aware GET: retries once after delay if response looks like rate-limited zeros
# Usage: webmaster_get_safe "endpoint_path"
webmaster_get_safe() {
    local path="$1"
    local response
    response=$(webmaster_get "$path")

    # Detect silent rate limit: HTTP 200 with suspicious zero data
    # Pattern: searchable_pages_count:0 when sqi > 0
    local pages sqi
    pages=$(json_value "$response" "searchable_pages_count")
    sqi=$(json_value "$response" "sqi")

    if [[ "$pages" == "0" && -n "$sqi" && "$sqi" -gt 0 ]] 2>/dev/null; then
        echo "[WARN] Possible rate limit: searchable_pages_count=0 with sqi=$sqi. Retrying in 10s..." >&2
        sleep 10
        response=$(webmaster_get "$path")
        # Check again after retry
        pages=$(json_value "$response" "searchable_pages_count")
        if [[ "$pages" == "0" ]] 2>/dev/null; then
            echo "[WARN] Still 0 after retry. Data may be affected by API rate limit. Retrying in 30s..." >&2
            sleep 30
            response=$(webmaster_get "$path")
            pages=$(json_value "$response" "searchable_pages_count")
            if [[ "$pages" == "0" ]] 2>/dev/null; then
                echo "[ERROR] searchable_pages_count=0 persists after 2 retries. Marking as RATE_LIMITED." >&2
                # Inject warning into response
                response=$(echo "$response" | sed 's/}$/,"_rate_limit_warning":"searchable_pages_count may be inaccurate due to API rate limiting"}/')
            fi
        fi
    fi

    echo "$response"
}

# Rate-limit-aware GET for queries: retries if count=0 for high-SQI sites
# Usage: webmaster_get_queries_safe "endpoint_path" sqi_value
webmaster_get_queries_safe() {
    local path="$1"
    local sqi="${2:-0}"
    local response
    response=$(webmaster_get "$path")

    local count
    count=$(json_value "$response" "count")

    if [[ "$count" == "0" && -n "$sqi" && "$sqi" -gt 200 ]] 2>/dev/null; then
        echo "[WARN] Possible rate limit: 0 queries with sqi=$sqi. Retrying in 10s..." >&2
        sleep 10
        response=$(webmaster_get "$path")
        count=$(json_value "$response" "count")
        if [[ "$count" == "0" ]] 2>/dev/null; then
            echo "[WARN] Still 0 queries after retry. Retrying in 30s..." >&2
            sleep 30
            response=$(webmaster_get "$path")
            count=$(json_value "$response" "count")
            if [[ "$count" == "0" ]] 2>/dev/null; then
                echo "[ERROR] 0 queries persists after 2 retries. Marking as RATE_LIMITED." >&2
                response=$(echo "$response" | sed 's/}$/,"_rate_limit_warning":"query count may be inaccurate due to API rate limiting"}/')
            fi
        fi
    fi

    echo "$response"
}

# Inter-host delay: call between auditing different sites in one session
# Usage: rate_limit_pause
rate_limit_pause() {
    local delay="${1:-3}"
    sleep "$delay"
}

# Extract JSON value (no jq)
json_value() {
    local json="$1"
    local key="$2"
    echo "$json" | grep -o "\"$key\":[^,}]*" | head -1 | sed 's/.*://' | tr -d '"[:space:]'
}

# Extract JSON string value
json_string() {
    local json="$1"
    local key="$2"
    echo "$json" | grep -o "\"$key\":\"[^\"]*\"" | head -1 | sed 's/.*:"//' | tr -d '"'
}

# Format number with separator
format_number() {
    local num="$1"
    printf "%'d" "$num" 2>/dev/null || echo "$num"
}

# Clear cached data
clear_cache() {
    rm -f "$CACHE_DIR"/user_id "$CACHE_DIR"/host_*
    echo "Cache cleared."
}
