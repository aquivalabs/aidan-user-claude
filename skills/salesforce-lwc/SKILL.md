---
name: salesforce-lwc
description: Use before writing Lightning Web Components.
allowed-tools: mcp__ide__getDiagnostics, Bash(npm run *), Bash(sf code-analyzer:*), Bash(sf project deploy *), Bash(sf lightning generate *)
---

## Workflow

1. **Read project config** — Get `sourceApiVersion` from `sfdx-project.json` for the component's `-meta.xml` file.

2. **Write the component** — Create the JS, HTML, and meta.xml files following [code-guidance.md](code-guidance.md).

3. **Check IDE diagnostics** — Use `mcp__ide__getDiagnostics` on new files. Fix errors and warnings before proceeding.

4. **Run static analysis**
   ```bash
   sf code-analyzer run --target <path-to-component> --view table
   ```
   Address violations before proceeding.

5. **Write Jest tests (if needed)** — See [test-guidance.md](test-guidance.md) for when tests are warranted.

6. **Run tests locally (if applicable)**
   ```bash
   npm run test:unit -- --testPathPattern=<componentName>
   ```

7. **Deploy**
   ```bash
   sf project deploy start --source-dir <path-to-component>
   ```

The task is complete when the component works in the org.