#!/bin/bash
#
# Тесты для yandex_checks.sh
#
# Запуск:
#   bash tests/test_yandex_checks.sh
#
# Проверяет:
#   1. Скрипт существует и исполняемый
#   2. Выдаёт валидный JSON
#   3. JSON содержит все обязательные ключи
#   4. Скрипт ошибается при отсутствии аргумента
#   5. Нет hardcoded секретов
#   6. Нет опасных команд

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$SCRIPT_DIR/scripts/yandex_checks.sh"

PASSED=0
FAILED=0
TOTAL=0

pass() {
    PASSED=$((PASSED + 1))
    TOTAL=$((TOTAL + 1))
    echo "  ✅ $1"
}

fail() {
    FAILED=$((FAILED + 1))
    TOTAL=$((TOTAL + 1))
    echo "  ❌ $1"
    if [ -n "${2:-}" ]; then
        echo "     $2"
    fi
}

echo ""
echo "═══════════════════════════════════════════════"
echo "  Tests: yandex_checks.sh"
echo "═══════════════════════════════════════════════"
echo ""

# ── 1. Файл существует и исполняемый ─────────────────────────

echo "=== File checks ==="

if [ -f "$SCRIPT" ]; then
    pass "Script exists"
else
    fail "Script not found at $SCRIPT"
fi

if [ -x "$SCRIPT" ]; then
    pass "Script is executable"
else
    fail "Script is not executable" "Run: chmod +x $SCRIPT"
fi

# ── 2. Ошибка при отсутствии аргумента ───────────────────────

echo ""
echo "=== Argument validation ==="

if ! bash "$SCRIPT" 2>/dev/null; then
    pass "Exits with error when no argument"
else
    fail "Should exit with error when no domain argument"
fi

# ── 3. Нет hardcoded секретов ────────────────────────────────

echo ""
echo "=== Security checks ==="

SOURCE=$(cat "$SCRIPT")

# Проверка на hardcoded API ключи
if echo "$SOURCE" | grep -qE 'AIza[A-Za-z0-9_-]{35}'; then
    fail "Hardcoded Google API key found"
else
    pass "No hardcoded Google API keys"
fi

# Проверка на Yandex-токены
if echo "$SOURCE" | grep -qE 'y[0-3]_[A-Za-z0-9_-]{35,}' | grep -vE '(example|placeholder|ваш_)'; then
    fail "Hardcoded Yandex token found"
else
    pass "No hardcoded Yandex tokens"
fi

# Проверка что PSI_KEY читается из env, не захардкожен
if echo "$SOURCE" | grep -q 'PSI_KEY="${PAGESPEED_API_KEY:-}"' || echo "$SOURCE" | grep -q 'GOOGLE_PSI_KEY'; then
    pass "API key loaded from environment"
else
    fail "API key should be loaded from environment variable"
fi

# Проверка на rm -rf или другие деструктивные команды
if echo "$SOURCE" | grep -qE 'rm\s+-rf\s+/' ; then
    fail "Dangerous 'rm -rf /' pattern found"
else
    pass "No dangerous rm commands"
fi

# Проверка что tmpfile удаляется
if echo "$SOURCE" | grep -q 'rm -f "$TMPFILE"'; then
    pass "Temp file cleaned up"
else
    fail "Temp file not cleaned up (missing rm -f \$TMPFILE)"
fi

# Проверка что нет eval на пользовательском вводе
if echo "$SOURCE" | grep -qE 'eval\s+.*\$'; then
    fail "Dangerous eval on variable found"
else
    pass "No dangerous eval patterns"
fi

# Проверка что curl не отправляет данные (только GET/HEAD)
if echo "$SOURCE" | grep -qE 'curl.*(-d |--data |--data-raw |--data-binary |-X POST|-X PUT|-X DELETE)'; then
    fail "curl sends data (expected read-only GET/HEAD)"
else
    pass "curl is read-only (no POST/PUT/DELETE)"
fi

# ── 4. JSON структура (статический анализ) ───────────────────

echo ""
echo "=== JSON structure checks ==="

# Все обязательные JSON ключи
REQUIRED_KEYS=(
    "robots_txt_yandex"
    "yandex_metrika"
    "turbo_pages"
    "regionality"
    "trackers"
    "open_graph"
    "meta_robots_sample"
    "core_web_vitals"
)

for key in "${REQUIRED_KEYS[@]}"; do
    if echo "$SOURCE" | grep -q "\"$key\""; then
        pass "JSON key: $key"
    else
        fail "Missing JSON key: $key"
    fi
done

# Проверяем что robots_txt_yandex содержит все нужные подключи
ROBOTS_SUBKEYS=(
    "has_yandex_section"
    "has_clean_param"
    "has_host_directive"
    "has_crawl_delay"
    "has_sitemap"
)

for key in "${ROBOTS_SUBKEYS[@]}"; do
    if echo "$SOURCE" | grep -q "$key"; then
        pass "robots_txt_yandex.$key"
    else
        fail "Missing robots_txt_yandex.$key"
    fi
done

# CWV subkeys
CWV_SUBKEYS=("lcp_ms" "inp_ms" "cls" "ttfb_ms")
for key in "${CWV_SUBKEYS[@]}"; do
    if echo "$SOURCE" | grep -q "$key"; then
        pass "core_web_vitals.$key"
    else
        fail "Missing core_web_vitals.$key"
    fi
done

# ── 5. Валидность JSON на реальном домене (опционально) ──────

echo ""
echo "=== Live JSON validation (example.com) ==="

# Используем example.com — всегда доступен, минимальная нагрузка
LIVE_OUTPUT=$(bash "$SCRIPT" "example.com" 2>/dev/null || true)

if [ -n "$LIVE_OUTPUT" ]; then
    pass "Script produces output for example.com"

    # Проверяем валидность JSON
    if echo "$LIVE_OUTPUT" | python3 -m json.tool >/dev/null 2>&1; then
        pass "Output is valid JSON"
    else
        fail "Output is NOT valid JSON" "$(echo "$LIVE_OUTPUT" | head -5)"
    fi

    # Проверяем что все корневые ключи присутствуют в выводе
    for key in "${REQUIRED_KEYS[@]}"; do
        if echo "$LIVE_OUTPUT" | python3 -c "import json,sys; d=json.load(sys.stdin); assert '$key' in d" 2>/dev/null; then
            pass "Live output has key: $key"
        else
            fail "Live output missing key: $key"
        fi
    done
else
    fail "Script produced no output for example.com"
fi

# ── Результат ────────────────────────────────────────────────

echo ""
echo "═══════════════════════════════════════════════"
echo "  Results: $PASSED passed, $FAILED failed (total: $TOTAL)"
echo "═══════════════════════════════════════════════"
echo ""

exit $FAILED
