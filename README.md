# Aidan's user-level Claude Configuration

This contains general rules in [CLAUDE.md](CLAUDE.md) and skills in the [skills](skills) directory.

Other files are stored in ~/.claude but they are not configuration.

## CLAUDE.md

Short by design. It should be language-agnostic; specifics live in skills or project-level files.

A few bets that have paid off so far:

- **Referencing Pinker rather than spelling out the style.** Claude knows *The Sense of Style* well enough that a reference is sufficient. No need to restate its principles.
- **No good/bad examples.** LLM-generated rules files love these, but they seem redundant. Claude follows the intent without them.
- **Encouraging pushback.** The "Your style" section explicitly invites Claude to challenge decisions, with an escape hatch ("I will tell you directly if something is decided") to keep it from becoming annoying. New — not yet proven in practice.
- **Specs and plans at the right altitude.** The spec guidance distinguishes structural plans (where code sketches belong) from behavioural specs (where they don't). This came from finding that Claude would over-solutionise specs with implementation detail that constrained the build phase unnecessarily.
- **ARCHITECTURE.md convention.** The idea is that Claude reads a full project and writes an ARCHITECTURE.md up front, saving repeated exploration. Jury is still out — it adds maintenance overhead when architecture changes, and some sources suggest agents perform worse with such files. Worth revisiting.

## Skills

The skills cover Salesforce development: Apex, LWC, and org symbol lookup. Each defines a workflow that guides Claude through the shortest path to working, tested code.

Things worth noting:

- **Skills replace multi-step agent work with a single invocation.** What might take 10 tool calls becomes 1 or 2. Time spent refining a skill pays for itself quickly.
- **salesforce-org-symbols uses scripts for indirection.** The skill can only access the current default org, and the scripts reformat CLI output into something easier for the LLM to consume. Safety and simplicity in one move.
- **allowed-tools enables pre-approved operations.** This is powerful but deliberately scoped to read-only operations and purpose-built scripts. The Apex skill pre-approves IDE diagnostics, static analysis, deploys, and test runs — all things that are safe to let run without confirmation.
- **CLAUDE.md must point to skills explicitly.** Claude doesn't always reach for a skill it already knows how to do natively. The "BEFORE writing Apex/LWC, use skill X" instructions in CLAUDE.md fix this. The keyword "before" matters.
- **Skills calling skills.** Early impression was that Claude doesn't call one skill from within another, but this needs re-investigation.
