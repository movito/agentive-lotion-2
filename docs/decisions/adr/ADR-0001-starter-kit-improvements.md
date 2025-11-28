# ADR-0001: Agentive Starter Kit Configuration Improvements

**Status**: Proposed
**Date**: 2025-11-27
**Author**: feature-developer
**Context**: AL2-0001 CI/CD and TDD Infrastructure Setup

## Summary

During the implementation of AL2-0001 (CI/CD and TDD Infrastructure Setup), several configuration issues were encountered that required adaptation and troubleshooting. This ADR documents these issues and proposes improvements for future versions of the agentive-starter-kit.

## Context

The agentive-starter-kit is designed to provide a production-ready foundation for new projects. However, new projects have different requirements than the source project (thematic-cuts), requiring adaptation during setup. The goal should be minimal friction when starting a new project.

## Problems Encountered

### 1. Missing `pyproject.toml`

**Problem**: No `pyproject.toml` was included in the starter kit, requiring creation from scratch.

**Impact**: 15+ minutes to configure pytest, black, ruff, and dependencies correctly.

**Recommendation**: Include a generic `pyproject.toml` with:
- Placeholder project name (`your-project-name`)
- Dev dependencies pre-configured (pytest, black, ruff, pre-commit)
- Tool configurations ready to use
- Empty `packages = []` to prevent setuptools auto-discovery errors

### 2. Setuptools Auto-Discovery Conflict

**Problem**: Without explicit package configuration, setuptools discovers `agents/` and `delegation/` as Python packages, causing pip install failures:

```
error: Multiple top-level packages discovered in a flat-layout: ['agents', 'delegation']
```

**Impact**: 10+ minutes debugging and adding `[tool.setuptools] packages = []`.

**Recommendation**: Include in `pyproject.toml`:
```toml
[tool.setuptools]
# New projects add their packages here when they create src code
# Prevents auto-discovery of non-Python directories
packages = []
```

### 3. Hardcoded Paths in Pre-commit Config

**Problem**: `.pre-commit-config.yaml` contained hardcoded paths from thematic-cuts:
- `./venv/bin/pytest` instead of just `pytest`
- `scripts/pre-commit-validate-tasks.sh` (doesn't exist in starter kit)

**Impact**: Pre-commit hooks fail until paths are fixed.

**Recommendation**: Use system PATH resolution:
```yaml
entry: bash -c '... pytest tests/ ...'  # No ./venv/bin/ prefix
```
And remove project-specific hooks or make them optional.

### 4. Project-Specific Pre-commit Hooks

**Problem**: The `validate-tasks` hook references a script that doesn't exist in the starter kit:
```yaml
entry: bash scripts/pre-commit-validate-tasks.sh
```

**Impact**: Pre-commit fails with "file not found".

**Recommendation**: Either:
- Remove project-specific hooks from starter kit
- Or include stub scripts that pass (with TODO comments)
- Or document which hooks to remove during setup

### 5. Missing Scripts Directory

**Problem**: `scripts/` directory doesn't exist but is referenced in pre-commit config.

**Impact**: Pre-flight verification and hook scripts need directory created.

**Recommendation**: Include `scripts/` directory with:
- `.gitkeep` or README explaining purpose
- Stub for `verify-setup.sh` (or include full pre-flight script)

### 6. Trailing Whitespace and Line Endings

**Problem**: Several starter kit files (agents/preflight, agents/onboarding, .claude/agents/*.md) have trailing whitespace.

**Impact**: Pre-commit hooks modify files on first run, creating unnecessary changes.

**Recommendation**: Run pre-commit hooks on starter kit files before releasing:
```bash
pre-commit run --all-files
```

### 7. Inconsistent Naming in Comments/Headers

**Problem**: `.pre-commit-config.yaml` references "Thematic Cuts" in header.

**Impact**: Confusion about which project the config is for.

**Recommendation**: Use generic naming: "Your Project Name" or "{{PROJECT_NAME}}" placeholder.

### 8. GitHub CLI Defaults to Upstream Repo

**Problem**: After cloning from starter kit, `gh` CLI defaults to the upstream repo instead of the new project's origin.

**Impact**: `gh run list`, `gh pr create`, and other commands fail or operate on wrong repo. CI-checker agent fails to find workflows.

**Recommendation**: Add to onboarding script:
```bash
gh repo set-default <new-repo-name>
```
Or document this in README Quick Start section.

## Proposed Starter Kit Changes

### High Priority (Must Have)

1. **Add `pyproject.toml`** with:
   ```toml
   [project]
   name = "your-project-name"  # Change this
   version = "0.1.0"
   dependencies = []  # Add runtime deps as needed

   [project.optional-dependencies]
   dev = [
       "pytest>=7.4.0",
       "pytest-cov>=4.1.0",
       "black>=23.12.0",
       "ruff>=0.1.0",
       "pre-commit>=3.5.0",
   ]

   [tool.setuptools]
   packages = []  # Add your packages when you create them

   [tool.pytest.ini_options]
   testpaths = ["tests"]
   markers = ["slow: marks tests as slow"]
   ```

2. **Fix `.pre-commit-config.yaml`**:
   - Remove hardcoded `./venv/bin/` paths
   - Remove or stub project-specific hooks
   - Update header comment to generic name

3. **Create `scripts/` directory** with README or pre-flight script

4. **Run pre-commit on starter kit** to fix whitespace issues

### Medium Priority (Should Have)

5. **Add generic smoke test** (`tests/test_smoke.py`) that validates:
   - Project structure (README, .agent-context, tests)
   - Python version
   - Core dependencies installed

6. **Add CI workflow template** (`.github/workflows/ci.yml`) with:
   - Python matrix (3.9, 3.11)
   - Test and lint jobs
   - Step-level error reporting

### Low Priority (Nice to Have)

7. **Add `docs/TESTING.md` template** with TDD workflow documentation

8. **Document setup steps** in README explicitly:
   - venv creation
   - pip install -e ".[dev]"
   - pre-commit install
   - Initial test run

## Implementation Checklist

For the starter kit maintainer:

- [ ] Create generic `pyproject.toml` with all tool configs
- [ ] Fix pre-commit config (remove hardcoded paths, project-specific hooks)
- [ ] Create `scripts/` directory with README
- [ ] Run `pre-commit run --all-files` and commit fixes
- [ ] Add generic smoke test
- [ ] Add CI workflow template
- [ ] Update README with development setup section
- [ ] Test clean setup on fresh clone

## Decision

Implement the "High Priority" changes in the next starter kit release. These changes will reduce setup time from 1-2 hours to ~15 minutes by eliminating common friction points.

## Consequences

**Positive**:
- New projects can run `pip install -e ".[dev]"` immediately
- Pre-commit hooks work out of the box
- Less confusion from project-specific references
- Faster onboarding for new developers

**Negative**:
- Existing projects using the starter kit need to handle merge conflicts
- Generic configurations may need project-specific tuning

## Notes

This ADR is based on actual setup experience during AL2-0001 implementation. All problems were encountered and resolved during the task. The recommendations are practical and tested.
