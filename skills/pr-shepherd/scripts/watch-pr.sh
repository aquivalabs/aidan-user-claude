#!/usr/bin/env bash
# Usage: watch-pr.sh <pr-number>
# Prints one line per change (base tip, merge state, failed check) and exits when the PR is no longer open.
# Silence means nothing has changed.
set -u
pr=${1:?usage: watch-pr.sh <pr-number>}
interval=60
prev=""

while true; do
  view=$(gh pr view "$pr" --json state,mergeStateStatus,baseRefName 2>/dev/null)
  if [ -z "$view" ]; then sleep "$interval"; continue; fi

  state=$(jq --raw-output .state <<<"$view")
  if [ "$state" != OPEN ]; then echo "PR $state"; exit 0; fi

  base=$(jq --raw-output .baseRefName <<<"$view")
  base_sha=$(gh api "repos/{owner}/{repo}/commits/$base" --jq .sha 2>/dev/null)
  if [ -z "$base_sha" ]; then sleep "$interval"; continue; fi

  # gh pr checks exits non-zero while checks are pending or failed, so read its output, not its status.
  checks=$(gh pr checks "$pr" --json name,bucket 2>/dev/null)
  [ -n "$checks" ] || checks='[]'

  current=$(
    {
      echo "base moved: $base_sha"
      echo "merge state: $(jq --raw-output .mergeStateStatus <<<"$view")"
      jq --raw-output '.[] | select(.bucket == "fail") | "check failed: \(.name)"' <<<"$checks"
    } | sort
  )

  comm -13 <(echo "$prev") <(echo "$current")
  prev=$current
  sleep "$interval"
done
