#!/usr/bin/env bash
# Pull POSTER v2 fonts into Playa/Resources/Fonts/ at build time.
#
# These TTF files are not checked into git — we download the canonical
# copies from the upstream font repos on every CI run. Local devs can run
# this script the same way to refresh fonts.
#
# Run from the repo root: `bash scripts/fetch-fonts.sh`.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEST="$ROOT/Playa/Resources/Fonts"
mkdir -p "$DEST"

fetch() {
    local url="$1"
    local out="$2"
    if [ -f "$DEST/$out" ]; then
        echo "skip: $out (already present)"
        return
    fi
    echo "fetching: $out"
    curl -fsSL --retry 3 --retry-delay 2 -o "$DEST/$out" "$url"
}

# Unbounded — display family (Google Fonts, OFL)
UNBOUNDED_BASE="https://raw.githubusercontent.com/googlefonts/Unbounded/main/fonts/ttf"
fetch "$UNBOUNDED_BASE/Unbounded-Light.ttf"    Unbounded-Light.ttf
fetch "$UNBOUNDED_BASE/Unbounded-Regular.ttf"  Unbounded-Regular.ttf
fetch "$UNBOUNDED_BASE/Unbounded-Medium.ttf"   Unbounded-Medium.ttf
fetch "$UNBOUNDED_BASE/Unbounded-SemiBold.ttf" Unbounded-SemiBold.ttf
fetch "$UNBOUNDED_BASE/Unbounded-Bold.ttf"     Unbounded-Bold.ttf
fetch "$UNBOUNDED_BASE/Unbounded-Black.ttf"    Unbounded-Black.ttf

# Space Grotesk — body sans
SG_BASE="https://raw.githubusercontent.com/floriankarsten/space-grotesk/master/fonts/ttf"
fetch "$SG_BASE/SpaceGrotesk-Light.ttf"        SpaceGrotesk-Light.ttf
fetch "$SG_BASE/SpaceGrotesk-Regular.ttf"      SpaceGrotesk-Regular.ttf
fetch "$SG_BASE/SpaceGrotesk-Medium.ttf"       SpaceGrotesk-Medium.ttf
fetch "$SG_BASE/SpaceGrotesk-SemiBold.ttf"     SpaceGrotesk-SemiBold.ttf
fetch "$SG_BASE/SpaceGrotesk-Bold.ttf"         SpaceGrotesk-Bold.ttf

# JetBrains Mono — labels and metadata
JBM_BASE="https://raw.githubusercontent.com/JetBrains/JetBrainsMono/master/fonts/ttf"
fetch "$JBM_BASE/JetBrainsMono-Regular.ttf"    JetBrainsMono-Regular.ttf
fetch "$JBM_BASE/JetBrainsMono-Medium.ttf"     JetBrainsMono-Medium.ttf
fetch "$JBM_BASE/JetBrainsMono-SemiBold.ttf"   JetBrainsMono-SemiBold.ttf
fetch "$JBM_BASE/JetBrainsMono-Bold.ttf"       JetBrainsMono-Bold.ttf

# Instrument Serif — italic flourish only (no roman cut used)
fetch "https://raw.githubusercontent.com/Instrument/instrument-serif/main/fonts/ttf/InstrumentSerif-Italic.ttf" \
      InstrumentSerif-Italic.ttf

echo "Fonts ready in $DEST"
ls -1 "$DEST"
