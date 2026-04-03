---
name: seo-audit-ru
description: >
  Комплексный SEO-аудит для российского рынка (Google + Яндекс).
  Объединяет /seo-audit (Google), /yandex-webmaster (индексация, ИКС, запросы),
  /yandex-wordstat (поисковый спрос) и Яндекс-специфичные проверки
  (robots.txt Yandex, Метрика, турбо-страницы, региональность, Справочник,
  meta robots, трекеры, Open Graph, Core Web Vitals).
  Формирует единый сводный отчёт с рекомендациями.
  Используй этот скилл когда пользователь просит аудит сайта для России,
  проверку сайта в Яндексе и Google одновременно, комплексный аудит,
  или любой SEO-аудит русскоязычного сайта.
  Triggers: СЕО аудит, SEO аудит РФ, аудит сайта Россия, полный аудит,
  аудит Google и Яндекс, комплексный аудит, seo-audit-ru,
  проверить сайт для России, аудит под Яндекс, проверить сайт,
  SEO проверка, аудит сайта, проверка SEO сайта.
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
| `/seo-audit-ru <домен> --quick` | Быстрый режим: только Яндекс-проверки + CWV, без полного Google-аудита |
| `/seo-audit-ru <домен> --spravochnik` | Только проверка Яндекс.Справочника: карточка, NAP, schema, виджеты, гео-сигналы |

## Execution

### Определение режима

- **Полный** (по умолчанию): Фазы 1A + 1B + 1C + 1D → Фаза 2 → Фаза 3
- **--yandex-only**: Пропустить 1A (Google-аудит). Всё остальное выполнить.
- **--quick**: Выполнить только 1C (yandex_checks.sh) + 1B (summary.sh + queries.sh). Пропустить 1A и остальные скрипты Вебмастера. Отчёт — короткая сводка без детального Google-аудита.
- **--spravochnik**: Выполнить ТОЛЬКО расширенную проверку Справочника. Пропустить все остальные фазы. Запустить `spravochnik_check.sh` и сформировать отчёт по шаблону «Справочник».

### Фаза 1: Параллельный сбор данных

Run ALL of the following in parallel:

**1A. Google SEO аудит** (пропустить при `--yandex-only` и `--quick`):

Spawn Agent with subagent_type `seo-audit`:
```
Prompt: "Run /seo-audit for https://<domain>. Return the full audit report."
```

**1B. Яндекс Вебмастер** — run bash scripts in parallel:
```bash
bash ~/.claude/skills/yandex-webmaster/scripts/summary.sh <domain>
bash ~/.claude/skills/yandex-webmaster/scripts/diagnostics.sh <domain>
bash ~/.claude/skills/yandex-webmaster/scripts/queries.sh <domain> TOTAL_SHOWS 20
bash ~/.claude/skills/yandex-webmaster/scripts/sqi_history.sh <domain>
bash ~/.claude/skills/yandex-webmaster/scripts/links.sh <domain>
bash ~/.claude/skills/yandex-webmaster/scripts/sitemaps.sh <domain>
```

При `--quick` запустить только `summary.sh` и `queries.sh`.

If domain is not in Yandex Webmaster (script returns error), skip Webmaster data and note this in the report.

**Пустые indicators в запросах**: API Вебмастера иногда возвращает queries с пустыми `indicators: {}` (без показов, кликов, CTR, позиции). Это НЕ ошибка — так API может отдавать данные при запросе сортировки по TOTAL_SHOWS за короткий период. В отчёте показывать список запросов без числовых колонок и пометить: «показы/клики/позиции недоступны через API». Для получения числовых данных попробовать queries.sh с параметром `TOTAL_CLICKS` или за более длинный период.

**1C. Яндекс-специфичные проверки**:
```bash
bash ~/.claude/skills/seo-audit-ru/scripts/yandex_checks.sh <domain>
```

**1D. PageSpeed CWV** (если CWV данные не получены из yandex_checks.sh):
```bash
source ~/.claude/skills/yandex-wordstat/config/.env && curl -s "https://www.googleapis.com/pagespeedonline/v5/runPagespeed?url=https://<domain>&key=${GOOGLE_PSI_KEY}&strategy=mobile&category=performance"
```

### Режим --spravochnik (отдельная проверка Справочника)

При `--spravochnik` пропустить все фазы выше. Выполнить только:

```bash
bash ~/.claude/skills/seo-audit-ru/scripts/spravochnik_check.sh <domain>
```

Parse JSON и сформировать отчёт по шаблону:

```markdown
# Яндекс.Справочник: {домен}
*Дата: {дата}*

## Тип бизнеса
- Определён как: локальный / федеральный / мультилокация
- Основание: (какие сигналы обнаружены)

## Карточка в Яндекс.Картах
- Найдена: да/нет
- Название: ...

## Ссылки на Яндекс.Карты на сайте
- Есть: да/нет
- URL: ...

## NAP (Name, Address, Phone)
- Телефонов найдено: X
- Адрес на сайте: есть/нет
- Email: есть/нет

## Schema.org бизнес-разметка
- Тип: LocalBusiness / Organization / нет
- Полнота: полная / частичная / отсутствует

## Виджет Яндекс.Бизнес
- Обнаружен: да/нет

## Гео-сигналы
- geo.region: значение или "не задан"
- geo.placename: значение или "не задан"
- geo.position: значение или "не задан"
- ICBM: значение или "не задан"

## Страница контактов
- Найдена: да/нет
- Путь: ...

## Рекомендации
1. ...
```

### Определение типа бизнеса перед рекомендациями

Перед формированием рекомендаций определи тип бизнеса по сигналам на сайте:

| Сигнал | Локальный | Федеральный/онлайн |
|--------|-----------|-------------------|
| Телефон 8-800 | — | да |
| Только городской номер | да | — |
| «Доставка по всей России» / «Работаем по всей РФ» | — | да |
| Несколько филиалов в разных городах | мультилокация | — |
| Только онлайн-услуги (издательство, SaaS, обучение) | — | да |
| Физический шоурум / офис для посетителей | да | — |

Если не удаётся определить — спросить пользователя.

### Рекомендации по типу бизнеса

**Локальный бизнес (кафе, магазин, клиника, салон):**
- Карточка в Справочнике — обязательна, это ключевой фактор локального ранжирования
- Schema: `@type: "LocalBusiness"` (или подтип: Restaurant, Store, MedicalClinic)
- geo.region / geo.placename мета-теги — добавить
- Регион в Вебмастере — указать город
- Ссылка на карточку с сайта — обязательна
- Виджет Яндекс.Бизнес с отзывами — рекомендуется

**Федеральный / онлайн бизнес (SaaS, издательство, e-commerce на всю РФ):**
- Карточка в Справочнике — оставить если есть (trust-сигнал), но НЕ акцентировать гео-привязку
- Schema: `@type: "Organization"` с `"areaServed": {"@type": "Country", "name": "Россия"}`
- geo.region мета-теги — **НЕ ставить** (привяжет к одному городу, ослабит федеральную видимость)
- Регион в Вебмастере — «Россия» (не город!)
- В карточке Справочника → «Территория обслуживания: вся Россия»
- На сайте указать: «Работаем по всей России»
- Ссылка на карточку — по желанию, не критично
- Виджет Яндекс.Бизнес — не приоритет

**Мультилокация (сеть филиалов):**
- Отдельная карточка в Справочнике для каждого филиала
- Schema: `@type: "LocalBusiness"` с массивом `location` или отдельные страницы филиалов
- geo мета-теги — на страницах филиалов (не на главной)
- Регион в Вебмастере — «Россия»

**ВАЖНО: Верификация через WebSearch.** Скрипт не может надёжно детектировать карточку в Яндекс.Картах (SPA с JS-рендерингом). Если `yandex_maps_search.found = false`, ОБЯЗАТЕЛЬНО выполни WebSearch: `"<домен> site:yandex.ru/maps OR site:yandex.com/maps"` для проверки. Яндекс.Карты = Яндекс.Справочник — это одна система.

---

### Фаза 1E: Верификация мета-тегов на ключевых страницах

Диагностика Вебмастера (`DOCUMENTS_MISSING_DESCRIPTION`, `DOCUMENTS_MISSING_TITLE`) — агрегированная проблема по ВСЕМУ сайту. Она не означает, что мета-теги отсутствуют на конкретных коммерческих страницах.

**Обязательно**: после Фазы 1B-1C, выполни WebFetch на 3-5 ключевых страниц сайта и извлеки:
- `<title>`, `<meta name="description">`, `<link rel="canonical">`
- `<meta name="robots">` (noindex/nofollow — осознанное решение, не ошибка!)
- Open Graph теги, viewport, lang

```
WebFetch https://<domain>/vak (или главная коммерческая страница)
→ Извлеки: title, meta description, canonical, robots, OG
```

**Правила:**
- Если мета-тег есть на странице — НЕ писать «отсутствует», даже если Вебмастер показывает PRESENT по сайту
- Если `<meta name="robots" content="noindex, nofollow">` — страница осознанно закрыта. Указать в отчёте как факт, не как проблему. Проверить есть ли альтернативный URL
- Проблема `MISSING_DESCRIPTION: PRESENT` → указать что она относится к другим страницам сайта (блог, архив, авторы), а не к коммерческим лендингам (если на них description есть)
- В секции «Диагностика Яндекса» отчёта — указать какие именно разделы затронуты (проверить через WebFetch 2-3 страниц блога/архива)

**Пример ошибки** (не повторять): Вебмастер показал `MISSING_DESCRIPTION: PRESENT` для nauchforum.ru. Мы написали «нет meta description на /vak». Но на /vak description есть + canonical + noindex. Проблема — на страницах блога и архива.

---

### Правила верификации (обязательные — усвоены из обратной связи SEO-специалиста)

Эти правила предотвращают повторение 17 ошибок, обнаруженных при проверке аудита sibac.info.

**V1: Не доверяй API-данным о битых ссылках буквально**
Вебмастер API сообщает N битых ссылок → перед тем как писать «N = CRITICAL», проверь выборку 5-10 URL через `curl -sI URL` (HTTP-статус). Многие «битые» URL отдают HTTP 200 с noindex — это рабочие страницы, не 404. В отчёте: «Вебмастер: N ссылок, выборочная проверка: X% реальных 404».

**V2: Используй только реальные URL сайта**
НЕ конструируй URL из параметров (`/conf?science=pedagogy`). Проверь реальную URL-структуру через sitemap, навигацию или WebFetch главной. Если проверяешь canonical/meta — используй URL, которые реально существуют.

**V3: Проверяй разметку через curl, не только WebFetch**
WebFetch не всегда отдаёт `<head>`. Для проверки meta/canonical/schema:
```bash
curl -sL https://domain.com/page | head -80 | grep -iE 'meta name="(description|robots)"'
curl -sL https://domain.com/page | grep -iE 'rel="canonical"'
curl -sL https://domain.com/page | grep -iE 'itemtype|application/ld\+json'
```
Если BreadcrumbList/Article/canonical обнаружены (Microdata или JSON-LD) — НЕ рекомендовать «добавить».

**V4: Не рекомендуй разметку на noindex-страницы**
Если страница закрыта `noindex, nofollow` — ScholarlyArticle, FAQ, Event и прочие Schema бессмысленны. Сначала проверь: `curl -sL URL | grep 'noindex'`. Если noindex → не рекомендуй разметку.

**V5: Контекст РФ-рынка (2026)**
- GA4: не приоритет если Google Ads не работает в РФ, а Метрика видит Google-трафик
- Host в robots.txt: полностью не работает в Яндексе (не «deprecated, но работает»)
- Турбо-страницы: технология отключена Яндексом — не рекомендовать
- llms.txt: ни один крупный AI-провайдер не подтвердил использование. LOW приоритет
- Self-referencing canonical на чистых URL: избыточен, создаёт риск конфликтов. Рекомендовать только на параметрических URL (?page=, ?sort=) и пагинации

**V6: Проверяй www-редирект правильно**
`curl -I https://www.domain.com` может отдать 200 для Claude, но 301 для Googlebot (User-Agent зависимый редирект). Не пиши «www не редиректит» без проверки с `curl -I -H "User-Agent: Googlebot"`.

**V7: Не давай шаблонных рекомендаций без проверки**
- FAQ schema → сначала проверь, есть ли FAQ-контент на сайте
- ScholarlyArticle → сначала проверь, индексируются ли статьи (noindex?)
- BreadcrumbList → проверь Microdata, не только JSON-LD: `grep -i 'itemtype.*BreadcrumbList'`
- Страница «О нас» → поищи по разным URL: /about, /o-nas, /o-kompanii, /o-sibak, /about-us
- Авторские страницы → проверь трафик перед рекомендацией «noindex». Они могут приносить 60K+ визитов

**V8: E-E-A-T — не занижай без полной проверки**
Перед оценкой найди ВСЕ сигналы доверия: юрлицо (ИНН/ОГРН), регистрация СМИ, лицензия контента, рецензенты с учёными степенями, годы работы, объём портфолио, оферта, способы оплаты. Не снижай оценку за отсутствие того, что не проверил. Для научного издательства с 16+ годами, 80K+ статей, 60K+ внешних ссылок с вузов — E-E-A-T не может быть 5/10.

---

### Фаза 2: Дополнительные проверки (пропустить при --quick)

Run these ONLY if triggered by Phase 1 findings:

| Условие | Действие |
|---------|----------|
| Обнаружен hreflang или `/en/` раздел | Spawn Agent `seo-hreflang` для аудита мультиязычности |
| Нужен детальный анализ спроса | Spawn Agent `yandex-wordstat` по ТОП-5 запросам из Вебмастера |
| E-E-A-T сигналы слабые | Spawn Agent `seo-content` для детального анализа |

### Фаза 3: Формирование отчёта

Parse all JSON results. For CWV data from PageSpeed API: LCP и TTFB — в миллисекундах (разделить на 1000 для секунд), CLS — percentile (разделить на 100 для десятичного значения, напр. 10 → 0.10), INP — в миллисекундах.

Present a unified report in the following structure.

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
(если indicators пустые — показать только список запросов и пометить «числовые данные недоступны через API»)

### Диагностика
Таблица проблем по уровням: FATAL > CRITICAL > POSSIBLE_PROBLEM > RECOMMENDATION
Для PRESENT-проблем (MISSING_DESCRIPTION, MISSING_TITLE) — указать какие именно разделы затронуты (верифицировано через WebFetch в Фазе 1E), а не писать «на всех страницах»

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
- Карточка организации: найдена/не найдена (из yandex_checks.sh → yandex_spravochnik.detected)
- Ссылки на Яндекс.Карты на сайте: есть/нет

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
| **Вебмастер: MISSING_DESCRIPTION/TITLE = PRESENT** | Это проблема САЙТА в целом, не конкретной страницы. Верифицируй ключевые страницы через WebFetch (Фаза 1E). Не пиши «нет meta description на /vak» если он там есть |
| **Страница с noindex, nofollow** | Это осознанное решение, не ошибка. Проверь альтернативный URL для того же контента. В отчёте указать как факт, не как проблему |
| **Geo-теги для федерального бизнеса** | Если сайт — федеральный/онлайн (8-800, «вся Россия», SaaS, издательство) — НЕ рекомендовать geo.region с городом. Это ослабит федеральную видимость. Регион в Вебмастере = «Россия» |
| **Битые ссылки из Вебмастера** | API сообщает N → проверить выборку 5-10 URL через `curl -sI`. Многие отдают 200+noindex, не 404 |
| **Canonical на чистых URL** | Self-referencing canonical избыточен. Рекомендовать только для параметрических URL и пагинации |
| **Schema на noindex-страницах** | ScholarlyArticle, FAQ, Event бессмысленны на закрытых страницах. Проверить noindex |
| **GA4 для РФ-сайта** | Метрика видит Google-трафик. Google Ads не работает в РФ. Не HIGH приоритет |
| **Host в robots.txt** | Полностью не работает в Яндексе. Не «deprecated, но работает» |
| **Турбо-страницы** | Технология отключена Яндексом. Не рекомендовать |
| **www-редирект** | curl может показать 200, а Googlebot видит 301. Проверять с `-H "User-Agent: Googlebot"` |

## Config

- Yandex tokens: `~/.claude/skills/yandex-wordstat/config/.env`
- PageSpeed API key: `GOOGLE_PSI_KEY` in the same .env file (or `PAGESPEED_API_KEY` env var)
- Yandex Webmaster scripts: `~/.claude/skills/yandex-webmaster/scripts/`
- Yandex checks script: `~/.claude/skills/seo-audit-ru/scripts/yandex_checks.sh`
- Spravochnik check script: `~/.claude/skills/seo-audit-ru/scripts/spravochnik_check.sh`
