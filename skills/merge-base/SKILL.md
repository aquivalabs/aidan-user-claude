---
name: merge-base
description: Merge the base branch into the current branch. Do the merge and resolve the safe parts first, then let a cheap signal decide how deep to look. Go past textual conflicts to semantic breaks, and past those to design consistency. When the base carries a refactor or redesign, bring the current branch into line with it (with the user's consent).
when_to_use: Use when the user wants to bring base-branch changes into their working branch, e.g. "merge main into this branch", "catch up with the base branch", "merge base changes in".
---

# Goal

Bring the base branch's changes into the current branch. Merge as much as you safely can on your own. Ask the user only about the merges that need a genuine decision.

There are three levels of trouble a merge can carry, each deeper than the last:

1. **Textual conflicts** — the parts `git` flags. The easy part.
2. **Semantic breaks** — the text merged cleanly but the combined code no longer holds together (a rename the other side still calls, a changed signature, logic in two files that no longer agrees).
3. **Design consistency** — the base carries a refactor or redesign, and code on the current branch still follows the old shape. It compiles, it passes, but it is now inconsistent with the direction of the codebase. This is the level a plain merge cannot see.

Most merges are routine catch-ups with none of this. So do not front-load the expensive investigation. Merge first, resolve the safe parts, then let a cheap signal tell you how deep to look. Escalate to the wider view only when that signal says a refactor is in play.

# Steps

## 1. Identify the base branch and merge

Detect the base rather than asking, then state your choice so the user can correct it:

- Try `git symbolic-ref refs/remotes/origin/HEAD` for the remote's default branch.
- Fall back to `main`, then `master`.
- If the current branch clearly forked from a different branch, prefer that.

Run `git fetch` first so the base is up to date. Confirm the working tree is clean; if it is dirty, stop and tell the user. Then run `git merge <base>`. Do not commit yet, so you have room to inspect.

## 2. Resolve the unambiguous textual conflicts

If the merge conflicted, resolve the conflicts whose correct answer is clear:

- Both sides added distinct, non-overlapping content: keep both.
- One side is a pure superset or trivial reformat of the other: take the fuller/newer one.
- Import lists, changelogs, lockfiles, and similar additive files: combine.

Leave for step 5 any conflict where two changes touch the same logic with different intent, where you would be guessing at the wanted behaviour, or where resolving it discards someone's real change.

## 3. Cheap assessment: what arrived, and does it look simple?

This step is always run and always cheap. Two bounded checks, no full-patch diffs:

- **See what came in**: `git diff --compact-summary <merge-base>..<base>` and `git diff --name-status <merge-base>..<base>`. These stay small regardless of branch size.
- **Semantic-break scan**: from the name-status list, take the symbols and files the base renamed, moved, or removed, and grep the current branch for uses of each. Grep only; do not read whole files. A tiny diff can still break you (a one-line signature change with callers on your branch), so this scan runs even when little changed.

Fix the unambiguous breaks yourself (e.g. update call sites for a rename). If the project has a fast build, type-check, lint, or test command, run it; a green run is strong evidence, a red one names the breaks directly.

Now decide the depth:

- **Looks simple** — no conflicts needed judgement, the summary is scattered small changes, and the scan flagged nothing: you are done. Go to step 6.
- **Signals a refactor** — conflicts needed judgement, or the summary shows structural moves (renames, moved files, new directories), or the scan found the base changed something your branch relies on: go to step 4.

## 4. Orient wider (only when step 3 signalled it)

Now spend the effort to understand the base's *direction*, so you can judge design consistency. Keep raw history out of your context: use `git log --oneline --merges`, `git shortlog`, and the summary diffs from step 3. If the change is large, delegate the reading to an `Explore` or `general-purpose` subagent and ask it to return only the conclusion: the one or two design themes, and the list of renamed, moved, or removed symbols. The subagent absorbs the raw diff so you do not.

Draw on whatever you can reach:

- **Source control**: commit messages and the summary diffs show the shape of the change.
- **Tickets**: if commits or branch names reference issue keys (Jira, GitHub, Asana), pull the ticket for the goal behind the change. Use the relevant MCP tools or `gh` when available.
- **In-repo docs**: check `ARCHITECTURE.md`, ADRs, `README`, and any design notes for a decision the base is enacting.

Name the one or two themes (e.g. "base migrated data access to a repository pattern"). Then find code on the current branch that still follows the old design the base has moved away from. The current branch's new files are the usual offenders: written against the old pattern, they merge without a murmur and quietly reintroduce it. Ask whether a reviewer who knew the base's direction would accept the merged result as consistent.

Bringing the current branch into line with a redesign changes code beyond the mechanical merge, so treat it as needing the user's consent. Do not silently rewrite their work. Gather these into step 5 with a concrete proposal for each.

## 5. Ask about the real decisions

Collect everything you could not resolve safely, and bring it to the user in one pass rather than one prompt at a time. Separate the two kinds:

- **Conflicts and breaks** you could not resolve: state the file(s), what each side did, and why it needs their call.
- **Consistency proposals**: state the base's design direction, the current-branch code that diverges from it, and the change you propose. Let the user choose to conform now, defer it, or keep the old shape deliberately.

Use `AskUserQuestion` when the choices are discrete. Do not guess on any of these; a wrong silent resolution is worse than a question.

## 6. Report

Summarise briefly: what merged cleanly, what you resolved and how, the depth you judged the merge to need and why, any consistency work done or proposed, and the result of any build/test run. Do not commit unless the user asked you to, or your standing instructions allow it; if you do commit, use a clear merge message.
