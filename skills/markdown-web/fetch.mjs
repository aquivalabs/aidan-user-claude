#!/usr/bin/env node

import { chromium } from "playwright";
import TurndownService from "turndown";
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

const __dirname = dirname(fileURLToPath(import.meta.url));

export function loadConfig() {
  return JSON.parse(readFileSync(join(__dirname, "sites.json"), "utf-8"));
}

export function matchSite(config, url) {
  const hostname = new URL(url).hostname;
  const site = config.sites.find(
    (s) => hostname === s.domain || hostname.endsWith(`.${s.domain}`)
  );
  if (site) return site;
  return { domain: hostname, ...config.defaults };
}

export function cleanMarkdown(md) {
  return (
    md
      .replace(/\n{3,}/g, "\n\n")
      .replace(/\[([^\]]*)\]\(\s*\)/g, "$1")
      .trim() + "\n"
  );
}

async function fetchPage(url) {
  const config = loadConfig();
  const site = matchSite(config, url);
  const content = site.content;

  const browser = await chromium.launch({ headless: true });
  try {
    const context = await browser.newContext();
    if (site.cookies?.length) {
      await context.addCookies(site.cookies);
    }

    const page = await context.newPage();
    await page.goto(url, { waitUntil: "load", timeout: 30000 });

    // Wait for content to render inside shadow DOM
    await page.waitForFunction(
      ({ shadowPath = [], waitFor }) => {
        let root = document;
        for (const tag of shadowPath) {
          const el = root.querySelector(tag);
          if (!el?.shadowRoot) return false;
          root = el.shadowRoot;
        }
        return !!root.querySelector(waitFor);
      },
      content,
      { timeout: 15000 }
    );

    // Wait for code blocks to render (they load lazily after shadow DOM)
    await page.waitForFunction(
      ({ shadowPath = [] }) => {
        let root = document;
        for (const tag of shadowPath) {
          const el = root.querySelector(tag);
          if (!el?.shadowRoot) return false;
          root = el.shadowRoot;
        }
        const cbs = root.querySelectorAll("dx-code-block");
        if (cbs.length === 0) return true; // no code blocks to wait for
        // Wait until at least the first code block has rendered content
        const first = cbs[0].shadowRoot?.querySelector(".code-block-content pre");
        return !!first;
      },
      content,
      { timeout: 10000 }
    ).catch(() => {}); // non-fatal — page may have no code blocks

    // Extract HTML from shadow DOM
    const html = await page.evaluate(
      ({ shadowPath = [], selector, removeSelectors = [] }) => {
        let root = document;
        for (const tag of shadowPath) {
          root = root.querySelector(tag).shadowRoot;
        }

        const container = root.querySelector(selector);
        if (!container) throw new Error(`Selector "${selector}" not found`);

        for (const sel of removeSelectors) {
          for (const el of container.querySelectorAll(sel)) {
            el.remove();
          }
        }

        // Inline dx-code-block shadow content before serializing
        for (const cb of container.querySelectorAll("dx-code-block")) {
          const cbc = cb.shadowRoot?.querySelector(".code-block-content pre code");
          if (cbc) {
            // Extract text from .line spans, skipping line number spans
            const lines = cbc.querySelectorAll(".line");
            const text = lines.length
              ? Array.from(lines).map((l) => l.textContent).join("\n")
              : cbc.textContent;
            const pre = document.createElement("pre");
            const codeEl = document.createElement("code");
            codeEl.textContent = text;
            pre.appendChild(codeEl);
            cb.replaceWith(pre);
          }
        }

        return container.innerHTML;
      },
      content
    );

    const turndown = new TurndownService({
      headingStyle: "atx",
      codeBlockStyle: "fenced",
    });

    return cleanMarkdown(turndown.turndown(html));
  } finally {
    await browser.close();
  }
}

// CLI entry point — skip when imported as a module
const isCLI =
  process.argv[1] &&
  fileURLToPath(import.meta.url) === process.argv[1];

if (isCLI) {
  const url = process.argv[2];
  if (!url) {
    console.error("Usage: node fetch.mjs <url>");
    process.exit(1);
  }
  const md = await fetchPage(url);
  process.stdout.write(md);
}
