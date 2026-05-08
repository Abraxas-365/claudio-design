#!/usr/bin/env node
/**
 * HTML animation → MP4 via Playwright recordVideo + ffmpeg.
 *
 * Requires: playwright (`npm install playwright`), ffmpeg on PATH.
 *
 * Usage:
 *   node render-video.js <html-file> \
 *     [--duration=30] [--width=1920] [--height=1080] \
 *     [--trim=<seconds>] [--fontwait=1.5] [--readytimeout=8] \
 *     [--keep-chrome] [--json]
 *
 * With --json flag, outputs structured JSON result to stdout:
 *   {"success": true, "output_path": "/path/to/output.mp4", "duration": 3.2, "size_mb": 1.5}
 *   {"success": false, "error": "Playwright not found. Run: npx playwright install chromium"}
 *
 * Design:
 *   1. Warmup context (no record) — caches fonts/assets, closes cleanly
 *   2. Record context (fresh, recordVideo ON) — WebM starts writing at
 *      context creation. Babel-standalone compile + React mount +
 *      fonts.ready can take 1.5-3s, during which WebM writes black frames.
 *      We measure this by waiting for window.__ready (set by animations.jsx
 *      Stage component after first paint), then trim exactly that offset.
 *   3. addInitScript injects CSS hiding "chrome" elements (progress bar,
 *      replay button, masthead, footer, etc.) that are fine for human
 *      debugging but shouldn't appear in exported video.
 *
 * Animation-ready signal:
 *   Set `window.__ready = true` in your HTML after first paint.
 *   If you use animations.jsx, Stage does this automatically.
 *
 * Output: next to the HTML file, same basename with .mp4 suffix (or --output=<path>).
 */

const { chromium } = require('playwright');
const path = require('path');
const fs = require('fs');
const { spawnSync } = require('child_process');

function arg(name, def) {
  const p = process.argv.find(a => a.startsWith('--' + name + '='));
  return p ? p.slice(name.length + 3) : def;
}
function hasFlag(name) {
  return process.argv.includes('--' + name);
}

const JSON_OUTPUT = hasFlag('json');

function jsonResult(obj) {
  if (JSON_OUTPUT) {
    process.stdout.write(JSON.stringify(obj) + '\n');
  }
}

function fail(msg) {
  if (JSON_OUTPUT) {
    jsonResult({ success: false, error: msg });
    process.exit(1);
  }
  console.error(msg);
  process.exit(1);
}

const HTML_FILE = process.argv.find(a => !a.startsWith('--') && a !== process.argv[0] && a !== process.argv[1]);
if (!HTML_FILE) {
  fail('Usage: node render-video.js <html-file> [--duration=30] [--width=1920] [--height=1080] [--json]');
}

const DURATION  = parseFloat(arg('duration', '30'));
const WIDTH     = parseInt(arg('width', '1920'));
const HEIGHT    = parseInt(arg('height', '1080'));
const TRIM_OVERRIDE = arg('trim', null);
const FONT_WAIT = parseFloat(arg('fontwait', '1.5'));
const READY_TIMEOUT = parseFloat(arg('readytimeout', '8'));
const KEEP_CHROME = hasFlag('keep-chrome');
const OUTPUT_OVERRIDE = arg('output', null);

const HTML_ABS = path.resolve(HTML_FILE);
const BASENAME = path.basename(HTML_FILE, path.extname(HTML_FILE));
const DIR      = path.dirname(HTML_ABS);
const TMP_DIR  = path.join(DIR, '.video-tmp-' + Date.now() + '-' + process.pid);
const MP4_OUT  = OUTPUT_OVERRIDE ? path.resolve(OUTPUT_OVERRIDE) : path.join(DIR, BASENAME + '.mp4');

// CSS to hide "chrome" elements during recording.
const HIDE_CHROME_CSS = `
  .no-record,
  .progress, .progress-bar,
  .counter, .tCur,
  .phases, .phase-label, .phase,
  .replay, button.replay,
  .masthead, .kicker, .title,
  .footer,
  [data-role="chrome"], [data-record="hidden"] {
    display: none !important;
  }
`;

if (!JSON_OUTPUT) {
  console.log(`▸ Rendering: ${HTML_FILE}`);
  console.log(`  size: ${WIDTH}x${HEIGHT} · duration: ${DURATION}s · hide-chrome: ${!KEEP_CHROME}`);
  console.log(`  output: ${MP4_OUT}`);
}

(async () => {
  // Check prerequisites
  const ffmpegCheck = spawnSync('ffmpeg', ['-version'], { stdio: 'pipe' });
  if (ffmpegCheck.status !== 0) {
    fail('ffmpeg not found on PATH. Install: brew install ffmpeg (macOS) or apt install ffmpeg (Linux)');
  }

  if (!fs.existsSync(HTML_ABS)) {
    fail(`HTML file not found: ${HTML_ABS}`);
  }

  fs.mkdirSync(TMP_DIR, { recursive: true });

  let browser;
  try {
    browser = await chromium.launch();
  } catch (e) {
    fail('Playwright not found. Run: npx playwright install chromium');
  }
  const url = 'file://' + HTML_ABS;

  // ── Phase 1: WARMUP (no recording, caches fonts/assets) ─────────────
  if (!JSON_OUTPUT) console.log('▸ Warmup (caching fonts)…');
  const warmupCtx = await browser.newContext({
    viewport: { width: WIDTH, height: HEIGHT },
  });
  const warmupPage = await warmupCtx.newPage();
  await warmupPage.goto(url, { waitUntil: 'load', timeout: 60000 });
  await warmupPage.waitForTimeout(FONT_WAIT * 1000);
  await warmupCtx.close();

  // ── Phase 2: RECORD (fresh context, animation from t=0) ─────────────
  if (!JSON_OUTPUT) console.log('▸ Recording (clean start)…');
  const recordCtx = await browser.newContext({
    viewport: { width: WIDTH, height: HEIGHT },
    deviceScaleFactor: 1,
    recordVideo: {
      dir: TMP_DIR,
      size: { width: WIDTH, height: HEIGHT },
    },
  });

  await recordCtx.addInitScript(() => { window.__recording = true; });

  if (!KEEP_CHROME) {
    await recordCtx.addInitScript(css => {
      const HIDE_MARK = 'data-video-hidden';

      function injectStyle() {
        const style = document.createElement('style');
        style.setAttribute('data-inject', 'render-video-chrome-hide');
        style.textContent = css;
        (document.head || document.documentElement).appendChild(style);
      }

      function hideChromeBars() {
        const vh = window.innerHeight;
        document.querySelectorAll('div, nav, header, footer, section, aside')
          .forEach(el => {
            if (el.hasAttribute(HIDE_MARK)) return;
            if (el.dataset.recordKeep === 'true') return;
            const s = getComputedStyle(el);
            if (s.position !== 'fixed' && s.position !== 'sticky') return;
            const r = el.getBoundingClientRect();
            if (r.height > vh * 0.25) return;
            const atBottom = r.bottom >= vh - 30;
            const atTop = r.top <= 30 && r.height < 80;
            if (!atBottom && !atTop) return;
            const txt = el.textContent || '';
            const hasBtn = !!el.querySelector('button, [role="button"]');
            const hasCtrls = /[⏸▶⏮⏭↻↺↩↪]|\d+\.\d+\s*s/.test(txt);
            if (hasBtn || hasCtrls) {
              el.style.setProperty('display', 'none', 'important');
              el.setAttribute(HIDE_MARK, '1');
            }
          });
      }

      const start = () => {
        injectStyle();
        hideChromeBars();
        const obs = new MutationObserver(hideChromeBars);
        obs.observe(document.body, { childList: true, subtree: true });
        setTimeout(() => obs.disconnect(), 6000);
      };

      if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', start, { once: true });
      } else {
        start();
      }
    }, HIDE_CHROME_CSS);
  }

  const T0 = Date.now();
  const page = await recordCtx.newPage();
  await page.goto(url, { waitUntil: 'load', timeout: 60000 });

  let animationStartSec;
  const hasReady = await page.waitForFunction(
    () => window.__ready === true,
    { timeout: READY_TIMEOUT * 1000 },
  ).then(() => true).catch(() => false);

  if (hasReady) {
    const seekCorrected = await page.evaluate(() => {
      if (typeof window.__seek === 'function') {
        window.__seek(0);
        return true;
      }
      return false;
    });
    if (seekCorrected) {
      await page.evaluate(() => new Promise(r => requestAnimationFrame(() => requestAnimationFrame(r))));
    }
    animationStartSec = (Date.now() - T0) / 1000;
    if (!JSON_OUTPUT) console.log(`▸ Ready at ${animationStartSec.toFixed(2)}s`);
  } else {
    await page.waitForTimeout(FONT_WAIT * 1000);
    animationStartSec = (Date.now() - T0) / 1000;
    if (!JSON_OUTPUT) {
      console.log(`  ⚠️  WARNING: window.__ready signal not detected within ${READY_TIMEOUT}s`);
      console.log(`     Using fallback trim of ${animationStartSec.toFixed(2)}s + 0.5s safety margin.`);
    }
  }

  await page.waitForTimeout(DURATION * 1000 + 300);

  await page.close();
  await recordCtx.close();
  await browser.close();

  const webmFiles = fs.readdirSync(TMP_DIR).filter(f => f.endsWith('.webm'));
  if (webmFiles.length === 0) {
    fail('No webm produced by Playwright recording');
  }
  const webmPath = path.join(TMP_DIR, webmFiles[0]);

  const resolvedTrim = TRIM_OVERRIDE !== null
    ? parseFloat(TRIM_OVERRIDE)
    : animationStartSec + (hasReady ? 0.05 : 0.5);

  if (!JSON_OUTPUT) console.log(`▸ ffmpeg: trim=${resolvedTrim.toFixed(2)}s, encode H.264…`);
  const ffmpeg = spawnSync('ffmpeg', [
    '-y',
    '-ss', String(resolvedTrim),
    '-i', webmPath,
    '-t', String(DURATION),
    '-c:v', 'libx264',
    '-pix_fmt', 'yuv420p',
    '-crf', '18',
    '-preset', 'medium',
    '-movflags', '+faststart',
    MP4_OUT,
  ], { stdio: ['ignore', 'ignore', 'pipe'] });

  if (ffmpeg.status !== 0) {
    fail('ffmpeg encoding failed: ' + ffmpeg.stderr.toString().slice(-500));
  }

  fs.rmSync(TMP_DIR, { recursive: true, force: true });

  const mp4Size = (fs.statSync(MP4_OUT).size / 1024 / 1024).toFixed(1);
  if (!JSON_OUTPUT) {
    console.log(`✓ Done: ${MP4_OUT} (${mp4Size} MB)`);
  }
  jsonResult({
    success: true,
    output_path: MP4_OUT,
    duration: DURATION,
    size_mb: parseFloat(mp4Size),
  });
})().catch(e => {
  fail(e.message || String(e));
});
