#!/usr/bin/env bash
#
# Coach Script: Bulk PR Review Helper
#
# Usage: ./scripts/bulk-pr-check.sh
#
# Description: Interactive script to review all pending workshop PRs.
# For each PR, it checks out the branch, runs validation, and optionally
# opens the PR for review.

set -euo pipefail

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo "❌ Error: GitHub CLI (gh) is not installed."
    echo "   Install it from: https://cli.github.com/"
    exit 1
fi

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║          Bulk PR Review Helper                                ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Get list of pending workshop PRs
echo "🔍 Fetching pending workshop PRs..."
pr_list=$(gh pr list --label "workshop" --state open --json number --jq '.[].number' 2>/dev/null || echo "")

if [ -z "$pr_list" ]; then
    echo "✅ No pending workshop PRs to review!"
    exit 0
fi

pr_count=$(echo "$pr_list" | wc -l)
echo "📊 Found $pr_count pending PR(s)"
echo ""

current=0

for pr_number in $pr_list; do
    ((current++))
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "PR $current/$pr_count: #$pr_number"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # Show PR details
    gh pr view "$pr_number" --json number,title,author,createdAt,additions,deletions \
        --template '{{printf "Title: %s\n" .title}}{{printf "Author: %s\n" .author.login}}{{printf "Created: %s\n" .createdAt}}{{printf "Changes: +%d -%d\n" .additions .deletions}}'
    echo ""

    # Ask if user wants to checkout and validate
    read -rp "📥 Checkout and validate this PR? [y/N] " -n 1
    echo ""

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "🔄 Checking out PR #$pr_number..."
        gh pr checkout "$pr_number"

        echo "🧪 Running workshop validation..."
        if ./scripts/workshop-check.sh final; then
            echo "✅ Validation PASSED"
        else
            echo "❌ Validation FAILED"
        fi
        echo ""

        # Ask if user wants to run build and tests
        read -rp "🏗️  Run build and tests? [y/N] " -n 1
        echo ""

        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "🔨 Building..."
            if make build; then
                echo "✅ Build PASSED"
            else
                echo "❌ Build FAILED"
            fi

            echo "🧪 Testing..."
            if make test; then
                echo "✅ Tests PASSED"
            else
                echo "❌ Tests FAILED"
            fi
        fi
        echo ""

        # Ask if user wants to review now
        read -rp "👀 Open PR for review in browser? [y/N] " -n 1
        echo ""

        if [[ $REPLY =~ ^[Yy]$ ]]; then
            gh pr view "$pr_number" --web
        fi

        # Ask if user wants to approve/request changes/comment
        echo ""
        echo "Actions:"
        echo "  1) Approve"
        echo "  2) Request changes"
        echo "  3) Add comment"
        echo "  4) Skip (review later)"
        read -rp "Select action [1-4]: " -n 1 action
        echo ""
        echo ""

        case $action in
            1)
                read -rp "Approval comment: " comment
                gh pr review "$pr_number" --approve --body "$comment"
                echo "✅ PR #$pr_number approved!"
                ;;
            2)
                read -rp "Change request comment: " comment
                gh pr review "$pr_number" --request-changes --body "$comment"
                echo "🔄 Changes requested for PR #$pr_number"
                ;;
            3)
                read -rp "Comment: " comment
                gh pr comment "$pr_number" --body "$comment"
                echo "💬 Comment added to PR #$pr_number"
                ;;
            4)
                echo "⏭️  Skipped PR #$pr_number"
                ;;
            *)
                echo "Invalid option. Skipping."
                ;;
        esac
    else
        echo "⏭️  Skipped PR #$pr_number"
    fi

    echo ""
done

# Return to main branch
echo "🔙 Returning to main branch..."
git checkout main

echo ""
echo "✅ Bulk PR review complete!"
echo "   Reviewed: $pr_count PR(s)"
