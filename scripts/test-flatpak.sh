#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
APP_ID=io.github.AyAmbo.ComfyUIFlatpak
# Never launch validation against the user's default profile.
PROFILE="${COMFYUI_FLATPAK_TEST_PROFILE:-flatpak-smoke-$(date +%s)-$$}"
PROFILE="$(printf '%s' "$PROFILE" | tr -c 'A-Za-z0-9_.-' '_' | sed 's/^_*//; s/_*$//')"
case "$PROFILE" in
  ''|default|.|..)
    echo "Choose a non-default named test profile." >&2
    exit 2
    ;;
esac
RUN=(flatpak run "--env=COMFYUI_FLATPAK_PROFILE=$PROFILE")
echo "Test profile: $PROFILE (retained for inspection)"

echo "== Python/GPU/import test =="
"${RUN[@]}" --command=sh "$APP_ID" -lc 'export PYTHONUSERBASE="$XDG_DATA_HOME/python-profiles/$COMFYUI_FLATPAK_PROFILE"; export PYTHONPATH=/app/share/comfyui; python3 - <<'"'"'PY'"'"'
import sys
import comfyui_version
import torch
print("python", sys.version)
print("ComfyUI", comfyui_version.__version__)
assert comfyui_version.__version__ == "0.35.0"
print("torch", torch.__version__)
print("cuda available", torch.cuda.is_available())
assert torch.cuda.is_available(), "CUDA is required by this GPU smoke test"
print("cuda device count", torch.cuda.device_count())
for device in range(torch.cuda.device_count()):
    print("cuda device", device, torch.cuda.get_device_name(device))
    x = torch.arange(256, dtype=torch.float32).reshape(16, 16) / 256
    actual = x.to(f"cuda:{device}") @ x.to(f"cuda:{device}")
    torch.testing.assert_close(actual.cpu(), x @ x)
    print("cuda matmul verified", device, float(actual.sum()))
import comfyui_manager
import comfy_angle
import git
print("Manager, comfy_angle, GitPython imports ok")
PY
'

echo "== tool availability =="
"${RUN[@]}" --command=sh "$APP_ID" -c 'git --version && comfyui-pip --version && comfyui-uv --version'

echo "== Triton CUDA JIT test (fresh profile cache) =="
"${RUN[@]}" --filesystem="$PWD:ro" --env=CC=/app/bin/comfyui-flatpak-cc --command=sh "$APP_ID" -c '
export PYTHONUSERBASE="$XDG_DATA_HOME/python-profiles/$COMFYUI_FLATPAK_PROFILE"
export TRITON_CACHE_DIR="$XDG_CACHE_HOME/ComfyUI-profiles/$COMFYUI_FLATPAK_PROFILE/triton"
export ZIG_GLOBAL_CACHE_DIR="$XDG_CACHE_HOME/ComfyUI-profiles/$COMFYUI_FLATPAK_PROFILE/zig"
exec python3 "$1"
' sh "$PWD/scripts/triton-smoke-test.py"

echo "== Native kitchen CUDA and aimdo VRAM tests =="
"${RUN[@]}" --filesystem="$PWD:ro" --command=sh "$APP_ID" -c '
export PYTHONUSERBASE="$XDG_DATA_HOME/python-profiles/$COMFYUI_FLATPAK_PROFILE"
exec python3 "$1"
' sh "$PWD/scripts/native-backends-smoke-test.py"

echo "== quick ComfyUI CPU test =="
"${RUN[@]}" "$APP_ID" --cpu --quick-test-for-ci

echo "For HTTP/API/image-graph testing, start this profile on an unused port:"
echo "flatpak run $APP_ID --profile $PROFILE --port 8189"
echo "python3 scripts/api-smoke-test.py --url http://127.0.0.1:8189"
