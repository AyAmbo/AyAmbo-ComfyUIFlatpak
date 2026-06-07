#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

if [ ! -f packaging/pypi-dependencies.json ]; then
  echo "Missing packaging/pypi-dependencies.json. Run scripts/generate-python-sources.sh first." >&2
  exit 1
fi

flatpak-builder --user --install --force-clean build-dir io.github.AyAmbo.ComfyUIFlatpak.yml
