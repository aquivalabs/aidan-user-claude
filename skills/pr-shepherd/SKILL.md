---
name: pr-shepherd
description: Take a PR from open to merged. Checks it is ready, enables squash auto-merge, watches CI and the base branch in the background, and fixes failing checks, conflicts, and semantic breaks from base changes itself, asking the user only when a fix needs judgement. Use whenever the user wants a PR landed or watched through CI, even without naming this skill, "shepherd this PR", "babysit the PR", "get this merged", "merge when green", "keep an eye on CI", "land it".
allowed-tools: Bash(gh *), Bash(git *), Bash(npm *), Read, Edit, Write, Grep, Glob, AskUserQuestion, Skill, Monitor
---

# Shepherd a PR to merge

Resolve the PR from the argument (number or URL), else from the current branch. Read its head and base branch names from `gh pr view --json headRefName,baseRefName`.

All fixes happen in a worktree of the shepherd's own, so the user can keep working in their checkout.

## 1. Check it is ready

Read the PR body, and `git status` in the user's checkout. Stop and tell the user what is wrong and how to fix it when either holds:

- The body is an unfilled template, or lacks a closing keyword for its issue.
- The local branch has uncommitted or unpushed work. Ask whether to commit and push it; never push on assumption.

GitHub's own merge blockers (draft, requested changes, conflicts, failing checks) surface through steps 4 to 6.

## 2. Create the worktree

`git fetch`, then `git worktree add --detach .claude/worktrees/pr-<number> origin/<head>` from the repo root. If `.claude/worktrees/` is not already ignored, append it to `.git/info/exclude` so the worktree stays out of the user's `git status` and tooling. Detach because the user may have the head branch checked out, and git refuses to check out one branch in two worktrees. Push with `git push origin HEAD:<head>`, and start each fix from `origin/<head>` after a fresh fetch. Tell the user their local branch needs a pull after the shepherd pushes.

Remove the worktree when the PR merges or closes.

## 3. Enable auto-merge

If auto-merge is off, enable it with squash. If GitHub refuses, report its message to the user.

## 4. Watch for changes

Arm one `Monitor` (`timeout_ms: 1800000`, the maximum) running `~/.claude/skills/pr-shepherd/scripts/watch-pr.sh <pr-number>`. It polls every 60 seconds and prints a line only when something changes: `base moved: <sha>`, `merge state: <GitHub's mergeStateStatus>`, `check failed: <name>`, `PR MERGED`, or `PR CLOSED`. The first poll reports the current base too. Silence means nothing has changed. It survives your fixes; do not restart it after a push.

When the monitor reports:

- **`PR MERGED`:** report it and stop.
- **`PR CLOSED`:** tell the user and stop.
- **`base moved`, or `merge state: DIRTY` or `BEHIND`:** step 5. These often arrive together; handle them as one catch-up.
- **`check failed`, or another merge state that blocks the merge:** step 6.
- **`merge state: CLEAN` that persists while auto-merge should be on:** something switched it off. Tell the user and stop unless you know why.
- **Expiry notice:** re-arm the same script. A push cancels superseded runs; the script ignores cancelled checks and waits for the new run.

## 5. Catch up with the base

CI tested the PR against an older base, so a base change needs a fresh look at the combined code.

1. Turn auto-merge off (`gh pr merge <number> --disable-auto`) so GitHub cannot merge on a stale assessment.
2. In the worktree, run `engineering-skills:catch-up-with-base` with the PR's base branch. If the branch is already up to date, turn auto-merge back on and return to watching.
3. Act on the result:
   - **A decision needs the user** (see below): leave auto-merge off and ask with AskUserQuestion, with a recommended option. Apply the answer, then continue as below.
   - **Textual conflicts, or semantic breaks or design changes you fixed:** commit and push.
   - **Clean, with nothing to fix:** commit and push if GitHub reports `BEHIND` (the repo requires up-to-date branches); otherwise `git merge --abort` and let the PR merge as it is.
4. Turn auto-merge back on.

The shepherd has more authority than the catch-up skill grants on its own. It commits and pushes the merge. It also brings the PR's code into line with a base refactor without asking, when the new shape is unambiguous and applying it keeps behaviour unchanged: a renamed or moved API, a deprecated call with a named replacement, a new base utility that does exactly what the PR's own code does. Ask instead when conforming would change behaviour, needs a choice between shapes, or reaches code the PR did not touch. Ask, too, about any conflict where both sides change the same logic with different intent.

Merge; never rebase or force-push.

## 6. Resolve failures, or ask

Read the failed run's log before touching anything.

**Fix and push without asking** when the cause is mechanical and the fix is unambiguous:

- Lint, formatting, or typecheck failures. Reproduce with the matching local command, fix, re-run it, commit, push.
- A test failing because of a change this PR made, where the test's expectation is plainly stale or the implementation has a slip the test correctly caught. A test double that disagrees with the implementation gets fixed in the double.
- A check that fails for a transient infrastructure reason (runner lost, network timeout): rerun the failed jobs, once.

**Ask the user (AskUserQuestion) with a recommended option** when any of these hold:

- Fixing means choosing between changing the implementation and changing the test, and the spec does not settle which.
- The failure is in code the PR did not touch, or looks like a flaky test (it passed on rerun, or fails on the base branch too).
- A fix would weaken a gate: a lowered coverage threshold, a new suppression, `--no-verify`, a skipped test.
- The same check fails again after your fix. Two attempts on one failure is the limit.

Commit fixes with a message that says what failed and why the change fixes it. After any push, confirm auto-merge is still enabled.
