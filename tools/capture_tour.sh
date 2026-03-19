#!/bin/bash
#
# IronRep Screenshot Tour Capture Script
#
# 1. Launch app: xcrun simctl launch booted com.tmmr.ironRep
# 2. Run: bash tools/capture_tour.sh
# 3. In app: Settings > Debug > Screenshot Tour
#
set -euo pipefail

DEVICE="${1:-$(xcrun simctl list devices booted -j | python3 -c "
import json,sys
for r,ds in json.load(sys.stdin).get('devices',{}).items():
 for d in ds:
  if d.get('state')=='Booted': print(d['udid']); sys.exit(0)
")}"

OUTDIR="$(cd "$(dirname "$0")/.." && pwd)/marketing/screenshots-project/public/screenshots"
mkdir -p "$OUTDIR"

get_marker_dir() {
  xcrun simctl listapps "$DEVICE" 2>/dev/null | python3 -c "
import sys,re
t=sys.stdin.read()
m=re.search(r'DataContainer = \"file://(.*?)\";',t[t.find('iron_rep'):])
if m: print(m.group(1)+'/Documents/screenshot_markers')
" 2>/dev/null
}

SCREENS="01_workout 02_history 03_progress 04_exercises 05_exercise_progress 06_plan_editor"

# Clean old screenshots
for s in $SCREENS; do rm -f "$OUTDIR/${s}.png" 2>/dev/null; done

# Clean old markers
MDIR=$(get_marker_dir)
[ -n "$MDIR" ] && rm -rf "$MDIR" 2>/dev/null

echo "=== IronRep Screenshot Capture ==="
echo "Device: $DEVICE"
echo "Output: $OUTDIR"
echo ""
echo ">>> Settings > Debug > Screenshot Tour"
echo ""

CAPTURED=0
for i in $(seq 1 600); do
  # Re-resolve marker dir each iteration (handles reinstall)
  MDIR=$(get_marker_dir)
  [ -z "$MDIR" ] && sleep 0.3 && continue

  for name in $SCREENS; do
    if [ -f "$MDIR/$name" ] && [ ! -f "$OUTDIR/${name}.png" ]; then
      sleep 0.3
      xcrun simctl io "$DEVICE" screenshot "$OUTDIR/${name}.png" 2>/dev/null
      CAPTURED=$((CAPTURED + 1))
      echo "  [$CAPTURED/6] ${name}.png"
    fi
  done

  if [ -f "$MDIR/DONE" ]; then
    echo ""
    echo ">>> Tour complete! $CAPTURED screenshots."
    break
  fi
  sleep 0.3
done

echo ""
ls -la "$OUTDIR"/0*.png 2>/dev/null || echo "No screenshots captured"
