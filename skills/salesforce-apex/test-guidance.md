# Apex Test Guidance

Cover:
- Positive scenarios (happy path)
- Negative scenarios where appropriate

## Test Structure

Structure each test with comment sections:
```apex
// Setup
// Exercise
// Verify
```

## Test Data

- Use existing test data factories if available.
- Extract repeated test data setup to `@testSetup` methods or class-level helpers.

## Governor Limits

Use `Test.startTest()` and `Test.stopTest()` to isolate governor limits.

## Assertions

Only add messages to assertions if the failure reason isn't obvious from context.

## Avoid `@TestVisible`

Test through public methods and observable outcomes. If a private method needs direct testing, it likely belongs in its own class. Reserve `@TestVisible` for cases where no reasonable alternative exists.