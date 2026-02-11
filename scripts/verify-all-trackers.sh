#!/usr/bin/env bash
#
# Coach Script: Verify All Progress Trackers
#
# Usage: ./scripts/verify-all-trackers.sh
#
# Description: Checks if each student has created their progress tracker file.

set -euo pipefail

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║          Progress Tracker Verification                        ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Fetch all remote branches
git fetch --all --quiet

# Count total student branches
total_students=$(git branch -r | grep -c student/ || echo "0")
echo "📊 Total Students: $total_students"
echo ""

if [ "$total_students" -eq 0 ]; then
    echo "⚠️  No student branches found."
    exit 0
fi

success_count=0
missing_count=0

echo "────────────────────────────────────────────────────────────────"
printf "%-25s %-35s %-10s\n" "STUDENT" "TRACKER FILE" "STATUS"
echo "────────────────────────────────────────────────────────────────"

for branch in $(git branch -r | grep student/ | sed 's/origin\///' | sort); do
    username=$(echo "$branch" | sed 's/student\///')
    tracker="docs/workshop/PROGRESS_TRACKER_${username}.md"

    # Check if tracker exists on the branch
    if git show "origin/$branch:$tracker" > /dev/null 2>&1; then
        printf "%-25s %-35s %-10s\n" "$username" "$tracker" "✅ EXISTS"
        ((success_count++))
    else
        printf "%-25s %-35s %-10s\n" "$username" "$tracker" "❌ MISSING"
        ((missing_count++))
    fi
done

echo "────────────────────────────────────────────────────────────────"
echo ""
echo "📈 Summary:"
echo "   ✅ Trackers Found: $success_count"
echo "   ❌ Trackers Missing: $missing_count"
echo ""

if [ "$missing_count" -gt 0 ]; then
    echo "⚠️  Action Required:"
    echo "   - Contact students with missing trackers"
    echo "   - Guide them through tracker setup (see COACH_GUIDE.md)"
    exit 1
else
    echo "🎉 All students have created their progress trackers!"
    exit 0
fi
