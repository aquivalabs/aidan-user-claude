---
name: markdown-web
description: Fetch JS-rendered webpages via headless Chromium, returning clean markdown. Handles shadow DOM, cookie consent overlays, and other JS-heavy patterns that defeat simpler fetchers.
trigger: Use when WebFetch returns empty or JS-gated content, or when the URL is a known JS-heavy site (developer.salesforce.com, help.salesforce.com, trailhead.salesforce.com, developer.mozilla.org, medium.com, docs.google.com).
---

## Usage

```bash
node ~/.claude/skills/markdown-web/fetch.mjs "<url>"
```

## Setup (first time only)

```bash
cd ~/.claude/skills/markdown-web && npm install && npx playwright install chromium
```

## Site configuration

Per-domain config lives in `~/.claude/skills/markdown-web/sites.json`. Sites can specify cookies, shadow DOM traversal paths, content selectors, elements to remove, and a waitFor selector. Unknown domains fall back to sensible defaults (`main, article, body`).
