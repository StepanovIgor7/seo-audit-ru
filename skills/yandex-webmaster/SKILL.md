---
name: yandex-webmaster
description: |
  Данные из Яндекс Вебмастера: индексация, ИКС (SQI), поисковые запросы,
  внешние ссылки, битые ссылки, диагностика, сайтмапы, переобход страниц.
  Используй когда нужно: проверить индексацию в Яндексе, узнать ИКС,
  посмотреть по каким запросам сайт показывается в Яндексе,
  найти проблемы сайта, отправить страницу на переиндексацию.
  Triggers: Яндекс Вебмастер, индексация Яндекс, ИКС, SQI,
  запросы в Яндексе, диагностика Яндекс, переобход, recrawl Яндекс,
  yandex webmaster, проблемы сайта в Яндексе.
---

# yandex-webmaster

Retrieve site data from Yandex Webmaster API v4: indexing, SQI, search queries, links, diagnostics, sitemaps, recrawl.

## Config

Uses `YANDEX_WEBMASTER_TOKEN` from `~/.claude/skills/yandex-wordstat/config/.env`.

## Commands

The user invokes this skill as `/yandex-webmaster <command> <domain>`.

### Available commands

| Command | Description |
|---------|-------------|
| `/yandex-webmaster <domain>` | Full overview: SQI, indexing stats, top problems, top-10 queries |
| `/yandex-webmaster sites` | List all verified sites in the account |
| `/yandex-webmaster queries <domain>` | TOP search queries (shows, clicks, position) |
| `/yandex-webmaster indexing <domain>` | Indexing history and page samples |
| `/yandex-webmaster links <domain>` | External backlinks + broken internal links |
| `/yandex-webmaster diagnostics <domain>` | Site problems by severity |
| `/yandex-webmaster sitemaps <domain>` | Sitemap status |
| `/yandex-webmaster sqi <domain>` | SQI (ИКС) history |
| `/yandex-webmaster recrawl <full_url>` | Submit URL for recrawl + show quota |

## Execution Steps

### Step 1: Verify API connection

```bash
bash ~/.claude/skills/yandex-webmaster/scripts/get_user.sh
```

If this returns an error, the token may be expired. Tell the user to refresh it.

### Step 2: Execute the appropriate script

Based on the user's command, run the corresponding script:

**Full overview** (`/yandex-webmaster <domain>`):
```bash
bash ~/.claude/skills/yandex-webmaster/scripts/summary.sh <domain>
bash ~/.claude/skills/yandex-webmaster/scripts/diagnostics.sh <domain>
bash ~/.claude/skills/yandex-webmaster/scripts/queries.sh <domain> TOTAL_SHOWS 10
```

**List sites** (`/yandex-webmaster sites`):
```bash
bash ~/.claude/skills/yandex-webmaster/scripts/list_hosts.sh
```

**Search queries** (`/yandex-webmaster queries <domain>`):
```bash
bash ~/.claude/skills/yandex-webmaster/scripts/queries.sh <domain> TOTAL_SHOWS 100
```

**Indexing** (`/yandex-webmaster indexing <domain>`):
```bash
bash ~/.claude/skills/yandex-webmaster/scripts/indexing.sh <domain>
```

**Links** (`/yandex-webmaster links <domain>`):
```bash
bash ~/.claude/skills/yandex-webmaster/scripts/links.sh <domain>
```

**Diagnostics** (`/yandex-webmaster diagnostics <domain>`):
```bash
bash ~/.claude/skills/yandex-webmaster/scripts/diagnostics.sh <domain>
```

**Sitemaps** (`/yandex-webmaster sitemaps <domain>`):
```bash
bash ~/.claude/skills/yandex-webmaster/scripts/sitemaps.sh <domain>
```

**SQI history** (`/yandex-webmaster sqi <domain>`):
```bash
bash ~/.claude/skills/yandex-webmaster/scripts/sqi_history.sh <domain>
```

**Recrawl** (`/yandex-webmaster recrawl <url>`):
Extract domain from URL, then:
```bash
bash ~/.claude/skills/yandex-webmaster/scripts/recrawl.sh <domain> <full_url>
```

### Step 3: Parse and present results

All scripts return JSON. Parse the JSON and present results in a clear, structured format:

- Use tables for lists (queries, links, sitemaps)
- Highlight problems by severity: FATAL > CRITICAL > POSSIBLE_PROBLEM > RECOMMENDATION
- For SQI history, show trend (growing/declining/stable)
- For queries, show: query text, impressions, clicks, CTR, average position
- For the full overview, summarize key metrics at the top

### Step 4: Provide actionable recommendations

Based on the data, suggest:
- Which problems to fix first (by severity)
- Pages that need recrawl after fixes
- Queries where the site is close to TOP-10 (positions 11-20) — growth opportunities
- Broken links that should be fixed

### Предупреждения при интерпретации данных (из обратной связи SEO-специалиста)

**Битые ссылки (links.sh):** API может сообщить N тысяч «битых» ссылок. Но многие из этих URL отдают HTTP 200 с `noindex` — это рабочие страницы, не реальные 404. Перед тем как писать «N битых ссылок = CRITICAL», проверь выборку 5-10 URL через `curl -sI URL`. В отчёте: «Вебмастер сообщает N ссылок, выборочная проверка показала X% реальных 404».

**DOCUMENTS_MISSING_DESCRIPTION:** Это агрегированная проблема САЙТА, не конкретной страницы. Коммерческие страницы могут иметь meta description, а проблема — на архивных/авторских. Проверяй конкретные URL через `curl -sL URL | head -50 | grep 'meta name="description"'`.

**Количество страниц в индексе:** При `searchable_pages_count=0` и `sqi > 0` — это rate limit API, не реальный ноль. Подожди 5 сек и повтори.

## Error Handling

- **401 Unauthorized**: Token expired. User needs to get a new one at https://oauth.yandex.ru/
- **403 Forbidden**: Site not verified or no access. User must verify ownership in Yandex Webmaster.
- **404 Not Found**: Site not added to Webmaster. User needs to add it first.
- **429 Too Many Requests**: Rate limit hit. Wait and retry.

## Cache

The skill caches `user_id` and `host_id` in `~/.claude/skills/yandex-webmaster/cache/`.
To clear cache: `rm ~/.claude/skills/yandex-webmaster/cache/user_id ~/.claude/skills/yandex-webmaster/cache/host_*`

## API Reference

Base URL: `https://api.webmaster.yandex.net/v4/`
Auth: `Authorization: OAuth <token>`
Docs: https://yandex.ru/dev/webmaster/
