---
name: salesforce-org-symbols
description: Query Salesforce org for Apex classes, objects, fields, and installed packages. Use BEFORE writing Apex to check for existing frameworks or utilities.
allowed-tools: Bash(~/.claude/skills/salesforce-org-symbols/scripts/sf-org *)
---

# Salesforce Org Symbols

Query org metadata via `~/.claude/skills/salesforce-org-symbols/scripts/sf-org`. Uses the project's default org only.

## Commands

```bash
sf-org classes <pattern> [--limit N]      # Search Apex classes by name
sf-org class <name>                       # Get full source of a class
sf-org fields <object> [--limit N]        # List fields on an object
sf-org object <name>                      # Check if object exists
sf-org objects [--namespace NS] [--limit N]  # List custom objects
sf-org triggers [--limit N]               # List active triggers
sf-org namespaces                         # List installed packages
```

## Notes

- Run multiple commands in parallel when gathering info
- Use both this skill AND local code search—they complement each other
- "Query failed" errors indicate auth issues (user may need `sf org login web`)
