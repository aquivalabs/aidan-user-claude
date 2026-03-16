---
name: jina-reader
description: >-
  Fetch JS-rendered webpages via jina.ai reader, returning clean markdown.
  TRIGGER when: WebFetch fails with empty/JS-only content, or URL matches a
  known JS-heavy site (developer.salesforce.com, help.salesforce.com,
  trailhead.salesforce.com, developer.mozilla.org, medium.com, docs.google.com).
  DO NOT TRIGGER when: fetching raw APIs, GitHub (use gh CLI), or plain-text URLs.
allowed-tools: Bash(*r.jina.ai*), Bash(*jina-reader/fetch*.sh*)
---

# Jina Reader

Fetch web content as clean markdown via jina.ai's reader service. Handles JS-rendered pages that WebFetch can't.

## Fallback triggers

Use Jina when WebFetch returns any of:
- Empty or near-empty content
- "Enable JavaScript" or "JavaScript is required" messages
- `<noscript>` tags as primary content
- Suspiciously short response for a documentation page

## Fetch and clean

Pick the right script based on the URL's domain. Always use a script — never raw curl, as unprocessed output wastes context window.

### developer.salesforce.com

Strips nav chrome, footer, method index, type-link boilerplate, and "Requires Chatter" sections.

```bash
~/.claude/skills/jina-reader/fetch-developer.salesforce.com.sh "<the full URL>"
```

### All other sites

Generic pipeline: strips same-domain URLs, removes empty anchors, collapses blank lines.

```bash
~/.claude/skills/jina-reader/fetch.sh "<the full URL>"
```

## What the cleanup does

Both scripts share these steps:
1. **Strip base path** — turns `[text](https://example.com/docs/guide/page.htm)` into `[text](page.htm)`
2. **Strip domain** — reduces remaining same-domain URLs to site-relative paths
3. **Remove empty anchors** — Jina emits `[](url)` self-links that carry no content
4. **Collapse blank lines** — `cat -s` reduces runs of blank lines to one

The Salesforce script adds:
1. **Content extraction** — finds the second `===` underline (the actual content heading, not the `<title>` tag) and stops at the `DEVELOPER CENTERS` footer
2. **Strip method index** — removes the bullet-list table of contents (each method's detail section is self-sufficient)
3. **Strip "Requires Chatter"** — removes the heading and its answer (nearly always "No")
4. **Collapse type links** — `[String](url "tooltip")` → `String`
5. **Format parameters** — Jina concatenates parameter descriptions into a single line; the script splits them back into `paramName` / `Type: X` / description blocks

## Troubleshooting

### No API key

If `$JINA_API_KEY` is empty and the script fails:

1. Tell the user they need a Jina API key (free at https://jina.ai/reader).
2. Ask if they'd like you to set it up — they can paste the key and you'll add it to `~/.claude/settings.json` under the `env` key (e.g. `"env": { "JINA_API_KEY": "<key>" }`).
3. After writing the key, the user will need to restart Claude Code for the env var to take effect.

### 401 / empty response despite valid key

Claude Code's sandbox strips Authorization headers from outgoing requests unless the domain is allowlisted. If the key is set but requests return 401 or empty output, check that `~/.claude/settings.json` includes:

```json
"sandbox": {
  "network": {
    "allowedDomains": ["r.jina.ai"]
  }
}
```

If missing, add it and restart Claude Code.
