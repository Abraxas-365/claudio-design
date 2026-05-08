#!/usr/bin/env node
/**
 * export-pdf.mjs — Export multi-file slide deck to a single vector PDF.
 *
 * Usage:
 *   node export-pdf.mjs --slides <dir> --out <file.pdf> [--width 1920] [--height 1080] [--json]
 *
 * Features:
 *   - Text preserved as vector (copyable, searchable)
 *   - Background/graphics pixel-perfect (Playwright Chromium rendering)
 *   - No HTML modifications required
 *   - Zero visual loss (PDF = browser print output)
 *
 * With --json flag, outputs structured JSON:
 *   {"success": true, "output_path": "/path/to/output.pdf", "pages": 5, "size_kb": 1234}
 *
 * Dependencies: playwright pdf-lib
 *   npm install playwright pdf-lib
 */

import { chromium } from 'playwright';
import { PDFDocument } from 'pdf-lib';
import fs from 'fs/promises';
import path from 'path';

const JSON_MODE = process.argv.includes('--json');

function jsonResult(obj) {
  if (JSON_MODE) process.stdout.write(JSON.stringify(obj) + '\n');
}

function fail(msg) {
  if (JSON_MODE) {
    jsonResult({ success: false, error: msg });
    process.exit(1);
  }
  console.error(msg);
  process.exit(1);
}

function parseArgs() {
  const args = { width: 1920, height: 1080 };
  const a = process.argv.slice(2).filter(x => x !== '--json');
  for (let i = 0; i < a.length; i += 2) {
    const k = a[i].replace(/^--/, '');
    args[k] = a[i + 1];
  }
  if (!args.slides || !args.out) {
    fail('Usage: node export-pdf.mjs --slides <dir> --out <file.pdf> [--width 1920] [--height 1080] [--json]');
  }
  args.width = parseInt(args.width);
  args.height = parseInt(args.height);
  return args;
}

async function main() {
  const { slides, out, width, height } = parseArgs();
  const slidesDir = path.resolve(slides);
  const outFile = path.resolve(out);

  let files;
  try {
    files = (await fs.readdir(slidesDir))
      .filter(f => f.endsWith('.html'))
      .sort();
  } catch (e) {
    fail(`Cannot read slides directory: ${slidesDir}`);
  }

  if (!files.length) {
    fail(`No .html files found in ${slidesDir}`);
  }
  if (!JSON_MODE) console.log(`Found ${files.length} slides in ${slidesDir}`);

  let browser;
  try {
    browser = await chromium.launch();
  } catch (e) {
    fail('Playwright not found. Run: npx playwright install chromium');
  }

  const ctx = await browser.newContext({ viewport: { width, height } });

  // Render each HTML to its own PDF buffer
  const pageBuffers = [];
  for (const f of files) {
    const page = await ctx.newPage();
    const url = 'file://' + path.join(slidesDir, f);
    await page.goto(url, { waitUntil: 'networkidle' }).catch(() => page.goto(url));
    await page.waitForTimeout(1200); // web-font paint
    await page.emulateMedia({ media: 'screen' });
    const buf = await page.pdf({
      width: `${width}px`,
      height: `${height}px`,
      printBackground: true,
      margin: { top: 0, right: 0, bottom: 0, left: 0 },
      preferCSSPageSize: false,
    });
    pageBuffers.push(buf);
    await page.close();
    if (!JSON_MODE) console.log(`  [${pageBuffers.length}/${files.length}] ${f}`);
  }

  await browser.close();

  // Merge into a single PDF
  const merged = await PDFDocument.create();
  for (const buf of pageBuffers) {
    const src = await PDFDocument.load(buf);
    const copied = await merged.copyPages(src, src.getPageIndices());
    copied.forEach(p => merged.addPage(p));
  }
  const bytes = await merged.save();
  await fs.writeFile(outFile, bytes);

  const kb = (bytes.byteLength / 1024).toFixed(0);
  if (!JSON_MODE) {
    console.log(`\n✓ Wrote ${outFile}  (${kb} KB, ${files.length} pages, vector)`);
  }
  jsonResult({
    success: true,
    output_path: outFile,
    pages: files.length,
    size_kb: parseInt(kb),
  });
}

main().catch(e => fail(e.message || String(e)));
