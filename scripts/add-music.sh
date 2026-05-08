#!/usr/bin/env bash
# Mix a BGM track into an MP4 video.
#
# Usage:
#   bash add-music.sh <input.mp4> [--mood=<name>] [--music=<path>] [--out=<path>] [--json]
#
# Mood library (in ../assets/audio/, matching bgm-<mood>.mp3):
#   tech              — Apple Silicon / product keynote vibe, minimal synth+piano (default)
#   ad                — upbeat modern, clear build + drop, social-media ad energy
#   educational       — warm, patient, inviting learning tone
#   educational-alt   — alternate take of educational
#   tutorial          — lo-fi background, stays out of voiceover's way
#   tutorial-alt      — alternate take of tutorial
#
# Flags (all optional):
#   --mood=<name>     pick a preset from the library (default: tech)
#   --music=<path>    override with your own audio file (wins over --mood)
#   --out=<path>      output path (default: <input-basename>-bgm.mp4)
#   --json            output structured JSON result
#
# Behavior:
#   - Music is trimmed to match video duration
#   - 0.3s fade in, 1.0s fade out (avoids hard cuts)
#   - Video stream copied (no re-encode), audio AAC 192k
#
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ASSETS_DIR="$SCRIPT_DIR/../assets/audio"
JSON_MODE=false

# ── Parse args ───────────────────────────────────────────────────────
INPUT=""
MOOD="tech"
CUSTOM_MUSIC=""
OUTPUT=""
POSITIONAL=()

for arg in "$@"; do
  case "$arg" in
    --mood=*)  MOOD="${arg#*=}" ;;
    --music=*) CUSTOM_MUSIC="${arg#*=}" ;;
    --out=*)   OUTPUT="${arg#*=}" ;;
    --json)    JSON_MODE=true ;;
    *)         POSITIONAL+=("$arg") ;;
  esac
done

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

# Legacy positional: <input> [music] [output]
INPUT="${POSITIONAL[0]}"
[ -z "$CUSTOM_MUSIC" ] && [ -n "${POSITIONAL[1]}" ] && CUSTOM_MUSIC="${POSITIONAL[1]}"
[ -z "$OUTPUT" ]       && [ -n "${POSITIONAL[2]}" ] && OUTPUT="${POSITIONAL[2]}"

if [ -z "$INPUT" ] || [ ! -f "$INPUT" ]; then
  fail "Usage: bash add-music.sh <input.mp4> [--mood=<name>] [--music=<path>] [--out=<path>] [--json]"
fi

command -v ffmpeg >/dev/null 2>&1 || fail "ffmpeg not found on PATH"

# ── Resolve music source: --music wins, else --mood ─────────────────
if [ -n "$CUSTOM_MUSIC" ]; then
  MUSIC="$CUSTOM_MUSIC"
  SOURCE_LABEL="custom: $MUSIC"
else
  MUSIC="$ASSETS_DIR/bgm-${MOOD}.mp3"
  SOURCE_LABEL="mood: $MOOD"
fi

if [ ! -f "$MUSIC" ]; then
  AVAIL=$(ls "$ASSETS_DIR" 2>/dev/null | grep -E '^bgm-.*\.mp3$' | sed 's/^bgm-//;s/\.mp3$//' | tr '\n' ' ')
  fail "Music not found: $MUSIC. Available moods: $AVAIL"
fi

# ── Resolve output path ─────────────────────────────────────────────
INPUT_DIR="$(cd "$(dirname "$INPUT")" && pwd)"
INPUT_NAME="$(basename "$INPUT" .mp4)"
[ -z "$OUTPUT" ] && OUTPUT="$INPUT_DIR/$INPUT_NAME-bgm.mp4"

# ── Measure video duration, compute fade-out start ──────────────────
DURATION=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$INPUT")
if [ -z "$DURATION" ]; then
  fail "Could not read video duration"
fi
FADE_OUT_START=$(awk "BEGIN { d = $DURATION - 1; if (d < 0) d = 0; print d }")

$JSON_MODE || echo "▸ Mixing BGM into video"
$JSON_MODE || echo "  input:    $INPUT"
$JSON_MODE || echo "  music:    $SOURCE_LABEL"
$JSON_MODE || echo "  duration: ${DURATION}s"
$JSON_MODE || echo "  output:   $OUTPUT"

ffmpeg -y -loglevel error \
  -i "$INPUT" \
  -i "$MUSIC" \
  -filter_complex "[1:a]atrim=0:${DURATION},asetpts=PTS-STARTPTS,afade=t=in:st=0:d=0.3,afade=t=out:st=${FADE_OUT_START}:d=1[a]" \
  -map 0:v -map "[a]" \
  -c:v copy -c:a aac -b:a 192k -shortest \
  "$OUTPUT"

SIZE=$(du -h "$OUTPUT" | cut -f1)
$JSON_MODE || echo "✓ Done: $OUTPUT ($SIZE)"
json_result "{\"success\": true, \"output_path\": \"$OUTPUT\", \"duration\": $DURATION}"
