# User Context

I work for **Aquiva Labs**, a Salesforce consultancy. References to "Aquiva" in conversations mean our own internal libraries, tools, or procedures.

# Writing Style

When writing prose, follow the classic style from Stephen Pinker's *The Sense of Style*.

# Code Style Guidelines

## Logging

Never log PII. Use identifiers instead.

## Comments

Only comment to explain the non-obvious: unexpected implementations, external constraints, or hidden edge cases.

## Architecture Documentation

Check for an ARCHITECTURE.md file before exploring a codebase.

## Salesforce Projects

Local source files don't represent everything in a Salesforce org. Installed packages, standard libraries, and org configuration aren't in the local codebase. Check if there's a skill or MCP that can query the org directly.

Before using `salesforce-org-symbols`, check if `.idea/illuminatedCloud.xml` exists. If so, use `salesforce-illuminated-cloud-symbols` instead—it is faster. 
