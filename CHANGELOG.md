# Changelog

Все заметные изменения в проекте документируются в этом файле.

Формат основан на [Keep a Changelog](https://keepachangelog.com/ru/1.0.0/),
проект следует [Semantic Versioning](https://semver.org/lang/ru/).

## [Unreleased]

### Планируется

- Интеграция с DataForSEO для автоматического анализа SERP
- Шаблоны отчётов в XLSX-формате
- Поддержка мультисайтового аудита (пакетный режим)
- Кэширование результатов API-запросов между фазами

## [1.1.0] — 2026-03-31

### Добавлено

- CI/CD pipeline (`.github/workflows/ci.yml`):
  - Валидация структуры скилла и SKILL.md frontmatter
  - Сканирование секретов (Google API keys, Yandex OAuth/IAM tokens, пароли)
  - Проверка .gitignore на полноту
  - Верификация что yandex_checks.sh — read-only (нет POST/PUT/DELETE)
  - Проверка обновления CHANGELOG.md в PR
- Тесты:
  - `tests/test_yandex_checks.sh` — 30+ bash-тестов:
    - Наличие и исполняемость скрипта
    - Валидация аргументов (ошибка без домена)
    - Безопасность: нет hardcoded ключей, нет eval, нет деструктивных команд
    - curl только GET/HEAD
    - Очистка временных файлов
    - Все 8 обязательных JSON-ключей и подключи
    - Live-тест на example.com с валидацией JSON
  - `tests/test_skill_structure.py` — 25+ Python-тестов (pytest):
    - Наличие обязательных файлов
    - SKILL.md frontmatter (name, description, allowed-tools, user-invokable)
    - Секции контента (фазы, отчёт, обработка ошибок)
    - Безопасность скрипта (нет hardcoded secrets, eval, деструктивных rm)
    - Формат CHANGELOG.md (Keep a Changelog)
    - Полнота .gitignore
- `.gitignore` — защита от коммита чувствительных файлов
- `CHANGELOG.md` — журнал изменений (этот файл)

### Безопасность

- CI автоматически сканирует каждый push/PR на утечки API-ключей и токенов
- Тесты проверяют что скрипт не может отправлять данные (только чтение)
- Тесты проверяют отсутствие dangerous patterns (eval, rm -rf /)

## [1.0.0] — 2026-03-29

### Добавлено

- Основной `SKILL.md` с описанием, триггерами и workflow аудита
- 3 фазы аудита:
  - Фаза 1: Параллельный сбор данных (Google SEO, Яндекс Вебмастер, yandex_checks.sh, PageSpeed)
  - Фаза 2: Условные проверки (hreflang, Wordstat, E-E-A-T)
  - Фаза 3: Формирование сводного отчёта
- `scripts/yandex_checks.sh` — Яндекс-специфичные проверки:
  - robots.txt для Yandex (секция, Clean-param, Host, Crawl-delay, Sitemap)
  - Яндекс Метрика (установка, ID счётчика)
  - Турбо-страницы (обнаружение)
  - Региональность (geo.region, geo.placename, geo.position)
  - Трекеры (VK Pixel, Top.Mail.ru, Roistat, Google Analytics)
  - Open Graph (og:title, og:description, og:image)
  - Meta robots по разделам (/, /blog, /about, /contacts)
  - Core Web Vitals через PageSpeed API (LCP, INP, CLS, TTFB)
- Структура отчёта: Сводка Google vs Яндекс, ТОП-10 проблем, детали по секциям
- Обработка ошибок: домен не найден, истёкший токен, таймауты, rate limits
- Интеграция с навыками: seo-audit, yandex-webmaster, yandex-wordstat, seo-hreflang, seo-content
