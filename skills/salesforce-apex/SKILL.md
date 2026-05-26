---
name: salesforce-apex
description: Provides Apex development workflow including static analysis and testing steps. Use before writing Apex classes or triggers
allowed-tools: mcp__ide__getDiagnostics, Bash(sf project deploy *), Bash(sf apex run test *), Read(~/.claude/skills/salesforce-apex/*)
---

## Workflow

1. **Read project config** — Get `sourceApiVersion` from `sfdx-project.json` for all new `-meta.xml` files.

2. **Write the Apex code**

3. **Check IDE diagnostics** — Use `mcp__ide__getDiagnostics` on new files. Fix errors and warnings before proceeding.

4. **Static analysis** — A post-edit hook runs `sf code-analyzer` automatically on `.cls` and `.trigger` files. Review its output and fix violations before proceeding.

5. **Write tests** — Create test classes following [test-guidance.md](test-guidance.md).

6. **Deploy code and tests** Let source tracking which files to deploy
   ```bash
   sf project deploy start
   ```

7. **Run tests in org**
   ```bash
   sf apex run test --class-names <TestClassName> --result-format human --wait 10
   ```

The task is complete when tests pass in the org.