#!/usr/bin/env bash
# Usage: watch-pr.sh <pr-number> [--resume]
# Prints one line per change (base tip, merge state, failed check) and exits when the PR is no longer open.
# Silence means nothing has changed. If gh keeps failing, prints "gh failing: <error>" and exits.
# --resume continues from the last run's state instead of reporting the current state afresh.
set -u
pr=${1:?usage: watch-pr.sh <pr-number> [--resume]}
interval=60
max_failures=5
failures=0
state_file="$(git rev-parse --git-common-dir)/pr-shepherd-$pr.state"
prev=""
if [ "${2:-}" = --resume ] && [ -f "$state_file" ]; then prev=$(cat "$state_file"); fi
err=$(mktemp)
trap 'rm -f "$err"' EXIT

# Retries a blip; a persistent failure exits loudly so it can't pass for silence.
gh_failed() {
  failures=$((failures + 1))
  if [ "$failures" -ge "$max_failures" ]; then
    echo "gh failing: $(tr '\n' ' ' <"$err")"
    exit 1
  fi
  sleep "$interval"
}

# Check lines carry the head sha, so a check that fails again after a push is a new line.
# Cancelled checks are left out: a push cancels superseded runs.
view_jq='"\(.state)\t\(.baseRefName)",
  "merge state: \(.mergeStateStatus)",
  (.headRefOid[0:7]) as $sha
  | .statusCheckRollup[]
  | select((if .__typename == "StatusContext" then .state else .conclusion end)
      | IN("FAILURE", "ERROR", "TIMED_OUT", "STARTUP_FAILURE", "ACTION_REQUIRED"))
  | "check failed: \(.name // .context) @ \($sha)"'

while true; do
  if ! view=$(gh pr view "$pr" --json state,mergeStateStatus,baseRefName,headRefOid,statusCheckRollup --jq "$view_jq" 2>"$err"); then
    gh_failed; continue
  fi
  IFS=$'\t' read -r state base <<<"$(head -n 1 <<<"$view")"

  if [ "$state" != OPEN ]; then echo "PR $state"; rm -f "$state_file"; exit 0; fi

  if ! base_sha=$(gh api "repos/{owner}/{repo}/commits/$base" --jq .sha 2>"$err"); then
    gh_failed; continue
  fi
  failures=0

  current=$(
    {
      echo "base moved: $base_sha"
      tail -n +2 <<<"$view"
    } | sort
  )

  comm -13 <(echo "$prev") <(echo "$current")
  prev=$current
  echo "$prev" >"$state_file"
  sleep "$interval"
done
