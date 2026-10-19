---
name: pr-shepherd
description: Take a PR from open to merged. Checks it is ready, enables squash auto-merge, watches CI and the base branch in the background, and fixes failing checks, conflicts, and semantic breaks from base changes itself, asking the user only when a fix needs judgement. Use whenever the user wants a PR landed or watched through CI, even without naming this skill, "shepherd this PR", "babysit the PR", "get this merged", "merge when green", "keep an eye on CI", "land it".
---

# Shepherd a PR to merge

The author is done with the PR. The shepherd takes on the chores between that and the merge: small failures, base changes, and keeping the two sides in agreement.

Resolve the PR from the argument (number or URL), else from the current branch. Read its head and base branch names from `gh pr view --json headRefName,baseRefName`.

All fixes happen in a worktree of the shepherd's own, so the user can keep working in their checkout.

## 1. Check it is ready

Read the PR body, and `git status` in the user's checkout. Stop and tell the user what is wrong and how to fix it when any of these holds:

- The body is an unfilled template, or breaks a PR standard the project sets: its PR template, contributing guide, or agent instructions (`AGENTS.md` and the like).
- The PR looks like it completes a GitHub issue but won't close it. The title or body mentions an issue (`#123` or an issue URL; `#123` may be a PR, which `gh api repos/{owner}/{repo}/issues/123 --jq '.pull_request != null'` reveals), `gh pr view --json closingIssuesReferences` is empty, and nothing says the PR only goes towards it ("towards", "part of", "partial" and the like).
- The local branch has uncommitted or unpushed work. Ask whether to commit and push it; never push on assumption.

GitHub's own merge blockers (draft, requested changes, conflicts, failing checks) surface while watching.

## 2. Create the worktree

`git fetch`, then `git worktree add --detach .worktrees/pr-<number> origin/<head>` from the repo root. If `.worktrees/` is not already ignored, append it to `.git/info/exclude` so the worktree stays out of the user's `git status` and tooling. Detach because the user may have the head branch checked out, and git refuses to check out one branch in two worktrees. Push with `git push origin HEAD:<head>`, and start each fix from `origin/<head>` after a fresh fetch. Tell the user their local branch needs a pull after the shepherd pushes.

Remove the worktree when the PR merges or closes.

## 3. Enable auto-merge

If auto-merge is off, enable it with squash. If GitHub refuses, report its message to the user.

## 4. Find the safety net

When the base moves and a catch-up merges cleanly, the shepherd lets the PR merge without CI ever testing the combined code (see **When the base moves**). Whether that is safe depends on what tests the base branch after merge. Read the CI configuration (`.github/workflows/`, and scripts it calls) once, and place the repo at one of three levels:

1. **Tests gate the release:** a full test run stands between the base and anything shipped, such as a release workflow that runs the suite, or `sf package version create --code-coverage`, which runs every Apex test.
2. **CI runs on each push to the base:** a break is caught within minutes, though other branches may merge it in first.
3. **Neither, or you can't tell:** CI outside GitHub Actions (Jenkins, Azure DevOps) counts as can't tell.

Tell the user the level in a line, naming the workflow that provides the net. At level 3, say that clean catch-ups will be pushed, so CI tests the combined code before merge.

The net covers only what the configured tests cover. When the PR's own checks run no real tests, say so: a pushed catch-up then proves little more than a dropped one.

## 5. Watch for changes

Run `bash <this skill's directory>/scripts/watch-pr.sh <pr-number>` with the repo root as the working directory (the script calls `gh` against the current repo, so it fails from anywhere else), as one background task that notifies you of each line as it prints, not only when it exits. In Claude Code that is `Monitor` with `timeout_ms: 1800000`; a background Bash task reports only on exit, so it misses every change. It polls every 60 seconds and prints a line only when something changes: `base moved: <sha>`, `merge state: <GitHub's mergeStateStatus>`, `check failed: <name> @ <head sha>`, `PR MERGED`, `PR CLOSED`, or `gh failing: <error>`. The first poll reports the current state, so it always prints a `base moved` line, even when the base hasn't moved. Silence means nothing has changed. It survives your fixes; do not restart it after a push.

Once the watcher is running, look once for clashes with other PRs that may merge first. List the open PRs into the same base with auto-merge on (`gh pr list --base <base> --search "is:open" --json number,title,author,autoMergeRequest,files`), leaving out this one. A clash is likely when one touches the same logic as this PR, or its diff (`gh pr diff <number>`) uses a public name this PR renamed or removed. Tell the user about each likely clash in a line: the PR, its author, and what collides. Don't block on it or check again; if one merges first, **When the base moves** handles it.

When the watcher reports:

- **`PR MERGED`:** report it and stop.
- **`PR CLOSED`:** tell the user and stop.
- **`gh failing`:** `gh` failed five polls running, so the watch has stopped. Give the user the error (a lapsed login needs `gh auth login`) and stop.
- **`base moved`, or `merge state: DIRTY` or `BEHIND`:** go to **When the base moves**. These often arrive together; handle them as one catch-up.
- **`check failed`:** go to **When a check fails**.
- **`merge state: BLOCKED`:** usually required checks still running, which needs nothing. If `gh pr view --json reviewDecision` shows `REVIEW_REQUIRED` or `CHANGES_REQUESTED`, tell the user once; the shepherd doesn't review or answer reviews.
- **`merge state: DRAFT`:** tell the user once. A draft can't merge, so once they mark it ready, enable auto-merge again.
- **`merge state: UNSTABLE`:** a check that isn't required failed. Its `check failed` line brings it to **When a check fails**, but it doesn't block the merge, so the PR may merge before the fix lands.
- **`merge state: CLEAN`:** auto-merge should merge it within moments. If `gh pr view --json autoMergeRequest` shows `null` and you didn't turn it off, something else did. Tell the user and stop unless you know why.
- **`merge state: UNKNOWN` or `HAS_HOOKS`:** nothing to do. `UNKNOWN` shows while GitHub recomputes after a push.
- **The watcher stops while the PR is open:** `Monitor` expires after 30 minutes, so this happens routinely. Start it again with `--resume` as a second argument, so it reports only what changed since it stopped rather than the whole state again.

## When the base moves

CI tested the PR against an older base, so a base change needs a fresh look at the combined code.

A clean merge with nothing to fix is not a reason to push when something tests the base after merge (levels 1 and 2 of **Find the safety net**). Every push restarts CI.

1. Confirm the base moved past the PR; the watcher's first `base moved` line comes whether it did or not. Run `gh api repos/{owner}/{repo}/compare/<base>...<head> --jq .behind_by`. If it is 0, return to watching.
2. Turn auto-merge off (`gh pr merge <number> --disable-auto`) so GitHub cannot merge on a stale assessment.
3. In the worktree, run the `catch-up-with-base` skill with the PR's base branch.
4. Act on the result:
   - **A decision needs the user** (see below): leave auto-merge off and ask, with a recommended option. Apply the answer, commit the merge, then continue as below.
   - **The catch-up skill held the commit on a build or test failure it couldn't fix:** resolve it as **When a check fails** does, then commit the merge with the fix and push.
   - **Textual conflicts, or semantic breaks or design changes you fixed:** commit any changes you made after the catch-up skill committed the merge, then push.
   - **Clean, with nothing to fix:** push if the safety net is level 3, or if GitHub reports `merge state: BEHIND`, which it does only when the base requires up-to-date branches. Otherwise `git reset --keep HEAD^1` to drop the merge commit and let the PR merge as it is (a behind branch still merges when the requirement is off), and tell the user in a line which net covers it. If another state such as `BLOCKED` is masking `BEHIND` (GitHub does not document which wins), the watcher reports `BEHIND` once the other blocker clears; catch up again then and push.
5. Turn auto-merge back on.

The shepherd has more authority than the catch-up skill grants on its own. It pushes the merge. It also makes the two sides agree without asking, wherever the code lives, test or not, when the change is unambiguous and keeps behaviour unchanged:

- **The PR's changes, carried into base code.** The PR renamed a public method and the base added a call to the old name: update that call. The same goes for a signature, file or API the PR changed.
- **The base's changes, carried into the PR's code.** A renamed or moved API, a deprecated call with a named replacement, a new base utility that does exactly what the PR's own code does.

Ask instead when making them agree would change behaviour or needs a choice between shapes, or when a base refactor would reach code neither side changed. Ask, too, about any conflict where both sides change the same logic with different intent.

Merge; never rebase or force-push.

## When a check fails

Read the failed run's log before touching anything.

**Fix and push without asking** when the cause is mechanical and the fix is unambiguous:

- Lint, formatting, or typecheck failures. Reproduce with the matching local command, fix, re-run it, commit, push.
- A test broken by this PR's change or by the base merge, where the fix changes how the test reaches the behaviour and leaves what it proves intact: a moved or renamed element found again by the same role or label, a changed navigation path, setup or fixtures, a renamed call. The test must assert the same thing afterwards. A test double that disagrees with the implementation gets fixed in the double.
- A test whose expectation the PR deliberately changed (its description or linked spec says the behaviour changes), or that caught a slip in the implementation.
- A check that fails for a transient infrastructure reason (runner lost, network timeout): rerun the failed jobs, once.

**Ask the user, with a recommended option,** when any of these hold:

- Fixing means choosing between changing the implementation and changing the test, and the spec does not settle which.
- The fix would change what a test asserts, beyond a change the PR deliberately made.
- The cause lies outside both this PR's diff and the base merge, or the test looks flaky (it passed on rerun, or fails on the base branch too).
- A fix would weaken a gate: a lowered coverage threshold, a new suppression, `--no-verify`, a skipped test, a blanket timeout increase, a fixed sleep.
- The same check fails again after your fix. Two attempts on one failure is the limit.

Commit fixes with a message that says what failed and why the change fixes it. After any push, confirm auto-merge is still enabled.
