#!/bin/bash
#
# Export marketing screenshots from the Next.js generator using Chrome headless.
# Requires: Next.js dev server running at localhost:3456
#
set -euo pipefail

CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
BASE="http://localhost:3456"
OUTBASE="/Users/tmaier/iron_rep/marketing/exports"

# All required sizes
declare -a SIZES=(
  "1284x2778"   # iPhone 6.5" (App Store / Play Store)
  "1320x2868"   # iPhone 6.9"
  "2048x2732"   # iPad 12.9" / 13"
)

SLIDES=6

for size in "${SIZES[@]}"; do
  W="${size%x*}"
  H="${size#*x}"
  DIR="$OUTBASE/$size"
  mkdir -p "$DIR"
  echo "=== Exporting $size ==="

  for i in $(seq 0 $((SLIDES-1))); do
    IDX=$(printf "%02d" $((i+1)))
    # Use Chrome to screenshot the page with a specific slide query param
    "$CHROME" --headless=new \
      --screenshot="$DIR/${IDX}.png" \
      --window-size="${W},${H}" \
      --hide-scrollbars \
      --disable-gpu \
      "${BASE}/export?slide=${i}&w=${W}&h=${H}" 2>/dev/null
    echo "  ${IDX}.png"
  done
done

echo ""
echo "=== Done ==="
ls -la "$OUTBASE"/*/
