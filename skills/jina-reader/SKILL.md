---
name: jina-reader
description: >-
  Fetch JS-rendered webpages via jina.ai reader, returning clean markdown.
  TRIGGER when: WebFetch fails with empty/JS-only content, or URL matches a
  known JS-heavy site (developer.salesforce.com, help.salesforce.com,
  trailhead.salesforce.com, developer.mozilla.org, medium.com, docs.google.com).
  DO NOT TRIGGER when: fetching raw APIs, GitHub (use gh CLI), or plain-text URLs.
allowed-tools: Bash(curl *r.jina.ai*), Bash(sed *)
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

Replace `<the full URL>` with the target URL (including `https://`). Always use the full pipeline — never curl without the sed cleanup, as raw output wastes context window.

```bash
URL="<the full URL>"
BASE_PATH="${URL%/*}/"
BASE_DOMAIN="$(echo "$URL" | sed -E 's|(https?://[^/]+).*|\1|')"

curl -sf "https://r.jina.ai/${URL}" \
  -H "Authorization: Bearer $JINA_API_KEY" \
  -H "X-Return-Format: markdown" \
  -H "X-Retain-Images: none" \
| sed \
  -e "s|${BASE_PATH}||g" \
  -e "s|${BASE_DOMAIN}||g" \
  -e 's/\[\]([^)]*)//g' \
| cat -s
```

What the sed cleanup does:
1. **Strip base path** — removes the directory portion of the request URL. Turns `[text](https://example.com/docs/guide/page.htm)` into `[text](page.htm)`.
2. **Strip domain** — catches remaining same-domain URLs that didn't share the exact base path, reducing them to site-relative paths.
3. **Remove empty anchors** — Jina emits `[](url)` self-referencing links that carry no content.
4. **Collapse blank lines** — `cat -s` reduces runs of blank lines to one.

If the curl fails (exit code non-zero) and `$JINA_API_KEY` is empty, the key is missing — see setup below.

## No API key

If the key is missing, do not attempt unauthenticated requests. Instead:

1. Tell the user they need a Jina API key (free at https://jina.ai/reader).
2. Ask if they'd like you to set it up — they can paste the key and you'll add it to `~/.claude/settings.json` under the `env` key (e.g. `"env": { "JINA_API_KEY": "<key>" }`).
3. After writing the key, the user will need to restart Claude Code for the env var to take effect.
