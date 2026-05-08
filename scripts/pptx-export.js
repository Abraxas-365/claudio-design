#!/usr/bin/env node
/**
 * pptx-export.js — thin CLI wrapper around html2pptx.js
 * Usage: node pptx-export.js <html_file> <output_path>
 * Output: single JSON line on stdout
 */
const path = require("path");
const [, , htmlFile, outputPath] = process.argv;

if (!htmlFile || !outputPath) {
  console.log(JSON.stringify({ success: false, error: "Usage: pptx-export.js <html_file> <output_path>" }));
  process.exit(1);
}

let pptxgen, h2p;
try {
  pptxgen = require("pptxgenjs");
  h2p = require(path.join(__dirname, "html2pptx.js"));
} catch (e) {
  console.log(JSON.stringify({ success: false, error: "Missing dependency: " + e.message + ". Run: npm install pptxgenjs sharp" }));
  process.exit(1);
}

(async () => {
  try {
    const pptx = new pptxgen();
    pptx.layout = "LAYOUT_16x9";
    await h2p(htmlFile, pptx);
    await pptx.writeFile(outputPath);
    console.log(JSON.stringify({ success: true, output_path: outputPath }));
  } catch (e) {
    console.log(JSON.stringify({ success: false, error: e.message }));
  }
})();
