# AyAmbo ComfyUI Flatpak

Unofficial, vibe-coded Flatpak packaging for [ComfyUI](https://github.com/Comfy-Org/ComfyUI).

This project packages ComfyUI as a local/shareable Flatpak with NVIDIA/CUDA support, ComfyUI-Manager, `git`, `pip`, and `uv` inside the sandbox. It is not affiliated with or endorsed by ComfyUI or Comfy Org.

License: GPL-3.0-or-later.

## What is included

- ComfyUI pinned to `f6c162ddcfbd7eefb39c06fe5b8d4c46e8d09f40` (`0.26.0`).
- Freedesktop runtime/SDK `25.08`.
- PyTorch CUDA wheel stack (`torch 2.12.1` with CUDA 13 wheels).
- ComfyUI-Manager enabled by default.
- `git` for custom-node clone/update.
- `pip` and `uv` for extension dependencies.
- Automatic custom-node `requirements*.txt` installer.
- Sandboxed writable data/config/cache under Flatpak app data.
- No model weights bundled.

App ID:

```text
io.github.AyAmbo.ComfyUIFlatpak
```

## Install the release bundle

Download all split release assets into the same folder:

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

Open:

```text
http://127.0.0.1:8188
```

Reinstall/update while keeping your data:

```bash
flatpak install --user --reinstall ./AyAmbo-ComfyUIFlatpak.flatpak
```

Uninstall but keep data:

```bash
flatpak uninstall --user io.github.AyAmbo.ComfyUIFlatpak
```

Full reset, including models/extensions/settings in this app's sandbox:

```bash
flatpak uninstall --user --delete-data io.github.AyAmbo.ComfyUIFlatpak
```

## NVIDIA / CUDA

For GPU use, install a host NVIDIA driver new enough for the bundled CUDA/PyTorch stack and the matching Flatpak NVIDIA GL extension.

This package was validated on:

```text
NVIDIA driver 595.80
org.freedesktop.Platform.GL.nvidia-595-80//1.4
2x NVIDIA GeForce RTX 3060
torch.cuda.is_available() == True
```

Flatpak usually installs matching GL extensions automatically when available. If needed, install manually, for example:

```bash
flatpak install flathub org.freedesktop.Platform.GL.nvidia-595-80//1.4
```

Run validation:

```bash
scripts/test-flatpak.sh
```

## Sandboxed data locations

Default profile:

```text
~/.var/app/io.github.AyAmbo.ComfyUIFlatpak/data/ComfyUI/models
~/.var/app/io.github.AyAmbo.ComfyUIFlatpak/data/ComfyUI/custom_nodes
~/.var/app/io.github.AyAmbo.ComfyUIFlatpak/data/ComfyUI/input
~/.var/app/io.github.AyAmbo.ComfyUIFlatpak/data/ComfyUI/output
~/.var/app/io.github.AyAmbo.ComfyUIFlatpak/data/ComfyUI/user
~/.var/app/io.github.AyAmbo.ComfyUIFlatpak/data/python
~/.var/app/io.github.AyAmbo.ComfyUIFlatpak/cache/pip
~/.var/app/io.github.AyAmbo.ComfyUIFlatpak/cache/uv
~/.var/app/io.github.AyAmbo.ComfyUIFlatpak/cache/huggingface
~/.var/app/io.github.AyAmbo.ComfyUIFlatpak/cache/torch
```

`/app` is immutable. Extension Python packages are installed into the app-private Flatpak data area, not into host Python.

## Extension dependency install / repair commands

The launcher automatically scans custom nodes for:

```text
requirements.txt
requirements*.txt
```

and installs changed requirements into the sandboxed Python user layer. Hash markers are stored under:

```text
~/.var/app/io.github.AyAmbo.ComfyUIFlatpak/data/ComfyUI/user/__flatpak_requirements
```

Manually install a missing package:

```bash
flatpak run --command=comfyui-pip io.github.AyAmbo.ComfyUIFlatpak install accelerate
```

Install from an extension requirement file:

```bash
flatpak run --command=comfyui-pip io.github.AyAmbo.ComfyUIFlatpak install -r ~/.var/app/io.github.AyAmbo.ComfyUIFlatpak/data/ComfyUI/custom_nodes/EXT/requirements.txt
```

Run the auto requirements installer manually:

```bash
flatpak run --command=comfyui-install-requirements io.github.AyAmbo.ComfyUIFlatpak
```

Check helper tools:

```bash
flatpak run --command=comfyui-pip io.github.AyAmbo.ComfyUIFlatpak --version
flatpak run --command=comfyui-uv io.github.AyAmbo.ComfyUIFlatpak --version
```

Disable automatic requirement installation for one run:

```bash
flatpak run --env=COMFYUI_FLATPAK_AUTO_INSTALL_REQUIREMENTS=0 io.github.AyAmbo.ComfyUIFlatpak
```

## Multiple ports / GPUs / profiles

Same sandbox data, different ports:

```bash
flatpak run io.github.AyAmbo.ComfyUIFlatpak --port 8188
flatpak run io.github.AyAmbo.ComfyUIFlatpak --port 8189
```

Different GPU per instance:

```bash
flatpak run --env=CUDA_VISIBLE_DEVICES=0 io.github.AyAmbo.ComfyUIFlatpak --port 8188
flatpak run --env=CUDA_VISIBLE_DEVICES=1 io.github.AyAmbo.ComfyUIFlatpak --port 8189
```

Safer separate profiles, with separate data/config/cache/Python layers:

```bash
flatpak run --env=CUDA_VISIBLE_DEVICES=0 io.github.AyAmbo.ComfyUIFlatpak --profile gpu0 --port 8188
flatpak run --env=CUDA_VISIBLE_DEVICES=1 io.github.AyAmbo.ComfyUIFlatpak --profile gpu1 --port 8189
```

Profile data lives under:

```text
~/.var/app/io.github.AyAmbo.ComfyUIFlatpak/data/ComfyUI-profiles/PROFILE
~/.var/app/io.github.AyAmbo.ComfyUIFlatpak/config/ComfyUI-profiles/PROFILE
~/.var/app/io.github.AyAmbo.ComfyUIFlatpak/cache/ComfyUI-profiles/PROFILE
~/.var/app/io.github.AyAmbo.ComfyUIFlatpak/data/python-profiles/PROFILE
```

## Build from source

Install prerequisites:

```bash
sudo apt install flatpak flatpak-builder python3-venv
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install flathub org.freedesktop.Platform//25.08 org.freedesktop.Sdk//25.08
```

Generate Python source manifest only when requirements/versions change:

```bash
scripts/generate-python-sources.sh
```

Iterate/build locally:

```bash
scripts/build-incremental.sh
scripts/install-local.sh
scripts/test-flatpak.sh
```

Create release bundle:

```bash
scripts/make-bundle.sh
```

Outputs are written to `release/`:

```text
AyAmbo-ComfyUIFlatpak.flatpak
AyAmbo-ComfyUIFlatpak.flatpak.sha256
AyAmbo-ComfyUIFlatpak.flatpak.zst
AyAmbo-ComfyUIFlatpak.flatpak.zst.sha256
AyAmbo-ComfyUIFlatpak.flatpak.zst.parts.sha256
AyAmbo-ComfyUIFlatpak.flatpak.zst.part-*
INSTALL.md
```

Upload the `.part-*`, `.zst.sha256`, `.parts.sha256`, and `INSTALL.md` files to GitHub Releases.

## Modify/update

Main files:

```text
io.github.AyAmbo.ComfyUIFlatpak.yml
packaging/comfyui-flatpak-launcher
packaging/comfyui-flatpak-install-requirements
packaging/sources/python-requirements.in
scripts/*.sh
```

To update ComfyUI or dependencies:

1. Update the pinned ComfyUI commit in the manifest/docs.
2. Check upstream `requirements.txt` and Manager version.
3. Update `packaging/sources/python-requirements.in`.
4. Run `scripts/generate-python-sources.sh`.
5. Build/test/bundle again.

## Notes

This was vibe-coded with AI.
