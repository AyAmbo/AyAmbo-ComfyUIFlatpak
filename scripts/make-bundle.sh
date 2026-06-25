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
# GitHub's per-file release asset limit is 2 GiB. Keep parts safely below it.
PART_SIZE="1900M"

rm -rf repo build-dir release
mkdir -p release
: > release/.gitkeep

flatpak-builder --repo=repo --force-clean build-dir io.github.AyAmbo.ComfyUIFlatpak.yml
flatpak build-bundle repo "release/$BUNDLE" "$APP_ID"

(
  cd release
  sha256sum "$BUNDLE" > "$BUNDLE.sha256"
  zstd -19 -T0 -f "$BUNDLE" -o "$ZST_BUNDLE"
  split -b "$PART_SIZE" -d -a 3 "$ZST_BUNDLE" "$PART_PREFIX"
  sha256sum "$ZST_BUNDLE" > "$ZST_BUNDLE.sha256"
  sha256sum ${PART_PREFIX}* > "$ZST_BUNDLE.parts.sha256"
  cat > INSTALL.md <<'EOF'
# AyAmbo ComfyUI Flatpak release install

Download all release assets into the same folder:

```text
AyAmbo-ComfyUIFlatpak.flatpak.zst.part-*
AyAmbo-ComfyUIFlatpak.flatpak.zst.parts.sha256
AyAmbo-ComfyUIFlatpak.flatpak.zst.sha256
```

Verify, join, decompress, and install:

```bash
sha256sum -c AyAmbo-ComfyUIFlatpak.flatpak.zst.parts.sha256
cat AyAmbo-ComfyUIFlatpak.flatpak.zst.part-* > AyAmbo-ComfyUIFlatpak.flatpak.zst
sha256sum -c AyAmbo-ComfyUIFlatpak.flatpak.zst.sha256
zstd -d -f AyAmbo-ComfyUIFlatpak.flatpak.zst
flatpak install --user --reinstall ./AyAmbo-ComfyUIFlatpak.flatpak
flatpak run io.github.AyAmbo.ComfyUIFlatpak
```

Open ComfyUI at:

```text
http://127.0.0.1:8188
```
EOF
  ls -lh "$BUNDLE" "$BUNDLE.sha256" "$ZST_BUNDLE" "$ZST_BUNDLE.sha256" "$ZST_BUNDLE.parts.sha256" ${PART_PREFIX}* INSTALL.md
)
