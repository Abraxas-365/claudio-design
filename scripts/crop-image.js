#!/usr/bin/env node
/**
 * crop-image.js — Read a PNG file, optionally crop to 7000px max per dimension,
 * and output base64-encoded PNG as JSON.
 *
 * Usage: node crop-image.js <image-path>
 *
 * Output (stdout, JSON):
 *   { success: true, data: "<base64>", width: N, height: N, was_cropped: bool, crop_warning?: string }
 *   { success: false, error: "<message>" }
 *
 * Uses `sharp` for cropping if available; falls back to returning the original
 * image with a warning when the image exceeds the limit.
 */

'use strict';

const fs   = require('fs');
const path = require('path');

const MAX_DIM  = 7000;
const imagePath = process.argv[2];

if (!imagePath) {
  console.log(JSON.stringify({ success: false, error: 'Usage: crop-image.js <image-path>' }));
  process.exit(1);
}

async function main() {
  let data;
  try {
    data = fs.readFileSync(imagePath);
  } catch (e) {
    console.log(JSON.stringify({ success: false, error: 'Cannot read file: ' + e.message }));
    process.exit(1);
  }

  // Parse PNG dimensions from the IHDR chunk
  // PNG layout: 8-byte signature + 4-byte length + 4-byte "IHDR" + 4-byte width + 4-byte height + ...
  let width = 0, height = 0;
  if (data.length >= 24) {
    width  = data.readUInt32BE(16);
    height = data.readUInt32BE(20);
  }

  const needsCrop = width > MAX_DIM || height > MAX_DIM;

  if (needsCrop) {
    // Try to crop using sharp
    try {
      const sharp = require('sharp');
      const cropW = Math.min(width,  MAX_DIM);
      const cropH = Math.min(height, MAX_DIM);
      const cropped = await sharp(data)
        .extract({ left: 0, top: 0, width: cropW, height: cropH })
        .png()
        .toBuffer();
      console.log(JSON.stringify({
        success:      true,
        data:         cropped.toString('base64'),
        width:        cropW,
        height:       cropH,
        was_cropped:  true,
        crop_warning: `Image was ${width}x${height}px, cropped to ${cropW}x${cropH}px`,
      }));
      return;
    } catch (_) {
      // sharp not available — return original with warning
      console.log(JSON.stringify({
        success:      true,
        data:         data.toString('base64'),
        width,
        height,
        was_cropped:  false,
        crop_warning: `Image is ${width}x${height}px (exceeds ${MAX_DIM}px limit) — install sharp for automatic cropping`,
      }));
      return;
    }
  }

  // Image is within limits — return as-is
  console.log(JSON.stringify({
    success:     true,
    data:        data.toString('base64'),
    width,
    height,
    was_cropped: false,
  }));
}

main().catch(err => {
  console.log(JSON.stringify({ success: false, error: err.message }));
  process.exit(1);
});
