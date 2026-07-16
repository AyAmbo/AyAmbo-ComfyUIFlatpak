#!/usr/bin/env bash
set -euo pipefail
APP_ID=io.github.AyAmbo.ComfyUIFlatpak

echo "== Python/GPU/import test =="
flatpak run --command=sh "$APP_ID" -lc 'export PYTHONPATH=/app/share/comfyui${PYTHONPATH:+:$PYTHONPATH}; python3 - <<'"'"'PY'"'"'
import sys
print('"'"'python'"'"', sys.version)
import torch
print('"'"'torch'"'"', torch.__version__)
print('"'"'cuda available'"'"', torch.cuda.is_available())
print('"'"'cuda device count'"'"', torch.cuda.device_count())
if torch.cuda.is_available():
    print('"'"'cuda device 0'"'"', torch.cuda.get_device_name(0))
    x = torch.randn((256, 256), device='"'"'cuda'"'"')
    print('"'"'cuda matmul checksum'"'"', float((x @ x).sum().cpu()))
import comfyui_manager
print('"'"'comfyui_manager'"'"', getattr(comfyui_manager, '"'"'__file__'"'"', '"'"'ok'"'"'))
import comfy_angle
print('"'"'comfy_angle'"'"', getattr(comfy_angle, '"'"'__file__'"'"', '"'"'ok'"'"'))
import git
print('"'"'GitPython ok'"'"')
PY
'

echo "== tool availability =="
flatpak run --command=sh "$APP_ID" -c 'which git && git --version && python3 -m pip --version && python3 -m uv --version'

echo "== Triton CUDA JIT test =="
flatpak run --filesystem="$PWD:ro" --env=CC=/app/bin/comfyui-flatpak-cc --command=python3 "$APP_ID" "$PWD/scripts/triton-smoke-test.py"

echo "== quick ComfyUI test =="
flatpak run "$APP_ID" --cpu --quick-test-for-ci
