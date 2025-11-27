#!/bin/bash
# Pre-flight verification for TDD infrastructure setup
# Task: AL2-0001

set -e  # Exit on first error

echo "🔍 Verifying prerequisites for AL2-0001..."
echo

# Check Python version
echo "Checking Python version..."
python3 --version | grep -q "Python 3\.\(9\|1[0-9]\)" || {
    echo "❌ Python 3.9+ required"
    exit 1
}
echo "✅ Python 3.9+ detected"

# Check git configuration
echo "Checking git configuration..."
git config user.name > /dev/null && git config user.email > /dev/null || {
    echo "❌ Git not configured"
    echo "   Run: git config --global user.name \"Your Name\""
    echo "   Run: git config --global user.email \"you@example.com\""
    exit 1
}
echo "✅ Git configured"

# Verify project structure
echo "Checking project structure..."
[ -f "README.md" ] || { echo "❌ README.md not found"; exit 1; }
[ -d ".agent-context" ] || { echo "❌ .agent-context/ not found"; exit 1; }
[ -d "tests" ] || { echo "❌ tests/ directory not found"; exit 1; }
echo "✅ Project structure valid"

# Check if venv already exists
if [ -d "venv" ]; then
    echo "⚠️  venv/ already exists - will be reused"
else
    echo "✅ Ready to create venv/"
fi

# Check if pyproject.toml exists
if [ -f "pyproject.toml" ]; then
    echo "⚠️  pyproject.toml already exists - will be overwritten"
else
    echo "✅ Ready to create pyproject.toml"
fi

# Verify required directories exist (or can be created)
echo "Verifying required directories..."
for dir in "tests" ".agent-context" "docs" "scripts" "delegation/tasks"; do
    if [ ! -d "$dir" ]; then
        echo "⚠️  Directory not found: $dir"
        echo "   Creating $dir..."
        mkdir -p "$dir" || {
            echo "❌ Failed to create $dir"
            exit 1
        }
        echo "✅ Created $dir"
    else
        echo "✅ $dir exists"
    fi
done

echo
echo "✅ All prerequisites met! Ready to proceed with setup."
