#!/bin/bash
# Extended Yandex.Справочник (Business Directory) check
# Usage: spravochnik_check.sh <domain>
# Returns JSON with detailed business directory analysis

DOMAIN="${1:?Usage: spravochnik_check.sh <domain>}"
URL="https://${DOMAIN}"
TMPFILE=$(mktemp)
TMPFILE2=$(mktemp)

# Fetch homepage HTML
curl -sL -A "Mozilla/5.0 (compatible; SEO-Audit-RU/1.0)" "$URL" -o "$TMPFILE" 2>/dev/null

echo "{"

# === 1. Yandex Maps / Spravochnik presence ===
echo '"yandex_maps_search": {'

# Detection of Yandex Maps/Spravochnik card.
# Yandex Maps is a JS SPA — curl cannot parse it reliably.
# We use multiple fallback methods, but automated detection has limits.
# The SKILL.md instructs Claude to also use WebSearch as a verification step.

HAS_ORG="false"
ORG_NAME=""
ORG_ID=""
ORG_URL=""
ORG_ADDRESS=""

# Method 1: Check if site HTML links to its own Yandex Maps card
MAPS_SELF_LINK=$(grep -oi 'yandex\.\(ru\|com\)/maps/org/[^"< ]*' "$TMPFILE" | head -1)
if [ -n "$MAPS_SELF_LINK" ]; then
    HAS_ORG="true"
    ORG_NAME="(linked from site)"
    ORG_URL="https://$MAPS_SELF_LINK"
fi

# Method 2: Check contact page for Yandex Maps links
if [ "$HAS_ORG" = "false" ]; then
    for cpath in "/contacts" "/kontakty" "/contact"; do
        CONTACT_HTML=$(curl -sL -A "Mozilla/5.0 (compatible; SEO-Audit-RU/1.0)" "${URL}${cpath}" 2>/dev/null)
        CONTACT_MAPS_LINK=$(echo "$CONTACT_HTML" | grep -oi 'yandex\.\(ru\|com\)/maps/org/[^"< ]*' | head -1)
        if [ -n "$CONTACT_MAPS_LINK" ]; then
            HAS_ORG="true"
            ORG_NAME="(linked from ${cpath})"
            ORG_URL="https://$CONTACT_MAPS_LINK"
            break
        fi
    done
fi

# Note: If both methods fail, HAS_ORG="false" does NOT mean the card doesn't exist.
# Yandex Maps cards often exist but aren't linked from the site.
# The SKILL.md instructs Claude to verify via WebSearch when this happens.

echo "  \"found\": $HAS_ORG,"
echo "  \"org_name\": \"${ORG_NAME:-not found}\","
echo "  \"org_id\": \"${ORG_ID:-unknown}\","
echo "  \"org_url\": \"${ORG_URL:-unknown}\","
echo "  \"address\": \"${ORG_ADDRESS:-unknown}\""
echo '},'

# === 2. Links to Yandex Maps/Business on the site ===
echo '"maps_links_on_site": {'

MAPS_LINK=$(grep -oi 'yandex\.ru/maps[^"]*\|maps\.yandex\.ru[^"]*' "$TMPFILE" | head -3)
HAS_MAPS_LINK="false"
MAPS_URLS="[]"
if [ -n "$MAPS_LINK" ]; then
    HAS_MAPS_LINK="true"
    MAPS_URLS="[$(echo "$MAPS_LINK" | sed 's/^/"/' | sed 's/$/"/' | tr '\n' ',' | sed 's/,$//' )]"
fi

echo "  \"has_links\": $HAS_MAPS_LINK,"
echo "  \"urls\": $MAPS_URLS"
echo '},'

# === 3. NAP consistency (Name, Address, Phone on site) ===
echo '"nap_on_site": {'

# Phone numbers (Russian format)
PHONES=$(grep -oE '(\+7|8)[\s\-\(]?[0-9]{3}[\s\-\)]?[0-9]{3}[\-\s]?[0-9]{2}[\-\s]?[0-9]{2}' "$TMPFILE" | sort -u | head -5)
PHONE_COUNT=$(echo "$PHONES" | grep -c '[0-9]' 2>/dev/null || echo "0")

# Address patterns (Russian)
ADDRESS=$(grep -oi 'г\.\s*[А-Яа-яЁё]*\|ул\.\s*[А-Яа-яЁё]*\|пр\.\s*[А-Яа-яЁё]*\|д\.\s*[0-9]*' "$TMPFILE" | head -5)
HAS_ADDRESS="false"
if [ -n "$ADDRESS" ]; then
    HAS_ADDRESS="true"
fi

# Email
EMAILS=$(grep -oiE '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}' "$TMPFILE" | sort -u | head -3)
HAS_EMAIL="false"
if [ -n "$EMAILS" ]; then
    HAS_EMAIL="true"
fi

echo "  \"phones_found\": $PHONE_COUNT,"
echo "  \"has_address\": $HAS_ADDRESS,"
echo "  \"has_email\": $HAS_EMAIL"
echo '},'

# === 4. Schema.org LocalBusiness / Organization ===
echo '"schema_business": {'

# Check for LocalBusiness or Organization schema
LOCAL_BIZ=$(grep -oi '"@type"[^,]*"LocalBusiness"\|"@type"[^,]*"Organization"\|"@type"[^,]*"Corporation"' "$TMPFILE" | head -1)
HAS_SCHEMA="false"
SCHEMA_TYPE="none"
if [ -n "$LOCAL_BIZ" ]; then
    HAS_SCHEMA="true"
    SCHEMA_TYPE=$(echo "$LOCAL_BIZ" | grep -oi 'LocalBusiness\|Organization\|Corporation' | head -1)
fi

echo "  \"has_business_schema\": $HAS_SCHEMA,"
echo "  \"schema_type\": \"$SCHEMA_TYPE\""
echo '},'

# === 5. Yandex.Business widget / reviews ===
echo '"yandex_business_widget": {'

WIDGET=$(grep -oi 'business\.yandex\|yandex-business\|widget.*yandex.*review\|yandex.*otzyvy' "$TMPFILE" | head -1)
HAS_WIDGET="false"
if [ -n "$WIDGET" ]; then
    HAS_WIDGET="true"
fi

echo "  \"detected\": $HAS_WIDGET"
echo '},'

# === 6. geo meta tags (from homepage) ===
echo '"geo_signals": {'

GEO_REGION=$(grep -oi '<meta name="geo\.region"[^>]*content="[^"]*"' "$TMPFILE" | grep -o 'content="[^"]*"' | sed 's/content="//;s/"//')
GEO_PLACE=$(grep -oi '<meta name="geo\.placename"[^>]*content="[^"]*"' "$TMPFILE" | grep -o 'content="[^"]*"' | sed 's/content="//;s/"//')
GEO_POS=$(grep -oi '<meta name="geo\.position"[^>]*content="[^"]*"' "$TMPFILE" | grep -o 'content="[^"]*"' | sed 's/content="//;s/"//')
ICBM=$(grep -oi '<meta name="ICBM"[^>]*content="[^"]*"' "$TMPFILE" | grep -o 'content="[^"]*"' | sed 's/content="//;s/"//')

echo "  \"geo_region\": \"${GEO_REGION:-not set}\","
echo "  \"geo_placename\": \"${GEO_PLACE:-not set}\","
echo "  \"geo_position\": \"${GEO_POS:-not set}\","
echo "  \"icbm\": \"${ICBM:-not set}\""
echo '},'

# === 7. Contact page check ===
echo '"contact_page": {'

# Try common contact page paths
CONTACT_FOUND="false"
CONTACT_URL=""
for path in "/contacts" "/kontakty" "/contact" "/about/contacts" "/o-kompanii"; do
    HTTP_CODE=$(curl -sL -o /dev/null -w "%{http_code}" -A "Mozilla/5.0" "${URL}${path}" 2>/dev/null)
    if [ "$HTTP_CODE" = "200" ]; then
        CONTACT_FOUND="true"
        CONTACT_URL="${path}"
        break
    fi
done

echo "  \"found\": $CONTACT_FOUND,"
echo "  \"path\": \"${CONTACT_URL:-none}\""
echo '}'

echo "}"

# Cleanup
rm -f "$TMPFILE" "$TMPFILE2"
