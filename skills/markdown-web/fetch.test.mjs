import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { matchSite, loadConfig, cleanMarkdown } from "./fetch.mjs";

describe("matchSite", () => {
  const config = {
    sites: [
      { domain: "developer.salesforce.com", content: { selector: "div.sf" } },
      { domain: "example.com", content: { selector: "main" } },
    ],
    defaults: { cookies: [], content: { selector: "body" } },
  };

  it("matches exact domain", () => {
    const site = matchSite(config, "https://developer.salesforce.com/docs/foo");
    assert.equal(site.domain, "developer.salesforce.com");
  });

  it("matches subdomain", () => {
    const site = matchSite(config, "https://sub.example.com/page");
    assert.equal(site.domain, "example.com");
  });

  it("falls back to defaults for unknown domain", () => {
    const site = matchSite(config, "https://unknown.org/page");
    assert.equal(site.content.selector, "body");
    assert.equal(site.domain, "unknown.org");
  });
});

describe("cleanMarkdown", () => {
  it("collapses excessive blank lines", () => {
    const result = cleanMarkdown("# Title\n\n\n\n\nParagraph");
    assert.equal(result, "# Title\n\nParagraph\n");
  });

  it("strips empty links but keeps text", () => {
    const result = cleanMarkdown("See [Type Class]() for details");
    assert.equal(result, "See Type Class for details\n");
  });

  it("leaves valid links intact", () => {
    const result = cleanMarkdown("See [docs](https://example.com)");
    assert.equal(result, "See [docs](https://example.com)\n");
  });

  it("trims whitespace", () => {
    const result = cleanMarkdown("  hello  \n\n  ");
    assert.equal(result, "hello\n");
  });
});

describe("integration", { skip: process.env.CI ? "skipped in CI" : false }, () => {
  it("fetches Salesforce Type class docs", async () => {
    const { execFile } = await import("node:child_process");
    const { promisify } = await import("node:util");
    const exec = promisify(execFile);
    const { fileURLToPath } = await import("node:url");
    const { dirname, join } = await import("node:path");

    const __dirname = dirname(fileURLToPath(import.meta.url));
    const script = join(__dirname, "fetch.mjs");
    const url = "https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_methods_system_type.htm";

    const { stdout } = await exec("node", [script, url], { timeout: 30000 });

    assert.ok(stdout.includes("# Type Class"), "should have page title");
    assert.ok(stdout.includes("## Namespace"), "should have namespace heading");
    assert.ok(stdout.includes("forName"), "should mention forName method");
    assert.ok(!stdout.includes("ullinks"), "should not contain TOC list class");
    assert.ok(stdout.includes("```"), "should have fenced code blocks");
  });
});
