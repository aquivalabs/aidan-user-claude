---
name: salesforce-apex-tests
description: Use when writing Apex tests.
allowed-tools:
---

Structure each test with comment sections: `// Setup`, `// Exercise`, `// Verify`.

Use existing test data factories if available.

Use `Test.startTest()` and `Test.stopTest()` to isolate governor limits.

Extract repeated test data setup to `@testSetup` methods or class-level helpers.

Only add messages to assertions if the failure reason isn't obvious from context.