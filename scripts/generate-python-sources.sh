#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

REQ="packaging/sources/python-requirements.in"
OUT="packaging/pypi-dependencies"
VENV=".venv-flatpak-tools"

if [ ! -f "$REQ" ]; then
  echo "Missing $REQ" >&2
  exit 1
fi

if ! command -v flatpak >/dev/null 2>&1; then
  echo "Warning: flatpak is not installed; generator can still run but cannot inspect installed runtimes." >&2
fi

GENERATOR="$VENV/bin/flatpak_pip_generator"

if [ ! -x "$GENERATOR" ]; then
  if [ ! -d "$VENV" ]; then
    if ! python3 -m venv "$VENV"; then
      echo "Failed to create Python venv. Install python3-venv/python3.13-venv, then rerun." >&2
      exit 1
    fi
  fi
  "$VENV/bin/python" -m pip install --upgrade pip wheel flatpak-pip-generator
fi

rm -f "$OUT.json"

PREFER_WHEELS="torch,torchsde,torchvision,torchaudio,triton,numpy,scipy,pillow,av,tokenizers,safetensors,sentencepiece,pydantic-core,kornia-rs,blake3,glfw,yarl,multidict,frozenlist,greenlet,charset-normalizer,regex,psutil,PyYAML,pyyaml,hf-xet,cffi,cryptography,pynacl,comfy-kitchen,comfy-aimdo,uv,matrix-nio,GitPython,PyGithub,cuda-bindings,nvidia-cublas,nvidia-cuda-cupti,nvidia-cuda-nvrtc,nvidia-cuda-runtime,nvidia-cudnn-cu13,nvidia-cufft,nvidia-cufile,nvidia-curand,nvidia-cusolver,nvidia-cusparse,nvidia-cusparselt-cu13,nvidia-nccl-cu13,nvidia-nvjitlink,nvidia-nvshmem-cu13,nvidia-nvtx"

# Keep this script as the single update point for Python dependency source generation.
set +e
"$GENERATOR" \
  --requirements-file "$REQ" \
  --output "$OUT" \
  --runtime org.freedesktop.Sdk//25.08 \
  --prefer-wheels "$PREFER_WHEELS" \
  --wheel-arches x86_64 \
  --ignore-installed pip,setuptools,packaging,wheel \
  --checker-data
GENERATOR_STATUS=$?
set -e

# The PyPI wrapper for flatpak-pip-generator 2026.5.28 can emit a valid output
# and then exit non-zero with an entrypoint ImportError. Treat an existing JSON
# as authoritative, but still warn so future maintainers can revisit this.
if [ "$GENERATOR_STATUS" -ne 0 ] && [ ! -f "$OUT.json" ]; then
  echo "flatpak-pip-generator failed before creating $OUT.json. Try rerunning with the installed generator's --help and adjust this script only." >&2
  exit "$GENERATOR_STATUS"
elif [ "$GENERATOR_STATUS" -ne 0 ]; then
  echo "Warning: flatpak-pip-generator exited with $GENERATOR_STATUS after creating $OUT.json; continuing." >&2
fi

if [ ! -f "$OUT.json" ]; then
  echo "Expected $OUT.json was not created" >&2
  exit 1
fi

echo "Generated $OUT.json"
