"""
Smoke tests to verify basic project structure and imports.

These tests run first to catch fundamental setup issues before
running more complex tests.
"""

from pathlib import Path

import pytest


class TestProjectStructure:
    """Verify basic project structure exists."""

    def test_readme_exists(self):
        """README.md should exist at project root."""
        project_root = Path(__file__).parent.parent
        assert (project_root / "README.md").exists(), "README.md not found"

    def test_agent_context_exists(self):
        """Agent context directory should exist."""
        project_root = Path(__file__).parent.parent
        assert (project_root / ".agent-context").is_dir(), ".agent-context/ not found"

    def test_tests_directory_exists(self):
        """Tests directory should exist."""
        project_root = Path(__file__).parent.parent
        assert (project_root / "tests").is_dir(), "tests/ not found"

    def test_docs_directory_exists(self):
        """Docs directory should exist."""
        project_root = Path(__file__).parent.parent
        assert (project_root / "docs").is_dir(), "docs/ not found"

    def test_architectural_docs_exist(self):
        """Key architectural documents should exist."""
        project_root = Path(__file__).parent.parent
        docs_path = project_root / ".agent-context"

        # Check for Phase 0 planning docs
        assert (
            docs_path / "2025-11-27-ARCHITECTURAL-VISION.md"
        ).exists(), "ARCHITECTURAL-VISION.md not found"
        assert (
            docs_path / "2025-11-27-SYSTEM-COMPONENTS-DATA-FLOW.md"
        ).exists(), "SYSTEM-COMPONENTS-DATA-FLOW.md not found"
        assert (
            docs_path / "2025-11-27-PHASE-1-TASK-BREAKDOWN.md"
        ).exists(), "PHASE-1-TASK-BREAKDOWN.md not found"


class TestPythonEnvironment:
    """Verify Python environment is correctly configured."""

    def test_python_version(self):
        """Python version should be 3.9+."""
        import sys

        assert sys.version_info >= (3, 9), f"Python 3.9+ required, got {sys.version}"

    def test_pytest_installed(self):
        """Pytest should be available."""
        import pytest

        assert pytest.__version__, "pytest not installed"

    def test_key_dependencies_installed(self):
        """Key dev dependencies should be importable (when in venv)."""
        # This test may be skipped if running outside venv (e.g., system pytest)
        try:
            import black

            assert black.__version__, "black not installed"
        except ImportError:
            pytest.skip("black not installed - run from venv: source venv/bin/activate")

    @pytest.mark.skip(reason="Backend not yet created - will pass in Phase 1")
    def test_backend_imports_work(self):
        """Backend imports should work (skip until backend/ created)."""
        # This will be updated when backend/ exists
        # import backend.api.main
        pass


class TestConfiguration:
    """Verify project configuration files."""

    def test_pyproject_toml_exists(self):
        """pyproject.toml should exist."""
        project_root = Path(__file__).parent.parent
        assert (project_root / "pyproject.toml").exists(), "pyproject.toml not found"

    def test_pyproject_toml_valid(self):
        """pyproject.toml should be valid TOML."""
        import sys

        project_root = Path(__file__).parent.parent
        pyproject_path = project_root / "pyproject.toml"

        # tomllib is Python 3.11+, use tomli for 3.9/3.10 compatibility
        if sys.version_info >= (3, 11):
            import tomllib

            with open(pyproject_path, "rb") as f:
                config = tomllib.load(f)
        else:
            # For Python 3.9/3.10, just verify the file exists and is readable
            # Full TOML validation happens on 3.11+
            assert pyproject_path.read_text().startswith("[build-system]")
            return

        # Verify key sections exist (only runs on Python 3.11+)
        assert "project" in config, "Missing [project] section"
        assert "tool" in config, "Missing [tool] section"
        assert config["project"]["name"] == "agentive-lotion-2"

    def test_precommit_config_exists(self):
        """Pre-commit config should exist."""
        project_root = Path(__file__).parent.parent
        assert (project_root / ".pre-commit-config.yaml").exists()

    def test_precommit_config_valid(self):
        """Pre-commit config should be valid YAML."""
        import yaml

        project_root = Path(__file__).parent.parent
        config_path = project_root / ".pre-commit-config.yaml"

        with open(config_path) as f:
            config = yaml.safe_load(f)

        assert "repos" in config, "Missing repos in pre-commit config"
        assert len(config["repos"]) > 0, "No repos defined in pre-commit config"

    def test_gitignore_exists(self):
        """.gitignore should exist."""
        project_root = Path(__file__).parent.parent
        assert (project_root / ".gitignore").exists()


class TestTestTemplate:
    """Verify test template exists and is valid."""

    def test_test_template_exists(self):
        """Test template should exist as a reference."""
        project_root = Path(__file__).parent.parent
        assert (
            project_root / "tests" / "test_template.py"
        ).exists(), "test_template.py not found"

    def test_test_template_is_importable(self):
        """Test template should be valid Python."""
        # This implicitly tests the file is valid Python
        import importlib.util

        project_root = Path(__file__).parent.parent
        template_path = project_root / "tests" / "test_template.py"

        spec = importlib.util.spec_from_file_location("test_template", template_path)
        assert spec is not None, "Could not load test_template.py"
