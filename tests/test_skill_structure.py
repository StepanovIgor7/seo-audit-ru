"""
Тесты структуры и целостности скилла seo-audit-ru.

Запуск:
    python -m pytest tests/test_skill_structure.py -v
    python -m pytest tests/ -v
"""

import os
import re
import yaml

SKILL_DIR = os.path.join(os.path.dirname(__file__), "..")


class TestRequiredFiles:
    """Все необходимые файлы существуют."""

    REQUIRED = [
        "SKILL.md",
        "CHANGELOG.md",
        "scripts/yandex_checks.sh",
        "tests/test_yandex_checks.sh",
        "tests/test_skill_structure.py",
        ".github/workflows/ci.yml",
        ".gitignore",
    ]

    def test_all_required_files_exist(self):
        for filepath in self.REQUIRED:
            full = os.path.join(SKILL_DIR, filepath)
            assert os.path.exists(full), f"Missing: {filepath}"

    def test_script_is_executable(self):
        script = os.path.join(SKILL_DIR, "scripts", "yandex_checks.sh")
        assert os.access(script, os.X_OK), "yandex_checks.sh is not executable"

    def test_test_script_is_executable(self):
        script = os.path.join(SKILL_DIR, "tests", "test_yandex_checks.sh")
        assert os.access(script, os.X_OK), "test_yandex_checks.sh is not executable"


class TestSkillFrontmatter:
    """SKILL.md имеет корректный YAML frontmatter."""

    def _load_frontmatter(self) -> dict:
        path = os.path.join(SKILL_DIR, "SKILL.md")
        with open(path, "r", encoding="utf-8") as f:
            content = f.read()
        match = re.match(r"^---\n(.*?)\n---", content, re.DOTALL)
        assert match, "SKILL.md missing YAML frontmatter"
        return yaml.safe_load(match.group(1))

    def test_has_name(self):
        fm = self._load_frontmatter()
        assert "name" in fm
        assert fm["name"] == "seo-audit-ru"

    def test_has_description(self):
        fm = self._load_frontmatter()
        assert "description" in fm
        assert len(fm["description"]) > 20

    def test_has_allowed_tools(self):
        fm = self._load_frontmatter()
        assert "allowed-tools" in fm
        assert isinstance(fm["allowed-tools"], list)
        assert len(fm["allowed-tools"]) >= 3

    def test_is_user_invokable(self):
        fm = self._load_frontmatter()
        assert fm.get("user-invokable") is True

    def test_has_argument_hint(self):
        fm = self._load_frontmatter()
        assert "argument-hint" in fm


class TestSkillContent:
    """SKILL.md содержит необходимые секции."""

    def _load_content(self) -> str:
        path = os.path.join(SKILL_DIR, "SKILL.md")
        with open(path, "r", encoding="utf-8") as f:
            return f.read()

    def test_has_execution_phases(self):
        content = self._load_content()
        assert "Фаза 1" in content
        assert "Фаза 2" in content
        assert "Фаза 3" in content

    def test_has_report_structure(self):
        content = self._load_content()
        assert "Report Structure" in content or "Структура отчёта" in content

    def test_has_error_handling(self):
        content = self._load_content()
        assert "Error Handling" in content or "Обработка ошибок" in content

    def test_references_yandex_checks_script(self):
        content = self._load_content()
        assert "yandex_checks.sh" in content

    def test_references_webmaster_scripts(self):
        content = self._load_content()
        assert "yandex-webmaster" in content


class TestScriptSecurity:
    """Скрипт yandex_checks.sh не содержит секретов и опасных паттернов."""

    def _load_script(self) -> str:
        path = os.path.join(SKILL_DIR, "scripts", "yandex_checks.sh")
        with open(path, "r", encoding="utf-8") as f:
            return f.read()

    def test_no_hardcoded_google_api_key(self):
        source = self._load_script()
        assert not re.search(r"AIza[A-Za-z0-9_-]{35}", source), \
            "Hardcoded Google API key found"

    def test_no_hardcoded_yandex_token(self):
        source = self._load_script()
        matches = re.findall(r"y[0-3]_[A-Za-z0-9_-]{35,}", source)
        for m in matches:
            assert "example" in m.lower() or "placeholder" in m.lower(), \
                f"Possible hardcoded Yandex token: {m[:20]}..."

    def test_no_eval_on_variables(self):
        source = self._load_script()
        assert not re.search(r"eval\s+.*\$", source), \
            "Dangerous eval on variable found"

    def test_no_destructive_rm(self):
        source = self._load_script()
        assert not re.search(r"rm\s+-rf\s+/", source), \
            "Dangerous rm -rf / pattern found"

    def test_curl_is_readonly(self):
        """curl не отправляет данные — только GET/HEAD."""
        source = self._load_script()
        assert not re.search(
            r"curl.*(-d |--data |--data-raw |--data-binary |-X POST|-X PUT|-X DELETE)",
            source
        ), "curl should be read-only"

    def test_tmpfile_cleanup(self):
        source = self._load_script()
        assert 'rm -f "$TMPFILE"' in source, \
            "Temp file should be cleaned up"

    def test_api_key_from_env(self):
        source = self._load_script()
        assert "PAGESPEED_API_KEY" in source or "GOOGLE_PSI_KEY" in source, \
            "API key should be loaded from environment"


class TestChangelog:
    """CHANGELOG.md имеет корректный формат."""

    def _load_changelog(self) -> str:
        path = os.path.join(SKILL_DIR, "CHANGELOG.md")
        with open(path, "r", encoding="utf-8") as f:
            return f.read()

    def test_has_changelog(self):
        path = os.path.join(SKILL_DIR, "CHANGELOG.md")
        assert os.path.exists(path)

    def test_has_unreleased_section(self):
        content = self._load_changelog()
        assert "[Unreleased]" in content

    def test_has_version_entries(self):
        content = self._load_changelog()
        assert re.search(r"\[[\d.]+\]", content), \
            "CHANGELOG should have at least one version entry"

    def test_follows_keepachangelog(self):
        content = self._load_changelog()
        # Проверяем наличие стандартных секций
        has_standard_sections = any(
            section in content
            for section in ["### Added", "### Changed", "### Fixed",
                          "### Добавлено", "### Изменено", "### Исправлено"]
        )
        assert has_standard_sections, \
            "CHANGELOG should use Keep a Changelog sections"


class TestGitignore:
    """.gitignore покрывает чувствительные файлы."""

    def _load_gitignore(self) -> str:
        path = os.path.join(SKILL_DIR, ".gitignore")
        with open(path, "r", encoding="utf-8") as f:
            return f.read()

    def test_ignores_env(self):
        gi = self._load_gitignore()
        assert ".env" in gi

    def test_ignores_secrets(self):
        gi = self._load_gitignore()
        assert "secret" in gi.lower() or "token" in gi.lower()
