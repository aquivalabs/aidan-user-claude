#!/usr/bin/env bash
# Jina Reader fetch for developer.salesforce.com — strips nav chrome, footer,
# method index, type-link boilerplate, and "Requires Chatter" sections.
# Usage: fetch-salesforce.sh <url>
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
| awk '
  # SF docs produce two setext h1s (=== underlines):
  #   1st = <title> tag, 2nd = actual content heading.
  # Print from the 2nd h1 to the footer marker.
  /^={3,}$/ { h1++; if (h1==2) { p=1; print prev; print; next } }
  p && /^DEVELOPER CENTERS$/ { exit }
  p { print }
  { prev=$0 }
' \
| awk '
  # Strip the method index: skip from the "## <Name> Methods" heading
  # (a setext h2 followed by --- underline) through to the first ###.
  /^-{3,}$/ && prev ~ /[Mm]ethods/ { in_index=1; next }
  in_index && /^### / { in_index=0 }
  in_index { next }

  # Strip "#### Requires Chatter" heading, blank line, and answer line.
  /^#### Requires Chatter/ { skip_remaining=2; next }
  skip_remaining > 0 { skip_remaining--; next }

  { print; prev=$0 }
' \
| sed -E 's/\[([^]]+)\]\([^)]*("[^"]*")?[^)]*\)/\1/g' \
| sed -E $'s/([.)])([a-z][a-zA-Z]+ Type:)/\\1\\\n\\\n\\2/g' \
| sed -E $'s/ Type: (String|Integer|Boolean|Long|Double|List|Map|Set|Object|ConnectApi\\.[A-Za-z.]+)/\\\nType: \\1\\\n/g' \
| cat -s
