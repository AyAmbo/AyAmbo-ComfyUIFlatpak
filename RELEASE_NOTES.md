# v0.5 — ComfyUI 0.35.0

Unofficial, vibe-coded Flatpak packaging, not affiliated with ComfyUI or Comfy Org.
This is the non-Desktop ComfyUI package for x86_64 Linux.

## Updated

- ComfyUI **0.35.0**, pinned to `40c4fcdf513a4523e39d54a9d391908af8df8171`
  ([upstream release](https://github.com/Comfy-Org/ComfyUI/releases/tag/v0.35.0)).
- Frontend **1.51.10**, workflow templates **0.11.57**, embedded docs **0.5.11**,
  comfy-kitchen **0.2.33**, comfy-aimdo **0.5.3**, and three matching template subpackages.
- Preserved PyTorch **2.13.0+cu130**, Triton **3.7.1**, ComfyUI-Manager **4.2.2**,
  Freedesktop **25.08**, bundled git/pip/uv/Zig, the app ID and sandbox permissions.
- Corrected a pre-existing wheel-selection issue: use native Linux x86_64 wheels for
  comfy-kitchen and comfy-aimdo, rather than universal wheels missing their native libraries.
  This enables the kitchen CUDA backend and aimdo/DynamicVRAM; generation now guards
  against accidentally selecting the stub wheels again.
- Preserved profile-specific Python user packages and custom-node overrides. No
  bundled-package precedence enforcement or additional doctor tools were introduced.
- Fixed a pre-existing `comfyui-uv pip` argument-order bug that prevented installation:
  install/uninstall and prefix-aware inspection now select the writable profile correctly;
  help/compile and interpreter-only check/tree receive only supported options.
- Safer bundling refuses a nonempty output folder, keeps previous releases, creates
  parts smaller than 2 GB, and verifies compressed and decompressed recombination hashes.
- Added a beginner backup/install/upgrade guide and isolated smoke-test instructions.

Only the required dependency modules were regenerated; unrelated bundled packages were
not refreshed. Upstream features and fixes are described in the upstream release notes.

## Validation on 2026-09-11

Tested the final installed Flatpak on NVIDIA driver **595.80**, matching Flatpak GL
extension, **two RTX 3060 GPUs**, Python **3.13.15** and glibc **2.42**, using separate
retained test profiles rather than the default user profile:

- Verified packaged ComfyUI version/commit and installed launcher/helper contents.
- CUDA matrix multiplication checked against CPU results on both GPUs.
- Triton **3.7.1** compiled its CUDA driver bridge through bundled Zig in a fresh cache
  and executed a minimal kernel on GPU 0.
- Native kitchen INT8 dequantization verified on both GPUs; native aimdo initialized
  both devices and passed a 4-KB VRAM-buffer write/read on each.
- GPU server reported **DynamicVRAM enabled** and the native kitchen CUDA backend available.
- CPU startup/SQLite initialization, API version/queue/node registration, frontend HTML
  plus three bundled JS assets, and an `EmptyImage -> SaveImage` API graph succeeded.
  The graph saved and served a 64x64 PNG; it is **not a diffusion/model inference test**.
- Real pip user-package override, uv install/list/freeze/show/uninstall, custom-node
  requirements installation/reuse marker, relative model-directory writes and separate
  profile package isolation passed. Bundled-package precedence was not forced.
- Split-part hashes and compressed/decompressed recombination hashes verified.

### Limitations

No suitable diffusion checkpoints were available in the inspected model locations;
no large models were downloaded. Real model generation, model offloading/VRAM pressure,
all DynamicVRAM/compiler workflows, arbitrary custom nodes, interactive browser behavior,
partner APIs and non-NVIDIA hardware are **not verified**.

ComfyUI-Manager still emits its pre-existing false “PyTorch is not installed” warning
(despite verified PyTorch/CUDA computation), and warns about unavailable optional matrix
sharing. The optional OpenGL accelerator is absent. Manager registry access failed during
startup and used its fallback list; Manager catalog installation is not certified by these
checks. Existing customized profiles may need their own dependency repairs.

## Install or upgrade

Download **both `.part-*` files and all three checksum files**, plus `INSTALL.md`.
Follow `INSTALL.md` to verify, join, decompress and install. Do not mix parts from older
releases. The full Flatpak is reconstructed locally because it exceeds GitHub's asset limit.

Stop ComfyUI and back up `~/.var/app/io.github.AyAmbo.ComfyUIFlatpak` first (and any
externally linked models). `flatpak install --user --reinstall` keeps models, custom nodes,
settings and profiles. Do not use `--delete-data` for an upgrade. No model weights are bundled.

Custom nodes and user-installed packages may need repair independently of this update.
Keep the previous bundle and data backup for rollback. Always try your important workflows
before deleting a backup.
