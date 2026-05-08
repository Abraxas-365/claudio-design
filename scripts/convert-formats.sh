#!/usr/bin/env bash
# Convert MP4 animation to 60fps MP4 and optimized GIF.
#
# Usage:
#   bash convert-formats.sh <input.mp4> [--json]
#
# Output (next to input):
#   <basename>-60fps.mp4   — motion-interpolated 60fps
#   <basename>.gif         — palette-optimized GIF (max 12s, 15fps, 800px)
#
# Requires: ffmpeg on PATH.
#
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INPUT="$1"
JSON_MODE=false
[[ "$*" == *--json* ]] && JSON_MODE=true

json_result() {
  if $JSON_MODE; then
    echo "$1"
  fi
}

fail() {
  if $JSON_MODE; then
    echo "{\"success\": false, \"error\": \"$1\"}"
  else
    echo "✗ $1" >&2
  fi
  exit 1
}

if [ -z "$INPUT" ] || [ ! -f "$INPUT" ]; then
  fail "Usage: bash convert-formats.sh <input.mp4>"
fi

command -v ffmpeg >/dev/null 2>&1 || fail "ffmpeg not found on PATH"

DIR="$(cd "$(dirname "$INPUT")" && pwd)"
NAME="$(basename "$INPUT" .mp4)"
OUT_60="$DIR/${NAME}-60fps.mp4"
OUT_GIF="$DIR/${NAME}.gif"

# ── 60fps interpolation ────────────────────────────────────────────
$JSON_MODE || echo "▸ Generating 60fps version…"
ffmpeg -y -loglevel error \
  -i "$INPUT" \
  -filter:v "minterpolate=fps=60:mi_mode=mci:mc_mode=aobmc:vsbmc=1" \
  -c:v libx264 -pix_fmt yuv420p -crf 18 -preset medium \
  -movflags +faststart \
  "$OUT_60"

SIZE_60=$(du -h "$OUT_60" | cut -f1)
$JSON_MODE || echo "  ✓ 60fps: $OUT_60 ($SIZE_60)"

# ── Palette-optimized GIF (max 12s, 15fps, 800px wide) ─────────────
$JSON_MODE || echo "▸ Generating optimized GIF…"
PALETTE="$DIR/.palette-$$.png"
ffmpeg -y -loglevel error \
  -t 12 -i "$INPUT" \
  -vf "fps=15,scale=800:-1:flags=lanczos,palettegen=max_colors=128:stats_mode=diff" \
  "$PALETTE"
ffmpeg -y -loglevel error \
  -t 12 -i "$INPUT" -i "$PALETTE" \
  -lavfi "fps=15,scale=800:-1:flags=lanczos [x]; [x][1:v] paletteuse=dither=bayer:bayer_scale=3" \
  "$OUT_GIF"
rm -f "$PALETTE"

SIZE_GIF=$(du -h "$OUT_GIF" | cut -f1)
$JSON_MODE || echo "  ✓ GIF: $OUT_GIF ($SIZE_GIF)"

$JSON_MODE || echo "✓ All formats done"
json_result "{\"success\": true, \"mp4_60fps\": \"$OUT_60\", \"gif\": \"$OUT_GIF\"}"
