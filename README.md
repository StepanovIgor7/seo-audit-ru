# SEO-Audit-RU: Комплексный SEO-аудит для российского рынка

Набор скиллов для Claude Code, объединяющий Google SEO-аудит и Яндекс-аналитику в единый отчёт.

## Что входит

| Скилл | Описание |
|-------|----------|
| `/seo-audit-ru` | Мета-скилл: объединяет Google и Яндекс аудит в единый отчёт |
| `/yandex-webmaster` | Данные из Яндекс Вебмастер API: ИКС, индексация, запросы, диагностика, ссылки |
| `/yandex-wordstat` | Анализ поискового спроса через Яндекс Wordstat API |

## Возможности

### /seo-audit-ru
- Полный Google SEO-аудит (через `/seo-audit`)
  - Technical SEO: краулинг, индексация, безопасность, URL-структура, мобильность
  - Core Web Vitals: LCP, INP, CLS, TTFB (через Google PageSpeed API)
  - Контент: E-E-A-T анализ, тонкий контент, читабельность
  - Schema.org: микроразметка, валидация JSON-LD
  - Изображения: alt-тексты, размеры, форматы, lazy loading
  - AI Search (GEO): видимость в AI Overviews, ChatGPT, Perplexity
  - Сайтмап: валидация XML, структура
- Данные Яндекс Вебмастера (ИКС, индексация, поисковые запросы, диагностика)
- Яндекс-специфичные проверки:
  - robots.txt: секция Yandex, Clean-param, Host, Crawl-delay
  - Яндекс Метрика (наличие, ID счётчика)
  - Турбо-страницы
  - Региональность (geo мета-теги)
  - Трекеры (VK Pixel, Top.Mail.ru, Roistat, GA)
  - Open Graph (для VK/Telegram)
  - meta robots по разделам сайта
  - Core Web Vitals (через PageSpeed API)
- Единый сводный отчёт с рекомендациями

### /yandex-webmaster
- ИКС (SQI) и динамика за 90 дней
- Статус индексации и история
- ТОП поисковых запросов (до 3000)
- Внешние ссылки + битые внутренние
- Диагностика проблем (FATAL / CRITICAL / POSSIBLE / RECOMMENDATION)
- Сайтмапы
- Переобход страниц (recrawl)

### /yandex-wordstat
- ТОП-2000 запросов с частотностью
- Ассоциации и синонимы
- Региональный спрос
- Динамика (тренды)
- Анализ упущенного спроса

## Установка

### 1. Зависимости

Установите [claude-seo](https://github.com/AgriciDaniel/claude-seo) (Google-часть аудита):

```bash
claude install-skill AgriciDaniel/claude-seo
```

### 2. Установка скиллов

```bash
git clone https://github.com/StepanovIgor7/seo-audit-ru.git
cd seo-audit-ru
bash install.sh
```

### 3. Настройка токенов

Скопируйте `.env.example` и заполните своими токенами:

```bash
cp config/.env.example ~/.claude/skills/yandex-wordstat/config/.env
```

Отредактируйте файл `~/.claude/skills/yandex-wordstat/config/.env`:

```
YANDEX_WORDSTAT_TOKEN=ваш_токен_wordstat
YANDEX_WEBMASTER_TOKEN=ваш_токен_webmaster
```

### 4. (Опционально) PageSpeed API

Для данных Core Web Vitals от Google:
1. Перейдите в [Google Cloud Console](https://console.cloud.google.com/)
2. Включите **PageSpeed Insights API**
3. Создайте API-ключ
4. Добавьте в `.env`:

```
PAGESPEED_API_KEY=ваш_ключ
```

## Получение токенов Яндекса

### Яндекс Wordstat API
1. Запросите доступ: https://yandex.ru/support2/wordstat/ru/content/api-wordstat
2. Получите OAuth-токен через: `https://oauth.yandex.ru/authorize?response_type=token&client_id={ваш_client_id}`
3. Токен действует 1 год

### Яндекс Вебмастер API
1. Зарегистрируйте приложение на https://oauth.yandex.ru/
2. Получите OAuth-токен
3. Сайты должны быть верифицированы в [Яндекс Вебмастере](https://webmaster.yandex.ru/)

## Использование

```bash
# Полный аудит (Google + Яндекс)
/seo-audit-ru example.com

# Только Яндекс-часть
/seo-audit-ru example.com --yandex-only

# Быстрый режим
/seo-audit-ru example.com --quick

# Яндекс Вебмастер отдельно
/yandex-webmaster example.com
/yandex-webmaster queries example.com
/yandex-webmaster diagnostics example.com
/yandex-webmaster sqi example.com
/yandex-webmaster sites

# Яндекс Wordstat отдельно
/yandex-wordstat "ключевой запрос"
```

## Установка на Windows

Скилл использует bash-скрипты. На Windows есть два варианта: WSL (рекомендуется) и Git Bash.

### Вариант 1: WSL (рекомендуется)

#### 1. Установить WSL

В PowerShell от имени администратора:

```powershell
wsl --install
```

Перезагрузите компьютер. После перезагрузки создайте логин и пароль для Linux.

#### 2. Установить Claude Code (в WSL)

```bash
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt-get install -y nodejs curl git
npm install -g @anthropic-ai/claude-code
```

#### 3. Далее — стандартная установка

```bash
claude install-skill AgriciDaniel/claude-seo
git clone https://github.com/StepanovIgor7/seo-audit-ru.git
cd seo-audit-ru
bash install.sh
```

Заполните токены в `~/.claude/skills/yandex-wordstat/config/.env` и перезапустите Claude Code.

### Вариант 2: Git Bash

Если WSL не подходит, можно использовать [Git for Windows](https://gitforwindows.org/) (включает Git Bash с поддержкой bash + curl).

#### 1. Установить Git for Windows

Скачайте и установите с https://gitforwindows.org/

#### 2. Установить в Git Bash

```bash
# Установить зависимость claude-seo (если Claude Code доступен)
claude install-skill AgriciDaniel/claude-seo

# Клонировать и установить
git clone https://github.com/StepanovIgor7/seo-audit-ru.git
cd seo-audit-ru
bash install.sh
```

#### 3. Настроить токены

```bash
cp config/.env.example ~/.claude/skills/yandex-wordstat/config/.env
# Отредактируйте файл, добавив свои токены
```

> Git Bash поддерживает bash и curl, поэтому все скрипты будут работать без WSL.

## Требования

- [Claude Code](https://claude.ai/code) CLI
- [claude-seo](https://github.com/AgriciDaniel/claude-seo) (для Google-аудита)
- OAuth-токены Яндекс Wordstat и Вебмастер
- curl (предустановлен на macOS/Linux)
- Windows: WSL (Windows Subsystem for Linux)

## Credits

Этот проект использует и опирается на следующие открытые разработки:

- **[claude-seo](https://github.com/AgriciDaniel/claude-seo)** by AgriciDaniel — Google SEO-аудит для Claude Code (MIT License). Используется как внешняя зависимость для Google-части аудита.
- **[polyakov-claude-skills](https://github.com/artwist-polyakov/polyakov-claude-skills)** by artwist-polyakov — Яндекс Wordstat скилл для Claude Code (MIT License). Исходный код `/yandex-wordstat` включён в этот репозиторий.

## Лицензия

MIT — см. [LICENSE](LICENSE)
