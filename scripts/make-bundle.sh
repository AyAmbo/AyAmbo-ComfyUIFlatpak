#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

if [ ! -f packaging/pypi-dependencies.json ]; then
  echo "Missing packaging/pypi-dependencies.json. Run scripts/generate-python-sources.sh first." >&2
  exit 1
fi

APP_ID="io.github.AyAmbo.ComfyUIFlatpak"
BUNDLE="AyAmbo-ComfyUIFlatpak.flatpak"
ZST_BUNDLE="$BUNDLE.zst"
PART_PREFIX="$ZST_BUNDLE.part-"
# Below both 2 GB (decimal) and GitHub's 2 GiB per-file limit.
PART_SIZE="1900M"
OUTPUT_DIR="${1:-release}"

# Require an empty destination to avoid mixing release parts.
mkdir -p "$OUTPUT_DIR"
# Flatpak canonicalizes relative paths using PWD; resolve symlinked checkouts first.
OUTPUT_DIR="$(cd "$OUTPUT_DIR" && pwd -P)"
if find "$OUTPUT_DIR" -mindepth 1 ! -name .gitkeep -print -quit | grep -q .; then
  echo "Output directory is not empty: $OUTPUT_DIR. Pass a new directory as the first argument." >&2
  exit 1
fi
flatpak-builder --repo=repo --force-clean build-dir io.github.AyAmbo.ComfyUIFlatpak.yml
flatpak build-bundle repo "$OUTPUT_DIR/$BUNDLE" "$APP_ID"

(
  cd "$OUTPUT_DIR"
  sha256sum "$BUNDLE" > "$BUNDLE.sha256"
  zstd -19 -T0 -f "$BUNDLE" -o "$ZST_BUNDLE"
  split -b "$PART_SIZE" -d -a 3 "$ZST_BUNDLE" "$PART_PREFIX"
  sha256sum "$ZST_BUNDLE" > "$ZST_BUNDLE.sha256"
  sha256sum ${PART_PREFIX}* > "$ZST_BUNDLE.parts.sha256"
  sha256sum -c "$ZST_BUNDLE.parts.sha256"
  # Check concatenation order and decompressed content without another large copy.
  test "$(cat ${PART_PREFIX}* | sha256sum | cut -d ' ' -f1)" = "$(cut -d ' ' -f1 "$ZST_BUNDLE.sha256")"
  test "$(cat ${PART_PREFIX}* | zstd -d -c | sha256sum | cut -d ' ' -f1)" = "$(cut -d ' ' -f1 "$BUNDLE.sha256")"
  ls -lh "$BUNDLE" "$BUNDLE.sha256" "$ZST_BUNDLE" "$ZST_BUNDLE.sha256" "$ZST_BUNDLE.parts.sha256" ${PART_PREFIX}*
)
