---
name: merge-base
description: Merge the base branch into the current branch. Merge everything that is safe automatically, and ask the user only about merges that need a real decision. Go past textual conflicts to semantic breaks, and past those to design consistency. When the base carries a refactor or redesign, bring the current branch into line with it (with the user's consent).
when_to_use: Use when the user wants to bring base-branch changes into their working branch, e.g. "merge main into this branch", "catch up with the base branch", "merge base changes in".
---

# Goal

Bring the base branch's changes into the current branch. Merge as much as you safely can on your own. Ask the user only about the merges that need a genuine decision.

Work at three levels, each deeper than the last:

1. **Textual conflicts** — the parts `git` flags. The easy part.
2. **Semantic breaks** — the text merged cleanly but the combined code no longer holds together (a rename the other side still calls, a changed signature, logic in two files that no longer agrees).
3. **Design consistency** — the base carries a refactor or redesign, and code on the current branch still follows the old shape. It compiles, it passes, but it is now inconsistent with the direction of the codebase. This is the level a plain merge cannot see, and the one most worth your attention.

# Steps

## 1. Identify the base branch

Detect it rather than asking, then state your choice so the user can correct it:

- Try `git symbolic-ref refs/remotes/origin/HEAD` for the remote's default branch.
- Fall back to `main`, then `master`.
- If the current branch clearly forked from a different branch, prefer that.

Run `git fetch` first so the base is up to date. Confirm the working tree is clean before merging; if it is dirty, stop and tell the user.

## 2. Understand what the base changed, and why

Before merging, build a picture of the base branch's direction. You need intent, not just a diff, to judge the design-consistency level later.

Keep the raw history out of your context. Use summary forms, never full-patch diffs: `git log --oneline --merges`, `git shortlog`, `git diff --compact-summary <merge-base>..<base>`, `git diff --name-status <merge-base>..<base>`. If the change is large, delegate the reading to an `Explore` or `general-purpose` subagent and ask it to return only the conclusion: the one or two design themes, and a list of renamed, moved, or removed symbols and files. The subagent absorbs the raw diff so you do not.

Draw on whatever you can reach:

- **Source control**: the summary commands above show the shape of the change. Large moves, renames, and new directories signal a refactor.
- **Tickets**: if commits or branch names reference issue keys (Jira, GitHub, Asana), pull the ticket to learn the goal behind the change. Use the relevant MCP tools or `gh` when they are available.
- **In-repo docs**: check `ARCHITECTURE.md`, ADRs, `README`, and any design notes for a decision the base is enacting.

Name the one or two themes you find (e.g. "base migrated data access to a repository pattern"). If you find nothing beyond scattered small changes, say so and proceed; not every merge carries a redesign.

## 3. Start the merge

Run `git merge <base>`. Do not commit yet, so you have room to inspect.

- Clean merge: still go through steps 4 to 6. A clean merge is not a safe merge.
- Conflicts: resolve them in step 4.

## 4. Resolve textual conflicts

Resolve the conflicts whose correct answer is unambiguous:

- Both sides added distinct, non-overlapping content: keep both.
- One side is a pure superset or trivial reformat of the other: take the fuller/newer one.
- Import lists, changelogs, lockfiles, and similar additive files: combine.

Leave for step 6 any conflict where two changes touch the same logic with different intent, where you would be guessing at the wanted behaviour, or where resolving it discards someone's real change.

## 5. Check semantic breaks and design consistency

**Semantic breaks** — look for text that merged cleanly but no longer holds together:

- The base renamed or removed a symbol, file, or config key the current branch still uses.
- The base changed a signature, type, or contract while the current branch added callers of the old shape.
- Related logic in different files that no longer agrees.
- A file the base moved or deleted that the current branch edited, so a change landed in an orphaned copy.

Work from the list of changed symbols and files from step 2, and grep the current branch for uses of each. Grep, do not read whole files or diffs, so the check stays cheap. Where the project has a fast build, type-check, lint, or test command, run it; a green run is strong evidence, a red one names the breaks directly. Fix the unambiguous ones yourself (e.g. update call sites for a rename).

**Design consistency** — using the themes from step 2, find code on the current branch that still follows the old design the base has moved away from. The current branch's new files are the usual offenders: written against the old pattern, they merge without a murmur and quietly reintroduce it. Ask whether a reviewer who knew the base's direction would accept the merged result as consistent.

Bringing the current branch into line with a redesign changes code beyond the mechanical merge, so treat it as needing the user's consent. Do not silently rewrite their work to match the new pattern. Gather these into step 6 with a concrete proposal for each.

## 6. Ask about the real decisions

Collect everything you could not resolve safely, and bring it to the user in one pass rather than one prompt at a time. Separate the two kinds:

- **Conflicts and breaks** you could not resolve: state the file(s), what each side did, and why it needs their call.
- **Consistency proposals**: state the base's design direction, the current-branch code that diverges from it, and the change you propose. Let the user choose to conform now, defer it, or keep the old shape deliberately.

Use `AskUserQuestion` when the choices are discrete. Do not guess on any of these; a wrong silent resolution is worse than a question.

## 7. Report

Summarise briefly: what merged cleanly, what you resolved and how, the base's design direction and any consistency work done or proposed, and the result of any build/test run. Do not commit unless the user asked you to, or your standing instructions allow it; if you do commit, use a clear merge message.
