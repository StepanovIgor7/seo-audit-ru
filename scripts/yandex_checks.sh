#!/bin/bash
# Yandex-specific SEO checks that are not covered by other skills
# Usage: yandex_checks.sh <domain>

DOMAIN="${1:?Usage: yandex_checks.sh <domain>}"
URL="https://${DOMAIN}"
TMPFILE=$(mktemp)

# Fetch homepage HTML once
curl -sL -A "Mozilla/5.0 (compatible; SEO-Audit-RU/1.0)" "$URL" -o "$TMPFILE" 2>/dev/null

echo "{"

# === 1. robots.txt: Yandex section ===
echo '"robots_txt_yandex": {'
ROBOTS=$(curl -sL "${URL}/robots.txt" 2>/dev/null)

# Extract Yandex-specific directives
YANDEX_SECTION=$(echo "$ROBOTS" | sed -n '/^[Uu]ser-agent:.*[Yy]andex/,/^[Uu]ser-agent:/p' | sed '$d')
HAS_YANDEX_SECTION="false"
if [ -n "$YANDEX_SECTION" ]; then
    HAS_YANDEX_SECTION="true"
fi

# Clean-param (Yandex-specific directive)
CLEAN_PARAM=$(echo "$ROBOTS" | grep -i "^Clean-param" | head -5)
HAS_CLEAN_PARAM="false"
if [ -n "$CLEAN_PARAM" ]; then
    HAS_CLEAN_PARAM="true"
fi

# Host directive
HOST_DIRECTIVE=$(echo "$ROBOTS" | grep -i "^Host:" | head -1)
HAS_HOST="false"
if [ -n "$HOST_DIRECTIVE" ]; then
    HAS_HOST="true"
fi

# Crawl-delay
CRAWL_DELAY=$(echo "$ROBOTS" | grep -i "^Crawl-delay" | head -1)
HAS_CRAWL_DELAY="false"
if [ -n "$CRAWL_DELAY" ]; then
    HAS_CRAWL_DELAY="true"
fi

# Sitemap in robots
SITEMAP_ROBOTS=$(echo "$ROBOTS" | grep -i "^Sitemap:" | head -3)
HAS_SITEMAP="false"
if [ -n "$SITEMAP_ROBOTS" ]; then
    HAS_SITEMAP="true"
fi

echo "  \"has_yandex_section\": $HAS_YANDEX_SECTION,"
echo "  \"has_clean_param\": $HAS_CLEAN_PARAM,"
echo "  \"has_host_directive\": $HAS_HOST,"
echo "  \"has_crawl_delay\": $HAS_CRAWL_DELAY,"
echo "  \"has_sitemap\": $HAS_SITEMAP"
echo '},'

# === 2. Yandex Metrika ===
echo '"yandex_metrika": {'
METRIKA_ID=$(grep -o 'yandex_metrika_callbacks2\|ym([0-9]*\|yaCounter[0-9]*\|mc\.yandex\.ru/watch/[0-9]*' "$TMPFILE" | grep -o '[0-9]\{5,\}' | head -1)
if [ -n "$METRIKA_ID" ]; then
    echo "  \"installed\": true,"
    echo "  \"counter_id\": \"$METRIKA_ID\""
else
    echo "  \"installed\": false,"
    echo "  \"counter_id\": null"
fi
echo '},'

# === 3. Turbo Pages ===
echo '"turbo_pages": {'
TURBO_LINK=$(grep -i 'rel="turbo"' "$TMPFILE" | head -1)
TURBO_RSS=$(curl -sI "${URL}/turbo-feed" 2>/dev/null | grep -i "200\|xml")
HAS_TURBO="false"
if [ -n "$TURBO_LINK" ] || [ -n "$TURBO_RSS" ]; then
    HAS_TURBO="true"
fi
echo "  \"detected\": $HAS_TURBO"
echo '},'

# === 4. Regional meta tags ===
echo '"regionality": {'
GEO_REGION=$(grep -oi '<meta name="geo\.region"[^>]*content="[^"]*"' "$TMPFILE" | grep -o 'content="[^"]*"' | sed 's/content="//;s/"//')
GEO_PLACE=$(grep -oi '<meta name="geo\.placename"[^>]*content="[^"]*"' "$TMPFILE" | grep -o 'content="[^"]*"' | sed 's/content="//;s/"//')
GEO_POS=$(grep -oi '<meta name="geo\.position"[^>]*content="[^"]*"' "$TMPFILE" | grep -o 'content="[^"]*"' | sed 's/content="//;s/"//')

HAS_GEO="false"
if [ -n "$GEO_REGION" ] || [ -n "$GEO_PLACE" ]; then
    HAS_GEO="true"
fi

echo "  \"has_geo_meta\": $HAS_GEO,"
echo "  \"geo_region\": \"${GEO_REGION:-not set}\","
echo "  \"geo_placename\": \"${GEO_PLACE:-not set}\","
echo "  \"geo_position\": \"${GEO_POS:-not set}\""
echo '},'

# === 5. Trackers ===
echo '"trackers": {'

# VK Pixel
VK_PIXEL=$(grep -o 'vk\.com/rtrg[^"]*' "$TMPFILE" | head -1)
HAS_VK="false"
VK_ID=""
if [ -n "$VK_PIXEL" ]; then
    HAS_VK="true"
    VK_ID=$(echo "$VK_PIXEL" | grep -o 'VK-RTRG-[0-9]*' | head -1)
fi

# Top.Mail.ru
MAIL_COUNTER=$(grep -o 'top-fwz1\.mail\.ru' "$TMPFILE" | head -1)
HAS_MAIL="false"
if [ -n "$MAIL_COUNTER" ]; then
    HAS_MAIL="true"
fi

# Roistat
ROISTAT=$(grep -o 'roistat' "$TMPFILE" | head -1)
HAS_ROISTAT="false"
if [ -n "$ROISTAT" ]; then
    HAS_ROISTAT="true"
fi

# Google Analytics / GTM
GA=$(grep -oiE 'gtag|googletagmanager|google-analytics|ga\(' "$TMPFILE" | head -1)
HAS_GA="false"
if [ -n "$GA" ]; then
    HAS_GA="true"
fi

# Reuse metrika detection from section 2 above
HAS_METRIKA="false"
if [ -n "$METRIKA_ID" ]; then
    HAS_METRIKA="true"
fi
echo "  \"yandex_metrika\": $HAS_METRIKA,"
echo "  \"vk_pixel\": $HAS_VK,"
echo "  \"top_mail_ru\": $HAS_MAIL,"
echo "  \"roistat\": $HAS_ROISTAT,"
echo "  \"google_analytics\": $HAS_GA"
echo '},'

# === 6. Open Graph ===
echo '"open_graph": {'
OG_TITLE=$(grep -oi '<meta property="og:title"[^>]*content="[^"]*"' "$TMPFILE" | grep -o 'content="[^"]*"' | sed 's/content="//;s/"//' | head -1)
OG_DESC=$(grep -oi '<meta property="og:description"[^>]*content="[^"]*"' "$TMPFILE" | grep -o 'content="[^"]*"' | sed 's/content="//;s/"//' | head -1)
OG_IMAGE=$(grep -oi '<meta property="og:image"[^>]*content="[^"]*"' "$TMPFILE" | grep -o 'content="[^"]*"' | sed 's/content="//;s/"//' | head -1)

HAS_OG="false"
if [ -n "$OG_TITLE" ] && [ -n "$OG_DESC" ] && [ -n "$OG_IMAGE" ]; then
    HAS_OG="true"
fi

echo "  \"complete\": $HAS_OG,"
echo "  \"og_title\": \"${OG_TITLE:-missing}\","
echo "  \"og_description\": \"${OG_DESC:-missing}\","
echo "  \"og_image\": \"${OG_IMAGE:-missing}\""
echo '},'

# === 7. Yandex.Справочник (Business Directory) ===
echo '"yandex_spravochnik": {'
HAS_SPRAV="false"
SPRAV_URL=""

# Check if site HTML links to its own Yandex Maps/Spravochnik card
SPRAV_LINK=$(grep -oi 'yandex\.\(ru\|com\)/maps/org/[^"< ]*' "$TMPFILE" | head -1)
if [ -n "$SPRAV_LINK" ]; then
    HAS_SPRAV="true"
    SPRAV_URL="https://$SPRAV_LINK"
fi

# Check for Yandex.Business widget or maps references
if [ "$HAS_SPRAV" = "false" ]; then
    SPRAV_IN_HTML=$(grep -oi 'business\.yandex\|yandex\.ru/maps\|maps\.yandex\|yandex\.com/maps' "$TMPFILE" | head -1)
    if [ -n "$SPRAV_IN_HTML" ]; then
        HAS_SPRAV="true"
    fi
fi

# Note: false does NOT mean card doesn't exist — Yandex Maps is JS-rendered.
# Claude should verify via WebSearch if detected=false.
echo "  \"detected\": $HAS_SPRAV,"
echo "  \"url\": \"${SPRAV_URL:-not found}\","
echo "  \"note\": \"if false, verify via WebSearch — script cannot detect JS-rendered Maps cards\""
echo '},'

# === 8. Meta robots sampling ===
echo '"meta_robots_sample": ['

# Sample different page types and check their meta robots
FIRST="true"
for path in "/" "/blog" "/about" "/contacts"; do
    SAMPLE_URL="${URL}${path}"
    SAMPLE_HTML=$(curl -sL -A "Mozilla/5.0" "$SAMPLE_URL" 2>/dev/null)
    META_ROBOTS=$(echo "$SAMPLE_HTML" | grep -oi '<meta name="robots"[^>]*content="[^"]*"' | grep -o 'content="[^"]*"' | sed 's/content="//;s/"//' | head -1)

    if [ "$FIRST" = "true" ]; then
        FIRST="false"
    else
        echo ","
    fi

    echo -n "  {\"path\": \"$path\", \"meta_robots\": \"${META_ROBOTS:-not set}\"}"
done
echo ""
echo '],'

# === 8. PageSpeed CWV (field data) ===
echo '"core_web_vitals": {'
PSI_KEY="${PAGESPEED_API_KEY:-}"

# Try to load from env file
if [ -z "$PSI_KEY" ]; then
    ENV_FILE="$HOME/.claude/skills/yandex-wordstat/config/.env"
    if [ -f "$ENV_FILE" ]; then
        # shellcheck disable=SC1090
        source "$ENV_FILE"
    fi
fi

# After sourcing .env, GOOGLE_PSI_KEY may now be set
if [ -z "$PSI_KEY" ] && [ -n "$GOOGLE_PSI_KEY" ]; then
    PSI_KEY="$GOOGLE_PSI_KEY"
fi

if [ -z "$PSI_KEY" ]; then
    echo "[WARN] GOOGLE_PSI_KEY not set. Set it in ~/.claude/skills/yandex-wordstat/config/.env or export PAGESPEED_API_KEY" >&2
    echo "[WARN] CWV data will be empty." >&2
fi

CWV_DATA=$(curl -s "https://www.googleapis.com/pagespeedonline/v5/runPagespeed?url=${URL}&key=${PSI_KEY}&strategy=mobile&category=performance" 2>/dev/null)

LCP=$(echo "$CWV_DATA" | grep -A2 '"LARGEST_CONTENTFUL_PAINT_MS"' | grep '"percentile"' | head -1 | grep -o '[0-9]*')
INP=$(echo "$CWV_DATA" | grep -A2 '"INTERACTION_TO_NEXT_PAINT"' | grep '"percentile"' | head -1 | grep -o '[0-9]*')
CLS=$(echo "$CWV_DATA" | grep -A2 '"CUMULATIVE_LAYOUT_SHIFT_SCORE"' | grep '"percentile"' | head -1 | grep -o '[0-9]*')
TTFB=$(echo "$CWV_DATA" | grep -A2 '"EXPERIMENTAL_TIME_TO_FIRST_BYTE"' | grep '"percentile"' | head -1 | grep -o '[0-9]*')

echo "  \"lcp_ms\": ${LCP:-null},"
echo "  \"inp_ms\": ${INP:-null},"
echo "  \"cls\": ${CLS:-null},"
echo "  \"ttfb_ms\": ${TTFB:-null}"
echo '}'

echo "}"

# Cleanup
rm -f "$TMPFILE"
