---
name: salesforce-apex-post
description: Use AFTER writing any new Apex classes, triggers, or other Apex files.
allowed-tools: mcp__ide__getDiagnostics, Bash(sf code-analyzer:*), Bash(sf project deploy *), Bash(sf apex run test *)
---

## 1. Check IDE Diagnostics

Use `mcp__ide__getDiagnostics` to check for linting issues in the new files. Fix any errors or warnings before proceeding.

## 2. Run Static Analysis

```bash
sf code-analyzer run --target <path-to-new-files> --view table
```

Address any violations before proceeding.

## 3. Write Tests

Create corresponding test classes with meaningful test methods covering:
- Positive scenarios (happy path)
- Negative scenarios where appropriate

## 4. Deploy

Deploy the new code and tests together:

```bash
sf project deploy start --source-dir <paths>
```

## 5. Run Tests

Execute the tests in the org:

```bash
sf apex run test --class-names <TestClassName> --result-format human --wait 10
```

## Completion

Only consider the task complete when tests pass in the org.
