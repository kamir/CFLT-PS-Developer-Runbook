#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
learners_dir="$root_dir/learners"

ask_required() {
  local prompt="$1"
  local var
  while true; do
    printf "%s " "$prompt"
    IFS= read -r var
    if [[ -n "${var// }" ]]; then
      printf "%s" "$var"
      return 0
    fi
    echo "Please provide a non-empty answer."
  done
}

now_utc="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

echo "Student Intake - First Actions"

echo
handle="$(ask_required "GitHub handle (or preferred identifier):")"

goal="$(ask_required "1) Primary goal for this workshop (1-2 sentences):")"
role="$(ask_required "2) Current role/context (team, product, workload):")"
exp="$(ask_required "3) Kafka/Confluent experience:")"
constraints="$(ask_required "4) Local environment constraints (OS, permissions, VPN, proxies):")"
outcome="$(ask_required "5) Expected outcome by end of workshop:")"
success="$(ask_required "6) What would make this workshop a success for you:")"

student_dir="$learners_dir/$handle"
state_file="$student_dir/learners-state.md"
review_file="$student_dir/coach-review.md"

mkdir -p "$student_dir"

cat <<EOF_STATE > "$state_file"
# Learner State

- Handle: $handle
- Collected (UTC): $now_utc

## Primary Goal
$goal

## Current Role / Context
$role

## Kafka / Confluent Experience
$exp

## Local Environment Constraints
$constraints

## Expected Outcome
$outcome

## Success Criteria
$success
EOF_STATE

if [[ ! -f "$review_file" ]]; then
  cat <<EOF_REVIEW > "$review_file"
# Coach Review

- Handle: $handle
- Review Date (UTC):

## Summary

## Risks / Gaps

## Recommended Next Step
EOF_REVIEW
fi

echo
printf "Saved: %s\n" "$state_file"
printf "Review template: %s\n" "$review_file"
