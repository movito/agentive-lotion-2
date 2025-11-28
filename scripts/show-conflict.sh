#!/bin/bash
# Helper script to visualize git conflicts more clearly
# Usage: ./scripts/show-conflict.sh <file>

if [ -z "$1" ]; then
    echo "Usage: $0 <conflicted-file>"
    echo "Example: $0 pyproject.toml"
    exit 1
fi

FILE="$1"

if [ ! -f "$FILE" ]; then
    echo "Error: File not found: $FILE"
    exit 1
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔍 Conflict Analysis for: $FILE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Extract and show conflicts with colors
awk '
BEGIN {
    in_conflict = 0
    conflict_num = 0
    RED="\033[0;31m"
    GREEN="\033[0;32m"
    BLUE="\033[0;34m"
    YELLOW="\033[1;33m"
    NC="\033[0m"
}

/^<<<<<<< HEAD/ {
    in_conflict = 1
    conflict_num++
    print ""
    print YELLOW "━━━ CONFLICT #" conflict_num " ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" NC
    print GREEN "YOUR VERSION (current branch - HEAD):" NC
    next
}

/^=======/ {
    print ""
    print BLUE "THEIR VERSION (upstream/main):" NC
    next
}

/^>>>>>>> / {
    in_conflict = 0
    print YELLOW "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" NC
    print ""
    next
}

in_conflict {
    # Color the lines based on which section
    if (/^<<<<<<< HEAD/ || /^=======/ || /^>>>>>>>/) {
        next
    }

    # Print with context
    print "  " $0
}
' "$FILE"

echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "💡 Quick Commands:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo
echo "  ${GREEN}git checkout --ours $FILE${NC}     # Keep YOUR version"
echo "  ${BLUE}git checkout --theirs $FILE${NC}   # Keep THEIR version"
echo "  ${YELLOW}# Or edit manually and then:${NC}"
echo "  ${YELLOW}git add $FILE${NC}                # Mark as resolved"
echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
