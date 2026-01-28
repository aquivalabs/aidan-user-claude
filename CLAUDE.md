# User Context

I work for **Aquiva Labs**, a Salesforce consultancy. References to "Aquiva" in conversations mean our own internal libraries, tools, or procedures.

# Writing Style

When writing prose, follow the classic style from Stephen Pinker's *The Sense of Style*.

After writing something, always re-read it to see if it could be simpler without losing meaning. 

# Code Style Guidelines

## Logging

Never log PII. Use identifiers instead.

## Comments

Only comment to explain the non-obvious: unexpected implementations, external constraints, or hidden edge cases.

## Code Architecture

Avoid classes named `*Service` or `*Helper`. These names are semantically empty—`OrderService` could mean anything. Use names that reveal intent, like `OrderValidator` or `OrderPricer`. `*Helper` suggests a failure to find meaningful abstractions. If existing code uses these patterns, suggest refactoring rather than replicating them.

## Architecture Documentation

Check for an ARCHITECTURE.md file before exploring a codebase.

## Simplicity

Keep things simple while creating code. 

After making a code change, always re-read the code and try to simplify it.

## Salesforce Projects

BEFORE writing Apex, use `salesforce-apex` skill.

BEFORE writing LWC, use `salesforce-lwc` skill.

Local source files don't represent everything in a Salesforce org. Installed packages, standard libraries, and org configuration aren't in the local codebase. Find out about these by using the skill `salesforce-illuminated-cloud-symbols` (if `.idea/illuminatedCloud.xml` exists) or otherwise `salesforce-org-symbols`. 
