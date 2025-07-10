#!/bin/bash

# Usage:
#   ./check_domains.sh zabc.net
#   MAX_CONCURRENT=10 SLEEP_INTERVAL=1 CONNECT_TIMEOUT=5 ./check_domains.sh zabc.net

# ------------------ Config ------------------
DOMAIN="$1"
MAX_CONCURRENT="${MAX_CONCURRENT:-5}"
SLEEP_INTERVAL="${SLEEP_INTERVAL:-2}"
CONNECT_TIMEOUT="${CONNECT_TIMEOUT:-3}"

if [ -z "$DOMAIN" ]; then
  echo "Usage: $0 yourdomain.com"
  exit 1
fi

# ------------------ Files ------------------
TMP_JSON=$(mktemp)
TMP_DOMAINS=$(mktemp)
SUCCESS_FILE="https_200.txt"
FAIL_FILE="https_failed.txt"
> "$SUCCESS_FILE"
> "$FAIL_FILE"

# ------------------ Fetch Subdomains ------------------
echo "[*] Fetching subdomains for: $DOMAIN"
curl -s "https://crt.sh/json?q=${DOMAIN}" > "$TMP_JSON"

echo "[*] Extracting and deduplicating domains..."
jq -r '.[].name_value' "$TMP_JSON" | tr '\n' ',' | tr ',' '\n' | sed 's/\*\.//' | sort -u > "$TMP_DOMAINS"

TOTAL=$(wc -l < "$TMP_DOMAINS")
echo "[*] Found $TOTAL unique subdomains."

# ------------------ Test Function ------------------
test_domain() {
    domain="$1"
    idx="$2"

    https_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time "$CONNECT_TIMEOUT" --connect-timeout "$CONNECT_TIMEOUT" "https://$domain")
    http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time "$CONNECT_TIMEOUT" --connect-timeout "$CONNECT_TIMEOUT" "http://$domain")

    if [ "$https_code" = "200" ] || [ "$http_code" = "200" ]; then
        echo "[progress: $idx/$TOTAL] $domain ✅ (https:$https_code / http:$http_code)"
        echo "$domain" >> "$SUCCESS_FILE"
    else
        echo "[progress: $idx/$TOTAL] $domain ❌ (https:$https_code / http:$http_code)"
        echo "$domain (https:$https_code http:$http_code)" >> "$FAIL_FILE"
    fi
}

# ------------------ Concurrent Processing ------------------
echo "[*] Starting concurrent testing (max $MAX_CONCURRENT at a time)..."
CURRENT_JOBS=0
COUNT=0

while read -r domain; do
    COUNT=$((COUNT + 1))
    test_domain "$domain" "$COUNT" &

    CURRENT_JOBS=$((CURRENT_JOBS + 1))
    if [ "$CURRENT_JOBS" -ge "$MAX_CONCURRENT" ]; then
        wait -n
        CURRENT_JOBS=$((CURRENT_JOBS - 1))
        sleep "$SLEEP_INTERVAL"
    fi
done < "$TMP_DOMAINS"

wait

echo ""
echo "[*] Scan complete for: $DOMAIN"
echo "✅ Available domains: saved in $SUCCESS_FILE"
echo "❌ Unavailable domains: saved in $FAIL_FILE"

rm "$TMP_JSON" "$TMP_DOMAINS"
