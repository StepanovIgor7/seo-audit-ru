#!/bin/bash
# Установка SEO-Audit-RU скиллов для Claude Code

set -e

SKILLS_DIR="$HOME/.claude/skills"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== Установка SEO-Audit-RU ==="
echo ""

# Создаём директорию скиллов если нет
mkdir -p "$SKILLS_DIR"

# Копируем скиллы
for skill in seo-audit-ru yandex-webmaster yandex-wordstat; do
    if [ -d "$SKILLS_DIR/$skill" ]; then
        echo "[$skill] Уже установлен. Обновляю..."
        rm -rf "$SKILLS_DIR/$skill"
    fi
    cp -r "$SCRIPT_DIR/skills/$skill" "$SKILLS_DIR/$skill"
    echo "[$skill] Установлен."
done

# Делаем скрипты исполняемыми
chmod +x "$SKILLS_DIR"/seo-audit-ru/scripts/*.sh 2>/dev/null
chmod +x "$SKILLS_DIR"/yandex-webmaster/scripts/*.sh 2>/dev/null
chmod +x "$SKILLS_DIR"/yandex-wordstat/scripts/*.sh 2>/dev/null

# Создаём config/.env если нет
ENV_FILE="$SKILLS_DIR/yandex-wordstat/config/.env"
if [ ! -f "$ENV_FILE" ]; then
    cp "$SCRIPT_DIR/config/.env.example" "$ENV_FILE"
    echo ""
    echo "Создан файл конфигурации: $ENV_FILE"
    echo "Заполните его своими токенами (см. README.md)."
else
    echo ""
    echo "Файл конфигурации уже существует: $ENV_FILE"
fi

echo ""
echo "=== Установка завершена ==="
echo ""
echo "Следующие шаги:"
echo "1. Заполните токены в $ENV_FILE"
echo "2. Установите claude-seo: claude install-skill AgriciDaniel/claude-seo"
echo "3. Перезапустите Claude Code"
echo "4. Попробуйте: /seo-audit-ru example.com"
