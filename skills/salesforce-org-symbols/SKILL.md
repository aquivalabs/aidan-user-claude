---
name: salesforce-org-symbols
description: Query Salesforce org for Apex classes, objects, and schema. Use BEFORE writing Apex code to check what frameworks, utilities, or patterns exist in the org (e.g., trigger frameworks, selector patterns, service classes). Also use to check object fields, find installed packages, or answer questions about what's available in Salesforce.
allowed-tools: Bash
---

# Salesforce Org Symbols

This skill queries Salesforce org metadata in real-time to provide information about available Apex classes, objects, fields, and installed packages. Use this BEFORE writing Apex code to understand what's already available in the org.

## When to Use This Skill

- Before creating triggers: Check for trigger frameworks (TDTM, TriggerHandler patterns)
- Before creating services: Search for existing *Service, *Handler, *Selector classes
- When writing Apex: Check if utility classes exist (e.g., Logger, TestFactory)
- When working with objects: Verify field names, types, and custom objects
- When user asks about installed packages or namespaces
- When user asks "what's in this org" or "what's available in Salesforce"

## Before You Start

### Determine Target Org

The Salesforce CLI needs to know which org to query:

1. **If user doesn't specify an org**: Omit `--target-org` flag (uses default org)
2. **If user specifies org alias/username**: Add `--target-org <alias-or-username>` to commands
3. **To check default org**: Run `sf config get target-org --json`

### Authentication Check

If queries fail with auth errors, the org may not be authenticated. Tell user to run:
```bash
sf org login web --alias <alias>
```

## Query Commands

Commands return JSON with results in `.result.records` array.

### 1. Apex Classes

#### Find Classes by Name Pattern

Search for classes containing specific text:

```bash
sf data query --query "SELECT Name, NamespacePrefix FROM ApexClass WHERE Name LIKE '%SearchTerm%' ORDER BY Name LIMIT 10" --json
```

Examples:
- Find test classes: `WHERE Name LIKE '%Test%' LIMIT 10`
- Find services: `WHERE Name LIKE '%Service%' LIMIT 10`
- Find handlers: `WHERE Name LIKE '%Handler%' LIMIT 10`

#### Get Class Details (Body/Methods)

Retrieve full class body to examine methods and signatures:

```bash
sf data query --query "SELECT Name, NamespacePrefix, Body FROM ApexClass WHERE Name = 'ClassName' LIMIT 1" --json
```

The `Body` field contains the complete Apex class source code. Parse this to extract:
- Method signatures
- Constructor patterns
- Class-level comments
- Interfaces implemented

#### List Classes in a Namespace

See what classes are provided by an installed package:

```bash
sf data query --query "SELECT Name FROM ApexClass WHERE NamespacePrefix = 'namespace' ORDER BY Name LIMIT 10" --json
```

#### List All Classes (Expensive - Use Sparingly)

Only use when user specifically asks for "all classes":

```bash
sf data query --query "SELECT Name, NamespacePrefix FROM ApexClass ORDER BY NamespacePrefix, Name LIMIT 100" --json
```

Warning: This can return hundreds of classes. The LIMIT 100 prevents overwhelming results.

### 2. Objects and Fields

#### Check if Object Exists

Verify an object is available in the org:

```bash
sf data query --query "SELECT QualifiedApiName, Label, NamespacePrefix, IsCustomizable FROM EntityDefinition WHERE QualifiedApiName = 'ObjectApiName' LIMIT 1" --json
```

Replace `ObjectApiName` with the API name (e.g., `Account`, `MyObject__c`).

#### List Fields on an Object

Get all fields with their types and labels:

```bash
sf data query --query "SELECT QualifiedApiName, DataType, Label FROM FieldDefinition WHERE EntityDefinition.QualifiedApiName = 'ObjectApiName' ORDER BY QualifiedApiName LIMIT 10" --json
```

Common field properties in results:
- `QualifiedApiName`: Full API name (e.g., `MyField__c`). Custom fields end with `__c`
- `DataType`: Field type (Text, Number, Lookup, etc.)
- `Label`: User-facing label

#### List Custom Objects

Find all custom objects in the org:

```bash
sf data query --query "SELECT QualifiedApiName, Label, NamespacePrefix FROM EntityDefinition WHERE IsCustomizable = true AND IsCustomSetting = false ORDER BY QualifiedApiName LIMIT 10" --json
```

To filter by namespace (installed package objects):
```bash
sf data query --query "SELECT QualifiedApiName, Label FROM EntityDefinition WHERE NamespacePrefix = 'namespace' ORDER BY QualifiedApiName LIMIT 10" --json
```

### 3. Trigger Frameworks and Patterns

#### Find Trigger-Related Classes

Simple search for any trigger-related classes:

```bash
sf data query --query "SELECT Name FROM ApexClass WHERE Name LIKE '%Trigger%' LIMIT 10" --json
```

This will find trigger handlers, frameworks, utilities, and helper classes. Common patterns you might see:
- `TriggerHandler` - Kevin O'Hara's framework base class
- `*TriggerHandler` - Specific trigger handlers (e.g., AccountTriggerHandler)
- `ApplicationTriggerHandler` - fflib pattern
- `TDTM_*` - NPSP's Table-Driven Trigger Management framework

#### Check Existing Triggers

See what triggers are already defined:

```bash
sf data query --query "SELECT Name, TableEnumOrId FROM ApexTrigger WHERE Status = 'Active' LIMIT 10" --json
```

### 4. Namespaces and Installed Packages

#### List All Installed Package Namespaces

```bash
sf data query --query "SELECT DISTINCT NamespacePrefix FROM ApexClass WHERE NamespacePrefix != null ORDER BY NamespacePrefix LIMIT 10" --json
```

Results show which managed/unlocked packages provide Apex classes.

#### Count Classes per Namespace

Useful to understand package size:

```bash
sf data query --query "SELECT NamespacePrefix, COUNT(Id) classCount FROM ApexClass WHERE NamespacePrefix != null GROUP BY NamespacePrefix ORDER BY NamespacePrefix LIMIT 10" --json
```

### 5. Common Utility Classes

#### Find Logger/Logging Classes

```bash
sf data query --query "SELECT Name, NamespacePrefix FROM ApexClass WHERE Name LIKE '%Logger%' OR Name LIKE '%Log%' LIMIT 10" --json
```

#### Find Test Factory/Data Builder Classes

```bash
sf data query --query "SELECT Name, NamespacePrefix FROM ApexClass WHERE Name LIKE '%Factory%' OR Name LIKE '%Builder%' OR Name LIKE '%TestData%' LIMIT 10" --json
```

#### Find Selector Pattern Classes (fflib)

```bash
sf data query --query "SELECT Name FROM ApexClass WHERE Name LIKE '%Selector%' OR Name = 'fflib_SObjectSelector' LIMIT 10" --json
```

#### Find Service Layer Classes

```bash
sf data query --query "SELECT Name, NamespacePrefix FROM ApexClass WHERE Name LIKE '%Service%' LIMIT 10" --json
```

## Parsing Query Results

The Salesforce CLI returns JSON. Parse the output structure:

```json
{
  "status": 0,
  "result": {
    "records": [
      {
        "Name": "ClassName",
        "NamespacePrefix": "namespace",
        "Body": "public class ClassName { ... }"
      }
    ],
    "totalSize": 1,
    "done": true
  }
}
```

- **Success**: `status: 0`, results in `result.records` array
- **No results**: `result.records` is empty array, `totalSize: 0`
- **Error**: Non-zero status, error message in output

### Extracting Class Methods from Body

When you retrieve a class Body, parse it to find methods:

1. Look for method signatures: `public/private/global/protected ... methodName(`
2. Extract return types and parameters
3. Identify constructors (name matches class name)
4. Note annotations (@AuraEnabled, @InvocableMethod, etc.)

You don't need to write a full parser - just extract key information the user needs.

## Output Guidance

When presenting results to the user:

1. **Summarize findings**: Don't dump raw JSON
2. **Highlight key information**: Class names, namespaces, patterns found
3. **Provide recommendations**: "Found TriggerHandler framework - recommend using it for new triggers"
4. **Include file references**: If local .cls files exist, reference them with line numbers

Example:
```
I found 3 trigger-related classes in your org:

1. TriggerHandler (no namespace) - Base trigger handler class
2. AccountTriggerHandler - Handles Account trigger logic
3. npsp__TDTM_Runnable (npsp namespace) - NPSP's trigger framework interface

Recommendation: Use the TriggerHandler base class for new triggers, as it follows best practices and is already in use.
```

## Error Handling

### Common Errors

**Not authenticated**:
```
ERROR running force:data:soql:query: The org cannot be found
```
→ Tell user to authenticate: `sf org login web`

**Invalid SOQL**:
```
ERROR: Invalid SOQL query
```
→ Check query syntax, object/field names

**No results**:
- `totalSize: 0` in response
- Not an error - just means no matching records

### Org Connection Issues

If queries consistently fail:
1. Check default org: `sf org list`
2. Verify authentication: `sf org display`
3. Try explicit org: Add `--target-org <alias>` to queries

## Performance Considerations

- **Class body queries are slow**: Only retrieve Body when needed for method details
- **All queries have LIMIT 10 by default**: Prevents overwhelming results in large orgs
- **Multiple queries**: Run them in parallel when possible (multiple Bash tool calls in one message)
- **API limits**: Standard Salesforce API limits apply

## Workflow Examples

### Example 1: Before Creating a Trigger

User asks: "I need to create a trigger on Opportunity"

Steps:
1. Check for existing triggers: Query ApexTrigger for Opportunity
2. Check for frameworks: Look for TriggerHandler, TDTM patterns
3. If framework found: Recommend using it and show example classes
4. Check Opportunity fields: Query FieldDefinition if user needs field info

### Example 2: Understanding Installed Packages

User asks: "What packages are installed?"

Steps:
1. Query distinct namespaces from ApexClass
2. For each namespace, optionally query a few class names to show what's included
3. Present organized list of packages with class counts

### Example 3: Finding Utilities Before Writing Code

User asks: "How should I log errors in Apex?"

Steps:
1. Search for Logger classes: `WHERE Name LIKE '%Logger%'`
2. If found: Get one class Body to show usage pattern
3. If not found: Recommend creating a logging utility

## Important Notes

- **Always query fresh**: Don't cache results (they may change)
- **This is complementary to local files**: Use both this skill AND local code search
- **Respect user's org**: Don't query excessively; be targeted
- **Package classes can't be modified**: If class is in a namespace, user can't edit it
- **LIMIT 10 is the default**: All queries include LIMIT 10 to keep results manageable
