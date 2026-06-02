# Aidan's user-level Claude Configuration

This contains general rules in [CLAUDE.md](CLAUDE.md), a personal plugin in [skills/aidan-salesforce-skills](skills/aidan-salesforce-skills), and any remaining standalone skills in the [skills](skills) directory.

## Installing the plugin

```
/plugin marketplace add aquivalabs/aidan-user-claude
/plugin install aidan-salesforce-skills@aidan-user-claude
```

Then add the CLAUDE.md nudges — the plugin can't carry these itself:

```markdown
BEFORE designing or writing Apex, use `aidan-salesforce-skills:salesforce-apex` skill.
BEFORE writing LWC, use `aidan-salesforce-skills:salesforce-lwc` skill.
```

## CLAUDE.md

Short by design. It should be language-agnostic; specifics live in skills or project-level files.

A few bets that have paid off so far:

- **Referencing Pinker rather than spelling out the style.** Claude knows *The Sense of Style* well enough that a reference is sufficient. No need to restate its principles.
- **No good/bad examples.** LLM-generated rules files love these, but they seem redundant. Claude follows the intent without them.
- **Encouraging pushback.** The "Your style" section explicitly invites Claude to challenge decisions, with an escape hatch ("I will tell you directly if something is decided") to keep it from becoming annoying. New — not yet proven in practice.
- **Specs and plans at the right altitude.** The spec guidance distinguishes structural plans (where code sketches belong) from behavioural specs (where they don't). This came from finding that Claude would over-solutionise specs with implementation detail that constrained the build phase unnecessarily.

Things to revisit over time:

- **ARCHITECTURE.md convention.** The idea is that Claude reads a full project and writes an ARCHITECTURE.md up front, saving repeated exploration. Jury is still out — it adds maintenance overhead when architecture changes, and some sources suggest agents perform worse with such files. Worth revisiting.
- **General coding advice** It may be that future models already follow our preferred coding style so we could remove some items if/when this happens. 

## Lessons learned

- **Auto-mode made the org-symbols skill redundant.** The `salesforce-org-symbols` skill wrapped a handful of SOQL queries behind a bash script. Its main value was the `allowed-tools` constraint, which gave Claude read-only org access without granting broad shell permissions. Once Claude Code introduced auto-mode — where users pre-approve tool usage rather than confirming each call — that permission-scoping argument disappeared. Claude can construct the same `sf data query` calls itself; the wrapper was just ceremony. Removed June 2026.

## Plugin: aidan-salesforce-skills

The Salesforce skills (Apex, LWC, org symbol lookup) plus the code-analyzer hook are bundled as a plugin. Each skill defines a workflow that guides Claude through the shortest path to working, tested code. The hook runs `sf code-analyzer` automatically on every `.cls` or `.trigger` edit.

Things worth noting:

- **Skills replace multi-step agent work with a single invocation.** What might take 10 tool calls becomes 1 or 2. Time spent refining a skill pays for itself quickly.
- **allowed-tools enables pre-approved operations.** This is powerful but deliberately scoped to read-only operations and purpose-built scripts. The Apex skill pre-approves IDE diagnostics, deploys, and test runs — all things that are safe to let run without confirmation.
- **CLAUDE.md must point to skills explicitly.** Claude doesn't always reach for a skill it already knows how to do natively. The "BEFORE writing Apex/LWC, use skill X" instructions in CLAUDE.md fix this. The keyword "before" matters. Plugins can't carry their own CLAUDE.md, so this remains a manual step.
- **General coding advice matters for skill quality.** The Apex and LWC skills work best alongside general coding guidance (no PII in logs, keep it simple, etc.). Users of this plugin should carry similar rules in their own CLAUDE.md.
