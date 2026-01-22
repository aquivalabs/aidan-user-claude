# User Context

I work for **Aquiva Labs**, a Salesforce consultancy. References to "Aquiva" in conversations mean our own internal libraries, tools, or procedures.

# Code Style Guidelines

## Logging

**Never log Personally Identifiable Information (PII).** This includes:
- Names (customer names, agent names, user names)
- Email addresses
- Phone numbers
- Any other personal data

Use identifiers (IDs) instead when logging for debugging purposes.

### Examples:

```typescript
// BAD - logs PII
log.info('Agent John Doe accepted voicemail from 555-1234');

// GOOD - uses IDs only
log.info('Agent accepted voicemail', { agentId: 'agent-123', voicemailId: 'vm-456' });
```

## Comments

**Never write comments that simply describe what the code says.** Only add comments when:

1. **Explaining unexpected or unusual code** - When the implementation choice is non-obvious or counterintuitive
2. **Providing context not readable from the code** - Business logic, API quirks, or external constraints
3. **Warning about edge cases** - Important gotchas or side effects that aren't immediately apparent

### Examples of BAD comments (redundant):

```typescript
// Get the voicemail by ID
const voicemail = this.getVoicemailById(id);

// Check if voicemail exists
if (!voicemail) {
  // Return error
  return { error: 'Not found' };
}
```

### Examples of GOOD comments (valuable context):

```typescript
// Use getVoicemailById instead of filtering data array - this returns the
// Backbone model with computed properties, not just the plain data object
const voicemailModel = this.skillVoicemailModel.getVoicemailById(id);

// The actual voicemail data is in 'exposedModel' due to Backbone's computed attribute pattern
const voicemail = voicemailModel.get('exposedModel');
```

**Default to self-documenting code** with clear variable names, small functions, and good structure. Only comment when necessary.

## Architecture Documentation

**When you need to understand a codebase's architecture, first check for an ARCHITECTURE.md file in the project root.**

This file typically contains:
- High-level system design and component relationships
- Key architectural decisions and patterns
- Directory structure and module organization
- Data flow and system boundaries

Always read this file before exploring the codebase or making architectural assumptions.

## Salesforce Projects

When asked about what's available "in this org" or "in Salesforce", remember that local source files
don't represent everything in a Salesforce org. Installed packages, standard Salesforce libraries,
and org configuration aren't in the local codebase.

As well as searching local files, check if there's a skill or MCP that can query the org directly.

### Salesforce Skills

Before using `salesforce-org-symbols`, first check if `.idea/illuminatedCloud.xml` exists in the project.
If it does, use `salesforce-illuminated-cloud-symbols` instead—it's faster since it uses the local
offline symbol table. Only use `salesforce-org-symbols` for non-Illuminated Cloud projects.