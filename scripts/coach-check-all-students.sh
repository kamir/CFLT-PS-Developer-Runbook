#!/usr/bin/env bash
#
# Coach Script: Check All Student Activity
#
# Usage: ./scripts/coach-check-all-students.sh
#
# Description: Generates a report of all student branch activity including
# last commit, last activity time, and commit count.

set -euo pipefail

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║          Student Activity Report                              ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "Generated: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# Fetch all remote branches
echo "🔄 Fetching latest branch information..."
git fetch --all --quiet

# Count total student branches
total_students=$(git branch -r | grep -c student/ || echo "0")
echo "📊 Total Students: $total_students"
echo ""

if [ "$total_students" -eq 0 ]; then
    echo "⚠️  No student branches found."
    echo "   Make sure students have created their branches: student/<username>"
    exit 0
fi

echo "────────────────────────────────────────────────────────────────"
printf "%-20s %-15s %-40s %-15s\n" "STUDENT" "COMMITS" "LAST COMMIT" "LAST ACTIVITY"
echo "────────────────────────────────────────────────────────────────"

# Loop through each student branch
for branch in $(git branch -r | grep student/ | sed 's/origin\///' | sort); do
    username=$(echo "$branch" | sed 's/student\///')

    # Get commit count
    commit_count=$(git rev-list --count "origin/$branch" 2>/dev/null || echo "0")

    # Get last commit message (truncated)
    last_commit=$(git log --oneline --max-count=1 "origin/$branch" 2>/dev/null | cut -c 1-40 || echo "No commits")

    # Get last activity (relative time)
    last_activity=$(git log --format="%ar" --max-count=1 "origin/$branch" 2>/dev/null || echo "Never")

    # Format output
    printf "%-20s %-15s %-40s %-15s\n" "$username" "$commit_count" "$last_commit" "$last_activity"
done

echo "────────────────────────────────────────────────────────────────"
echo ""
echo "💡 Tips:"
echo "   - Students with low commit counts may need assistance"
echo "   - Check if any students haven't pushed in > 24 hours"
echo "   - Use './scripts/verify-all-trackers.sh' to check progress trackers"
echo ""
