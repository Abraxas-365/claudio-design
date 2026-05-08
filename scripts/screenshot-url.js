#!/usr/bin/env node
/**
 * screenshot-url.js — Take a full-page screenshot of a URL using Playwright
 * and output base64-encoded PNG as JSON.
 *
 * Usage: node screenshot-url.js <url> [WxH]
 *   url    — fully-qualified URL (http:// or https://)
 *   WxH    — optional viewport dimensions, e.g. "1440x900" (default: 1440x900)
 *
 * Output (stdout, JSON):
 *   { success: true, data: "<base64>", width: N, height: N }
 *   { success: false, error: "<message>" }
 *
 * Requires Node.js >= 18 and Playwright: npx playwright install chromium
 */

'use strict';

const { chromium } = require('playwright');

const url         = process.argv[2];
const viewportArg = process.argv[3];

if (!url) {
  console.log(JSON.stringify({ success: false, error: 'Usage: screenshot-url.js <url> [WxH]' }));
  process.exit(1);
}

async function main() {
  // Parse optional viewport argument (e.g. "1440x900" or "1920×1080")
  let width = 1440, height = 900;
  if (viewportArg) {
    const m = viewportArg.match(/^(\d+)[xX×](\d+)$/);
    if (m) {
      width  = parseInt(m[1], 10);
      height = parseInt(m[2], 10);
    }
  }

  const browser = await chromium.launch({
    args: ['--no-sandbox', '--disable-setuid-sandbox'],
  });

  try {
    const page = await browser.newPage();
    await page.setViewportSize({ width, height });
    await page.goto(url, { waitUntil: 'networkidle', timeout: 30000 });

    // Give JS-heavy pages a moment to settle
    try {
      await page.waitForFunction(() => document.readyState === 'complete', { timeout: 5000 });
    } catch (_) { /* already loaded */ }

    const screenshot = await page.screenshot({ fullPage: false });
    await browser.close();

    console.log(JSON.stringify({
      success: true,
      data:    screenshot.toString('base64'),
      width,
      height,
    }));
  } catch (e) {
    await browser.close().catch(() => {});
    console.log(JSON.stringify({ success: false, error: e.message }));
    process.exit(1);
  }
}

main().catch(err => {
  console.log(JSON.stringify({ success: false, error: err.message }));
  process.exit(1);
});
