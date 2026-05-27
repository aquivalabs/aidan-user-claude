# User Context

I work for **Aquiva** (previously Aquiva Labs), a Salesforce consultancy. References to "Aquiva" in conversations mean our own internal libraries, tools, or procedures.

# Your style

I am an experienced developer/architect, but I can make mistakes. I value your pushback, so challenge decisions if necessary. I will tell you directly if something is decided and should no longer be challenged. 

# Writing Style

When writing prose, follow the classic style from Stephen Pinker's *The Sense of Style*.

After writing something, always re-read it to see if it could be simpler without losing meaning. 

## Specifications and Plans

Don't over-solutionise in specifications. Stick to architectural decisions, not details that can be handled in the build phase. Structural plans (e.g. refactoring) may include class sketches to show the target shape; behavioural specs should describe what, not how.

# Code Style Guidelines

## Logging

Never log PII. Use identifiers instead.

## Comments

Only comment to explain the non-obvious: unexpected implementations, external constraints, or hidden edge cases.

## Code Architecture

Avoid classes named `*Service` or `*Helper`. These names are semantically empty—`OrderService` could mean anything. Use names that reveal intent, like `OrderValidator` or `OrderPricer`. `*Helper` suggests a failure to find meaningful abstractions. If existing code uses these patterns, suggest refactoring rather than replicating them.

## Architecture Documentation

Check for an ARCHITECTURE.md file before exploring a codebase.

## Testing

When tests fail due to mismatches between test doubles (mocks, stubs, fakes) and implementation code, fix the test doubles — never modify implementation code to match test doubles.

## Simplicity

Keep things simple while creating code. 

After making a code change, always re-read the code and try to simplify it. In particular, if we solved a problem by adding stuff, re-read to see if we could instead have removed something. 

## Salesforce Projects

BEFORE designing or writing Apex, use `salesforce-apex` skill.

BEFORE writing LWC, use `salesforce-lwc` skill.

Local source files don't represent everything in a Salesforce org. Installed packages, standard libraries, and org configuration aren't in the local codebase. Find out about these by using the skill `salesforce-illuminated-cloud-symbols` (if `.idea/illuminatedCloud.xml` exists) or otherwise `salesforce-org-symbols`.

When removing metadata from a source-tracked org, delete the local file and deploy — don't use explicit CLI delete commands.

## Web Fetching

BEFORE fetching web content from JS-heavy sites (Salesforce docs, MDN, Medium, etc.), use `markdown-web` skill. Also use it as a fallback when WebFetch returns empty or JS-gated content.
