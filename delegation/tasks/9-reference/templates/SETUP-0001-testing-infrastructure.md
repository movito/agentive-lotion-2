# [PREFIX]-0001: CI/CD and TDD Infrastructure Setup

<!--
ONBOARDING AGENT: When creating this task, replace:
- [PREFIX] with the project's task prefix (e.g., AL2, PROJ)
- [DATE] with today's date (YYYY-MM-DD)
- [PROJECT-NAME] with the project name
- Remove language sections that don't apply
- Customize requirements based on project architecture
- DELETE THIS COMMENT BLOCK after customization
-->

**Status**: Todo
**Priority**: critical
**Assigned To**: feature-developer
**Estimated Effort**: 3-4 hours
**Created**: [DATE]
**Phase**: 0 (Foundation - blocks all other work)

## Overview

Set up the testing and CI/CD infrastructure for [PROJECT-NAME] so that all future development follows Test-Driven Development (TDD) practices. This foundational task **must be completed before any feature implementation** begins.

**Why this matters**: TDD catches bugs early, documents expected behavior, and makes refactoring safe. Setting this up first ensures good habits from day one and prevents accumulating untested code.

**Why feature-developer**: Planner coordinates and assigns tasks. Feature-developer implements infrastructure code. This is an implementation task.

## Existing Assets to Leverage

The starter kit includes these files - **adapt them, don't replace**:

| File | Status | Action |
|------|--------|--------|
| `tests/test_template.py` | ✅ Exists | Use as reference for test patterns |
| `.pre-commit-config.yaml` | ✅ Exists | Adapt (remove starter-kit specific hooks) |
| `tests/` directory | ✅ Exists | Add project-specific tests here |
| `pyproject.toml` | ❌ Missing | Create for Python projects |
| `.github/workflows/ci.yml` | ❌ Missing | Create CI workflow |

## Requirements

### Must Have
- [ ] **Pre-flight verification**: Run verification script before starting
- [ ] **Python config**: Create `pyproject.toml` with pytest, black, ruff configuration
- [ ] **Virtual environment**: Set up and document (`python -m venv venv`)
- [ ] **Adapt pre-commit**: Update `.pre-commit-config.yaml` (remove starter-kit references)
- [ ] **Install hooks**: Run `pre-commit install`
- [ ] **Smoke test**: Create `tests/test_smoke.py` to verify project structure
- [ ] **CI workflow**: Create `.github/workflows/ci.yml`
- [ ] **Documentation**: Create `docs/TESTING.md`

### Should Have
- [ ] Test coverage reporting configured (>70% target)
- [ ] Pre-commit runs fast tests (<30 seconds)
- [ ] CI provides clear failure messages

### Nice to Have
- [ ] Coverage badge in README
- [ ] Test results summary in CI output

## Pre-Flight Verification (MANDATORY)

⚠️ **STOP**: Do not proceed with implementation until all pre-flight checks pass.

### Step 0: Create Verification Script

Create `scripts/verify-setup.sh`:

```bash
#!/bin/bash
# Pre-flight verification for TDD infrastructure setup

echo "🔍 Verifying prerequisites..."
echo

ERRORS=0

# Check Python version
echo "Checking Python version..."
if python3 --version 2>/dev/null | grep -qE "Python 3\.(9|1[0-9])"; then
    echo "✅ Python 3.9+ detected"
else
    echo "❌ Python 3.9+ required"
    ERRORS=$((ERRORS + 1))
fi

# Check git configuration
echo "Checking git configuration..."
if git config user.name > /dev/null 2>&1 && git config user.email > /dev/null 2>&1; then
    echo "✅ Git configured"
else
    echo "❌ Git not configured"
    echo "   Run: git config --global user.name \"Your Name\""
    echo "   Run: git config --global user.email \"you@example.com\""
    ERRORS=$((ERRORS + 1))
fi

# Verify project structure
echo "Checking project structure..."
for item in "README.md" ".agent-context" "tests"; do
    if [ -e "$item" ]; then
        echo "✅ $item exists"
    else
        echo "❌ $item not found"
        ERRORS=$((ERRORS + 1))
    fi
done

# Check existing files
echo "Checking existing assets..."
[ -f "tests/test_template.py" ] && echo "✅ tests/test_template.py exists" || echo "⚠️  tests/test_template.py missing (will create)"
[ -f ".pre-commit-config.yaml" ] && echo "✅ .pre-commit-config.yaml exists" || echo "⚠️  .pre-commit-config.yaml missing"

# Summary
echo
if [ $ERRORS -eq 0 ]; then
    echo "✅ All prerequisites met! Ready to proceed."
    exit 0
else
    echo "❌ $ERRORS prerequisite(s) failed. Fix before proceeding."
    exit 1
fi
```

Make executable and run:

```bash
mkdir -p scripts
chmod +x scripts/verify-setup.sh
./scripts/verify-setup.sh
```

**If verification fails**, STOP and fix issues before proceeding to Step 1.

## Implementation Steps

### Step 1: Create `pyproject.toml`

```toml
[build-system]
requires = ["setuptools>=61.0"]
build-backend = "setuptools.build_meta"

[project]
name = "[PROJECT-NAME]"
version = "0.1.0"
requires-python = ">=3.9"
dependencies = [
    # Add your project dependencies here
]

[project.optional-dependencies]
dev = [
    "pytest>=7.4.0",
    "pytest-cov>=4.1.0",
    "pytest-asyncio>=0.21.0",
    "black>=23.12.0",
    "ruff>=0.1.0",
    "pre-commit>=3.5.0",
]

[tool.pytest.ini_options]
testpaths = ["tests"]
python_files = ["test_*.py"]
addopts = ["-v", "--strict-markers", "--tb=short"]
markers = [
    "slow: marks tests as slow (deselect with '-m \"not slow\"')",
    "integration: integration tests requiring external services",
]

[tool.black]
line-length = 88
target-version = ["py39", "py310", "py311"]

[tool.ruff]
line-length = 88
select = ["E", "F", "I", "N", "W"]

[tool.coverage.run]
source = ["src"]  # Adjust to your source directory
omit = ["tests/*", "venv/*"]

[tool.coverage.report]
exclude_lines = [
    "pragma: no cover",
    "if TYPE_CHECKING:",
    "raise NotImplementedError",
]
```

**Error Handling:**

| Error | Cause | Solution |
|-------|-------|----------|
| `toml syntax error` | Invalid TOML format | Validate with `python -c "import tomllib; tomllib.load(open('pyproject.toml', 'rb'))"` |
| `Invalid version specifier` | Wrong dependency format | Use `package>=X.Y.Z` format |

**Verification:**
```bash
python3 -c "import tomllib; tomllib.load(open('pyproject.toml', 'rb'))" && echo "✅ Valid TOML"
```

---

### Step 2: Set Up Virtual Environment

```bash
# Create virtual environment
python3 -m venv venv

# Activate (Mac/Linux)
source venv/bin/activate

# Activate (Windows)
# venv\Scripts\activate

# Install project with dev dependencies
pip install -e ".[dev]"
```

**Error Handling:**

| Error | Cause | Solution |
|-------|-------|----------|
| `venv creation failed` | Permissions or disk space | Check permissions, free disk space |
| `No module named pip` | pip not installed | `python3 -m ensurepip --upgrade` |
| `pip install fails` | Network or Python version | Check internet; verify Python 3.9+ |
| `Command not found: pytest` | venv not activated | Run `source venv/bin/activate` |

**Verification:**
```bash
which python  # Should show: .../venv/bin/python
pytest --version && echo "✅ pytest installed"
black --version && echo "✅ black installed"
```

---

### Step 3: Adapt `.pre-commit-config.yaml`

Review the existing file and:
- Remove any project-specific hooks from the starter kit
- Keep: black, isort/ruff, flake8, basic file checks
- Simplify pytest hook (remove hardcoded paths)

**Replace the pytest hook with:**

```yaml
  - repo: local
    hooks:
      - id: pytest-check
        name: Run fast tests
        entry: bash -c 'if [ "$SKIP_TESTS" = "1" ]; then echo "⚠️ Skipping tests"; exit 0; fi; pytest tests/ -v -x -m "not slow" --maxfail=3'
        language: system
        pass_filenames: false
        always_run: true
        stages: [pre-commit]
```

**Error Handling:**

| Error | Cause | Solution |
|-------|-------|----------|
| `YAML parsing error` | Bad indentation | Use 2-space indentation; validate with `python -c "import yaml; yaml.safe_load(open('.pre-commit-config.yaml'))"` |
| `Hook not found` | Removed hook still referenced | Ensure old hooks fully deleted |
| `black: command not found` | venv not activated | Activate venv first |

**Verification:**
```bash
python3 -c "import yaml; yaml.safe_load(open('.pre-commit-config.yaml'))" && echo "✅ Valid YAML"
```

---

### Step 4: Create Smoke Test

Create `tests/test_smoke.py`:

```python
"""Smoke tests to verify project structure and basic setup."""
import pytest
from pathlib import Path


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


class TestPythonEnvironment:
    """Verify Python environment is correctly configured."""

    def test_python_version(self):
        """Python version should be 3.9+."""
        import sys
        assert sys.version_info >= (3, 9), f"Python 3.9+ required, got {sys.version}"

    def test_pytest_installed(self):
        """Pytest should be available."""
        assert pytest.__version__, "pytest not installed"


class TestConfiguration:
    """Verify project configuration files."""

    def test_pyproject_toml_exists(self):
        """pyproject.toml should exist."""
        project_root = Path(__file__).parent.parent
        assert (project_root / "pyproject.toml").exists(), "pyproject.toml not found"

    def test_precommit_config_exists(self):
        """Pre-commit config should exist."""
        project_root = Path(__file__).parent.parent
        assert (project_root / ".pre-commit-config.yaml").exists()
```

**Error Handling:**

| Error | Cause | Solution |
|-------|-------|----------|
| `ModuleNotFoundError: pytest` | venv not activated | `source venv/bin/activate` |
| `Test failed: README.md not found` | Wrong directory | `cd` to project root |
| `AssertionError` | Missing file/directory | Verify project structure |

**Verification:**
```bash
pytest tests/test_smoke.py -v
# All tests should PASS
```

---

### Step 5: Create GitHub Actions CI

Create `.github/workflows/ci.yml`:

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    name: Test Python ${{ matrix.python-version }}
    runs-on: ubuntu-latest
    strategy:
      matrix:
        python-version: ["3.9", "3.11"]

    steps:
      - uses: actions/checkout@v4

      - name: Set up Python ${{ matrix.python-version }}
        uses: actions/setup-python@v5
        with:
          python-version: ${{ matrix.python-version }}

      - name: Install dependencies
        run: |
          python -m pip install --upgrade pip
          pip install -e ".[dev]"

      - name: Run tests with coverage
        run: pytest tests/ -v --cov --cov-report=term-missing

      - name: Check code formatting
        run: |
          black --check .
          ruff check .

  lint:
    name: Lint
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: "3.11"

      - name: Install linters
        run: pip install black ruff

      - name: Run black
        run: black --check --diff .

      - name: Run ruff
        run: ruff check .
```

**Error Handling:**

| Error | Cause | Solution |
|-------|-------|----------|
| `YAML syntax error` | Invalid structure | Use GitHub Actions syntax validator |
| `Directory not found` | Missing `.github/workflows/` | `mkdir -p .github/workflows` |
| `Tests pass locally, fail in CI` | Environment differences | Check Python version matrix |

**Verification:**
```bash
mkdir -p .github/workflows
ls .github/workflows/ci.yml && echo "✅ CI workflow created"
```

---

### Step 6: Install Pre-commit Hooks

```bash
# Install hooks
pre-commit install

# Test on all files
pre-commit run --all-files
```

**Error Handling:**

| Error | Cause | Solution |
|-------|-------|----------|
| `pre-commit: command not found` | Not installed | `pip install pre-commit` |
| `Hook failed: black` | Formatting issues | Run `black .` to auto-fix |
| `Hook failed: pytest-check` | Tests failing | Fix tests or use `SKIP_TESTS=1 git commit -m "WIP"` |

**Verification:**
```bash
ls .git/hooks/pre-commit && echo "✅ Hooks installed"
pre-commit run --all-files && echo "✅ All hooks pass"
```

---

### Step 7: Create Testing Documentation

Create `docs/TESTING.md`:

```markdown
# Testing Guide

## Quick Start

```bash
# Run all tests
pytest tests/ -v

# Run fast tests only (skip slow)
pytest tests/ -v -m "not slow"

# Run with coverage
pytest tests/ --cov --cov-report=html
open htmlcov/index.html
```

## TDD Workflow (Red-Green-Refactor)

1. **RED**: Write a failing test first
2. **GREEN**: Write minimum code to pass
3. **REFACTOR**: Improve while keeping tests green

## Writing Tests

Use `tests/test_template.py` as reference. Follow AAA pattern:

```python
def test_example():
    # Arrange: Set up test data
    input_data = {"key": "value"}

    # Act: Call the function
    result = function_to_test(input_data)

    # Assert: Verify the result
    assert result["status"] == "success"
```

## Pre-commit Hooks

Hooks run automatically before each commit:
- Code formatting (black)
- Linting (ruff)
- Fast tests

**Skip tests for WIP commits:**
```bash
SKIP_TESTS=1 git commit -m "WIP: work in progress"
```

## CI/CD

Tests run automatically on push via GitHub Actions.
View results: https://github.com/[org]/[repo]/actions

## Coverage Targets

- New code: >80% coverage
- Overall: >70% coverage
- Critical paths: >90% coverage
```

**Verification:**
```bash
mkdir -p docs
ls docs/TESTING.md && echo "✅ Documentation created"
```

---

## Acceptance Criteria

### Core Setup
- [ ] Pre-flight verification passes (`./scripts/verify-setup.sh`)
- [ ] `pytest tests/ -v` runs successfully
- [ ] `pre-commit run --all-files` passes
- [ ] GitHub Actions CI workflow exists and runs on push

### Configuration
- [ ] `pyproject.toml` exists with complete config
- [ ] Virtual environment documented
- [ ] `.pre-commit-config.yaml` adapted
- [ ] Pre-commit hooks installed

### Documentation
- [ ] `docs/TESTING.md` created
- [ ] TDD process documented

### Quality Gates
- [ ] Pre-commit runs in <30 seconds
- [ ] CI workflow completes in <3 minutes
- [ ] All tests pass on Python 3.9 and 3.11

## Success Metrics

**Quantitative**:
- Smoke test runs in <1 second
- Pre-commit hooks complete in <30 seconds
- CI workflow completes in <3 minutes

**Qualitative**:
- Developers can write tests following template
- TDD workflow is clear and documented
- CI failures are actionable

## Dependencies

**Blocks** (cannot start until this completes):
- All feature implementation tasks
- Backend/frontend project structure tasks

**Blocked By**:
- None (foundational task)

---

## Implementation Notes (For feature-developer)

### ✅ DO:
- Run pre-flight verification first (Step 0 is MANDATORY)
- Follow steps sequentially (1-7)
- Use error tables for troubleshooting
- Verify each step before proceeding
- Test pre-commit hooks thoroughly

### ❌ DON'T:
- Skip pre-flight verification
- Assume directories exist without checking
- Ignore verification commands
- Proceed if smoke tests fail

### Quality Assurance:
- All 7 steps include error handling tables
- Pre-flight script catches common issues early
- Verification commands confirm each step worked

### After Completion:
Ensure all subsequent feature tasks include:
- Test requirements section
- TDD workflow (Red-Green-Refactor)
- Coverage targets (80%+ for new code)

---

**Template Version**: 3.0.0
**Purpose**: First task for new projects to establish TDD practices
