---
name: seo-audit-ru
description: >
  Комплексный SEO-аудит для российского рынка (Google + Яндекс).
  Объединяет /seo-audit (Google), /yandex-webmaster (индексация, ИКС, запросы),
  /yandex-wordstat (поисковый спрос) и Яндекс-специфичные проверки
  (robots.txt Yandex, Метрика, турбо-страницы, региональность, Справочник,
  meta robots, трекеры, Open Graph, Core Web Vitals).
  Формирует единый сводный отчёт с рекомендациями.
  Triggers: СЕО аудит, SEO аудит РФ, аудит сайта Россия, полный аудит,
  аудит Google и Яндекс, комплексный аудит, seo-audit-ru,
  проверить сайт для России, аудит под Яндекс.
user-invokable: true
argument-hint: "<domain>"
allowed-tools:
  - Read
  - Grep
  - Glob
  - Bash
  - WebFetch
  - WebSearch
  - Agent
---

# SEO-аудит РФ: Google + Яндекс

Комплексный SEO-аудит, объединяющий Google-аудит и данные Яндекса в единый отчёт.

## Commands

| Команда | Описание |
|---------|----------|
| `/seo-audit-ru <домен>` | Полный аудит (Google + Яндекс + специфичные проверки) |
| `/seo-audit-ru <домен> --yandex-only` | Только Яндекс-часть (без Google-аудита) |
| `/seo-audit-ru <домен> --quick` | Быстрый режим: только сводка без детального Google-аудита |

## Execution

### Фаза 1: Параллельный сбор данных

Run ALL of the following in parallel:

**1A. Google SEO аудит** — spawn Agent with subagent_type `seo-audit`:
```
Prompt: "Run /seo-audit for https://<domain>. Return the full audit report."
```
Skip this if user passed `--yandex-only`.

**1B. Яндекс Вебмастер** — run bash scripts in parallel:
```bash
bash ~/.claude/skills/yandex-webmaster/scripts/summary.sh <domain>
bash ~/.claude/skills/yandex-webmaster/scripts/diagnostics.sh <domain>
bash ~/.claude/skills/yandex-webmaster/scripts/queries.sh <domain> TOTAL_SHOWS 20
bash ~/.claude/skills/yandex-webmaster/scripts/sqi_history.sh <domain>
bash ~/.claude/skills/yandex-webmaster/scripts/links.sh <domain>
bash ~/.claude/skills/yandex-webmaster/scripts/sitemaps.sh <domain>
```

NOTE: If domain is not in Yandex Webmaster (script returns error), skip Webmaster data and note this in the report.

**1C. Яндекс-специфичные проверки** — run inline:
```bash
bash ~/.claude/skills/seo-audit-ru/scripts/yandex_checks.sh <domain>
```

**1D. PageSpeed CWV** (if not already in yandex_checks.sh output):
```bash
source ~/.claude/skills/yandex-wordstat/config/.env && curl -s "https://www.googleapis.com/pagespeedonline/v5/runPagespeed?url=https://<domain>&key=${GOOGLE_PSI_KEY}&strategy=mobile&category=performance"
```

### Фаза 2: Дополнительные проверки (условные)

Run these ONLY if triggered by Phase 1 findings:

| Условие | Действие |
|---------|----------|
| Обнаружен hreflang или `/en/` раздел | Spawn Agent `seo-hreflang` для аудита мультиязычности |
| Нужен детальный анализ спроса | Spawn Agent `yandex-wordstat` по ТОП-5 запросам из Вебмастера |
| E-E-A-T сигналы слабые | Spawn Agent `seo-content` для детального анализа |

### Фаза 3: Формирование отчёта

Parse all JSON results and present a unified report in the following structure.

## Report Structure

```markdown
# SEO-аудит (Google + Яндекс): {домен}
*Дата: {дата}*

---

## Сводка

| Метрика | Google | Яндекс |
|---------|--------|--------|
| Health Score | XX/100 | — |
| Страниц в индексе | (из аудита) | (из Вебмастера) |
| ИКС (SQI) | — | XXX |
| LCP | X.X сек | — |
| INP | XXX мс | — |
| CLS | X.XX | — |
| TTFB | X.X сек | — |
| Core Web Vitals | pass/fail | — |
| Проблем найдено | X | X |

---

## ТОП-10 проблем

Объединить и приоритизировать проблемы из обоих источников:
- **Critical**: блокирует индексацию или вызывает санкции
- **High**: значительно влияет на ранжирование
- **Medium**: возможность для оптимизации
- **Low**: бэклог

---

## Google SEO

### Technical SEO
(из /seo-audit: crawlability, indexability, security, CWV, JS rendering)

### Content Quality
(из /seo-audit: E-E-A-T, thin content, readability)

### Schema / Structured Data
(из /seo-audit: detection, validation, recommendations)

### Images
(из /seo-audit: alt text, sizes, formats)

### AI Search Readiness (GEO)
(из /seo-audit: AI crawler access, llms.txt, citability)

### Performance
(из /seo-audit + PageSpeed API: LCP, INP, CLS, TTFB)

---

## Яндекс SEO

### ИКС и динамика
- Текущий ИКС: XXX
- Тренд за 90 дней: растёт/стабильно/падает
- История: мин → макс

### Индексация
- Страниц в поиске: XXX
- Исключённых: XXX
- Соотношение с сайтмапом

### Поисковые запросы (ТОП-20)
Таблица: запрос | показы | клики | CTR | позиция

### Диагностика
Таблица проблем по уровням: FATAL > CRITICAL > POSSIBLE_PROBLEM > RECOMMENDATION

### Внешние ссылки
- Количество: XXX
- ТОП доноров

### Битые внутренние ссылки
- Количество: XXX
- Основные паттерны

### Сайтмапы
Таблица: URL | ошибок | страниц

---

## Яндекс-специфичные проверки

### robots.txt для Yandex
- Секция User-agent: Yandex: есть/нет
- Clean-param: настроен/нет
- Host: указан/нет
- Crawl-delay: установлен/нет
- Sitemap: указан/нет

### Яндекс Метрика
- Установлена: да/нет
- ID счётчика: XXXXXXXX

### Турбо-страницы
- Обнаружены: да/нет

### Региональность
- geo.region: значение или "не задан"
- geo.placename: значение или "не задан"

### Яндекс.Справочник
- Карточка организации: найдена/не найдена

### meta robots по разделам
Таблица: раздел | директива | комментарий

### Трекеры и аналитика
Таблица: трекер | установлен

### Open Graph
- og:title: есть/нет
- og:description: есть/нет
- og:image: есть/нет

---

## Сравнение видимости Google vs Яндекс

Краткий анализ: где сайт сильнее, где слабее, какие запросы покрыты только в одном поисковике.

---

## Рекомендации

### Critical (исправить немедленно)
1. ...

### High (в течение недели)
1. ...

### Medium (в течение месяца)
1. ...

### Low (бэклог)
1. ...
```

## Error Handling

| Ситуация | Действие |
|----------|----------|
| Домен не найден в Яндекс Вебмастере | Пропустить Webmaster-данные, отметить в отчёте. Яндекс-специфичные проверки (curl) всё равно выполнить. |
| Токен Яндекса истёк (401) | Сообщить пользователю: обновить токен в `~/.claude/skills/yandex-wordstat/config/.env` |
| /seo-audit не завершился (таймаут) | Использовать данные из yandex_checks.sh (CWV, meta robots) как замену Google-части |
| PageSpeed API не ответил | Отметить "CWV: данные недоступны" |
| Сайт недоступен (DNS/connection error) | Прервать аудит, сообщить пользователю |
| **Яндекс API rate limit** (searchable_pages_count=0 при sqi>0, или count=0 запросов при sqi>200) | Скрипты summary.sh и queries.sh автоматически повторят запрос через 5 сек (webmaster_get_safe / webmaster_get_queries_safe). Если нули сохраняются — отметить в отчёте как «данные не получены (API rate limit)», НЕ писать «0 страниц» или «0 запросов» как факт |
| **Аудит нескольких сайтов в одной сессии** | Между сайтами добавлять паузу 3-5 сек (`rate_limit_pause` из common.sh). Яндекс API возвращает HTTP 200 с нулевыми данными при превышении лимита — стандартных заголовков X-RateLimit нет |

## Config

- Yandex tokens: `~/.claude/skills/yandex-wordstat/config/.env`
- PageSpeed API key: hardcoded in `yandex_checks.sh` (can be overridden via env)
- Yandex Webmaster scripts: `~/.claude/skills/yandex-webmaster/scripts/`
- Yandex checks script: `~/.claude/skills/seo-audit-ru/scripts/yandex_checks.sh`
