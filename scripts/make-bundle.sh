#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

if [ ! -f packaging/pypi-dependencies.json ]; then
  echo "Missing packaging/pypi-dependencies.json. Run scripts/generate-python-sources.sh first." >&2
  exit 1
fi

rm -rf repo build-dir
flatpak-builder --repo=repo --force-clean build-dir io.github.AyAmbo.ComfyUIFlatpak.yml
flatpak build-bundle repo AyAmbo-ComfyUIFlatpak.flatpak io.github.AyAmbo.ComfyUIFlatpak
sha256sum AyAmbo-ComfyUIFlatpak.flatpak > AyAmbo-ComfyUIFlatpak.flatpak.sha256
ls -lh AyAmbo-ComfyUIFlatpak.flatpak AyAmbo-ComfyUIFlatpak.flatpak.sha256
