#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

if [ ! -f packaging/pypi-dependencies.json ]; then
  echo "Missing packaging/pypi-dependencies.json. Run scripts/generate-python-sources.sh first." >&2
  exit 1
fi

# Faster iteration build: keeps .flatpak-builder module/download cache while
# refreshing the app dir. flatpak-builder refuses a non-empty app dir without
# --force-clean, but unchanged modules are still reused from cache.
# Use scripts/build-flatpak.sh for a release-style verification run.
flatpak-builder --force-clean build-dir io.github.AyAmbo.ComfyUIFlatpak.yml
