#!/usr/bin/env bash
# ============================================================
# download_model.sh
# Downloads the lfm2.5-350m CoreML model from HuggingFace
# using curl only — no extra tools required.
#
# Repo: https://huggingface.co/uzakotim/lfm2.5-350m-coreml
#
# Usage:
#   chmod +x download_model.sh
#   ./download_model.sh
#
# For private repos, set your HF read token:
#   HF_TOKEN=hf_xxxx ./download_model.sh
#
# Requirements: curl (ships with macOS)
# ============================================================

set -euo pipefail

HF_USER="mlboydaisuke"
HF_REPO="qwen2.5-0.5b-coreml"
CDN_BASE="https://huggingface.co/${HF_USER}/${HF_REPO}/resolve/main"
DEST_DIR="ios_robot_gesture_control/Models/qwen2.5-0.5b-coreml"

# Known files in the repo (from API: siblings list)
FILES=(
    "model.mlmodelc/analytics/coremldata.bin"
    "model.mlmodelc/coremldata.bin"
    "model.mlmodelc/metadata.json"
    "model.mlmodelc/model.mil"
    "model.mlmodelc/weights/weight.bin"
    "model_config.json"
    "hf_model/config.json"
    "hf_model/generation_config.json"
    "hf_model/tokenizer.json"
    "hf_model/tokenizer_config.json"
)

# ── Colour helpers ────────────────────────────────────────────
GREEN="\033[0;32m"; YELLOW="\033[1;33m"
CYAN="\033[0;36m";  RED="\033[0;31m"; NC="\033[0m"

echo -e "${CYAN}🤖  lfm2.5-350m CoreML model downloader${NC}"
echo -e "${CYAN}    Repo: ${HF_USER}/${HF_REPO}${NC}"
echo "======================================================"

# ── Check curl ────────────────────────────────────────────────
if ! command -v curl &>/dev/null; then
    echo -e "${RED}❌  curl not found.${NC}"
    exit 1
fi
echo -e "${GREEN}✓  curl available${NC}"

# ── Build auth header (optional) ─────────────────────────────
AUTH_ARGS=()
if [ -n "${HF_TOKEN:-}" ]; then
    AUTH_ARGS+=(-H "Authorization: Bearer ${HF_TOKEN}")
    echo -e "${GREEN}✓  Using HF_TOKEN${NC}"
fi

# ── Create destination dirs ───────────────────────────────────
mkdir -p \
    "$DEST_DIR/model.mlmodelc/analytics" \
    "$DEST_DIR/model.mlmodelc/weights" \
    "$DEST_DIR/hf_model"

# ── Download each file ────────────────────────────────────────
echo ""
echo "⬇️   Downloading ${#FILES[@]} files to $DEST_DIR …"
echo ""

FAILED=()
for RFILE in "${FILES[@]}"; do
    TARGET="$DEST_DIR/$RFILE"
    URL="${CDN_BASE}/${RFILE}"

    # Skip if already fully downloaded and non-empty
    if [ -f "$TARGET" ] && [ -s "$TARGET" ]; then
        SIZE=$(du -sh "$TARGET" 2>/dev/null | cut -f1)
        echo -e "  ${YELLOW}⏭  Skipping (exists, ${SIZE}): $RFILE${NC}"
        continue
    fi

    echo "  ↓  $RFILE"
    if curl -sSL --fail --progress-bar -o "$TARGET" "${AUTH_ARGS[@]}" "$URL"; then
        SIZE=$(du -sh "$TARGET" 2>/dev/null | cut -f1)
        echo -e "     ${GREEN}✓  ${SIZE}${NC}"
    else
        echo -e "     ${RED}❌  Failed${NC}"
        rm -f "$TARGET"
        FAILED+=("$RFILE")
    fi
done

# ── Summary ───────────────────────────────────────────────────
echo ""
if [ ${#FAILED[@]} -gt 0 ]; then
    echo -e "${RED}⚠️   ${#FAILED[@]} file(s) failed to download:${NC}"
    for f in "${FAILED[@]}"; do echo "    - $f"; done
    echo ""
    echo "Tip: If the repo is private, set HF_TOKEN and retry:"
    echo "  HF_TOKEN=hf_xxxx ./download_model.sh"
    exit 1
fi

echo -e "${GREEN}✅  All files downloaded successfully!${NC}"
echo ""
echo "📦  Files in $DEST_DIR:"
find "$DEST_DIR" -type f | sort | while read -r f; do
    SIZE=$(du -sh "$f" 2>/dev/null | cut -f1)
    printf "    %-8s %s\n" "$SIZE" "${f#$DEST_DIR/}"
done

# ── Xcode integration instructions ───────────────────────────
echo ""
echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║  NEXT STEP — Add the model to your Xcode project:        ║${NC}"
echo -e "${CYAN}║                                                          ║${NC}"
echo -e "${CYAN}║  1. Open ios_robot_gesture_control.xcworkspace in Xcode  ║${NC}"
echo -e "${CYAN}║  2. Right-click 'ios_robot_gesture_control' group        ║${NC}"
echo -e "${CYAN}║  3. 'Add Files to ios_robot_gesture_control…'            ║${NC}"
echo -e "${CYAN}║  4. Select the 'Models' folder                           ║${NC}"
echo -e "${CYAN}║  5. ✅  'Create folder references' (not groups)          ║${NC}"
echo -e "${CYAN}║  6. ✅  Target: ios_robot_gesture_control                ║${NC}"
echo -e "${CYAN}║  7. Click Add, then rebuild the app.                     ║${NC}"
echo -e "${CYAN}║                                                          ║${NC}"
echo -e "${CYAN}║  The app will load the model from the bundle —           ║${NC}"
echo -e "${CYAN}║  no runtime download required!                           ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
