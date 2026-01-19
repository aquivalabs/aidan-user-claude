---
name: salesforce-illuminated-cloud-symbols
description: Access Salesforce Apex classes and schema objects. Use BEFORE writing Apex code to check what frameworks, utilities, or patterns are already available (e.g., trigger frameworks, selector patterns, service classes). Also use when you need to know object fields, System class methods, API signatures. Check this when asked to create triggers, services, or any new Apex to see if there's an existing framework to follow.
allowed-tools: Read, Grep, Glob, Bash(unzip:*), Bash(zipgrep:*)
---

# Salesforce Illuminated Cloud Symbol Table

Access Salesforce class and object definitions from the Illuminated Cloud offline symbol table.

## Quick Start

**Step 1**: Read `.idea/illuminatedCloud.xml` using the Read tool (not bash)

**Step 2**: Find the `offlineSymbolTablePath` value in the XML. It will look like:
```
value="$PROJECT_DIR$/IlluminatedCloud/something/OfflineSymbolTable.zip"
```

**Step 3**: Replace `$PROJECT_DIR$` with the current working directory to get the full path. Example:
- XML value: `$PROJECT_DIR$/IlluminatedCloud/my_org_butler_DEV/OfflineSymbolTable.zip`
- Resolved: `/Users/aidan/WebstormProjects/my-org-butler/IlluminatedCloud/my_org_butler_DEV/OfflineSymbolTable.zip`

**Step 4**: Use the resolved literal path in all commands (do not use variables).

## Commands

**Search for a class by name** (list files in zip matching pattern):
```bash
unzip -l "/full/path/to/OfflineSymbolTable.zip" | grep -i "searchterm"
```

**Read a specific class definition**:
```bash
unzip -p "/full/path/to/OfflineSymbolTable.zip" "Namespace/ClassName.cls"
```

**Search inside files for methods/content**:
```bash
zipgrep -i "searchterm" "/full/path/to/OfflineSymbolTable.zip" | head -30
```

## Zip Structure

- `Schema/*.cls` - Database objects (Account, Contact, custom objects)
- `System/*.cls` - System Apex classes
- `ConnectApi/*.cls` - Connect API
- `aquiva_os/*.cls` - Installed package classes (namespace prefixed)

## Important

- Database objects like Account are modeled as `.cls` files in `Schema/`
- Installed packages have their own namespace folders (e.g., `aquiva_os/`)
- Always use the full literal path, never shell variables
- Use `unzip -p` to read files, `unzip -l` to list, `zipgrep` to search content
