#!/bin/bash
# Check GitHub Actions CI status for a branch
# Usage: ./scripts/verify-ci.sh [branch-name]

BRANCH="${1:-$(git branch --show-current 2>/dev/null)}"

if [ -z "$BRANCH" ]; then
    echo "❌ Could not determine branch"
    echo "Usage: ./scripts/verify-ci.sh [branch-name]"
    exit 1
fi

echo "🔍 Checking CI status for branch: $BRANCH"
echo

# Check gh CLI is available
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI (gh) not installed"
    echo "Install: https://cli.github.com/"
    exit 1
fi

# Check gh is authenticated
if ! gh auth status &> /dev/null; then
    echo "❌ GitHub CLI not authenticated"
    echo "Run: gh auth login"
    exit 1
fi

# Check gh is pointing at the right repo
EXPECTED_REPO=$(git remote get-url origin 2>/dev/null | sed 's/.*github.com[:/]//' | sed 's/.git$//')
ACTUAL_REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null)

if [ -z "$ACTUAL_REPO" ]; then
    echo "❌ Could not determine GitHub repository"
    echo "Run: gh repo set-default"
    exit 1
fi

if [ "$EXPECTED_REPO" != "$ACTUAL_REPO" ]; then
    echo "⚠️  GitHub CLI default repo mismatch!"
    echo "   Expected: $EXPECTED_REPO"
    echo "   Actual:   $ACTUAL_REPO"
    echo
    echo "Run: gh repo set-default"
    echo "Then re-run this script."
    exit 1
fi

echo "Repository: $ACTUAL_REPO"
echo

# List recent workflow runs
echo "Recent workflow runs for '$BRANCH':"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

RUNS=$(gh run list --branch "$BRANCH" --limit 5 2>&1)

if echo "$RUNS" | grep -q "no runs found"; then
    echo "No CI runs found for this branch."
    echo
    echo "This could mean:"
    echo "  1. No workflows are configured (.github/workflows/)"
    echo "  2. Branch hasn't been pushed yet"
    echo "  3. Workflows are disabled"
else
    echo "$RUNS"
fi

echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo
echo "Commands:"
echo "  Watch a run:     gh run watch <run-id>"
echo "  View run logs:   gh run view <run-id> --log"
echo "  List all runs:   gh run list"
