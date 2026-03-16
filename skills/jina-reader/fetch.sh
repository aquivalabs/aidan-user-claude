#!/usr/bin/env bash
# Generic Jina Reader fetch — strips URLs and empty anchors, collapses blank lines.
# Usage: fetch.sh <url>
set -euo pipefail

URL="$1"
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
