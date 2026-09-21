# AyAmbo ComfyUI Flatpak

Unofficial, vibe-coded Flatpak packaging for [ComfyUI](https://github.com/Comfy-Org/ComfyUI).

This project packages ComfyUI as a local/shareable Flatpak with NVIDIA/CUDA support, ComfyUI-Manager, `git`, `pip`, and `uv` inside the sandbox. It is not affiliated with or endorsed by ComfyUI or Comfy Org.

License: GPL-3.0-or-later.

## What is included

- ComfyUI pinned to `73c9bad4d21e7addbe1d13bc92eee0f1431b017d` (`0.37.0`).
- Freedesktop runtime/SDK `25.08`.
- PyTorch CUDA wheel stack (`torch 2.13.0` with CUDA 13 wheels).
- ComfyUI-Manager enabled by default.
- `git` for custom-node clone/update.
- `pip` and `uv` for extension dependencies.
- Bundled Zig C compiler for Triton CUDA runtime JIT compilation.
- Automatic custom-node `requirements*.txt` installer.
- Sandboxed writable data/config/cache under Flatpak app data.
- No model weights bundled.

## Install or update

Packaging release **v0.7** contains ComfyUI **0.37.0**, for x86_64 Linux (not ComfyUI Desktop).
Install Flatpak and zstd with your distribution's package manager. On Debian/Ubuntu:

```bash
sudo apt install flatpak zstd
flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install --user flathub org.freedesktop.Platform//25.08
```

Before upgrading, stop ComfyUI and copy the whole hidden folder
`~/.var/app/io.github.AyAmbo.ComfyUIFlatpak` to a safe location. Back up externally
linked models separately. Reinstalling keeps data, but updates can change it;
keep the previous release and backup for rollback. Do not use `--delete-data`
for an upgrade. Allow about 10 GB for the downloaded parts and reconstructed
files, plus space for the installed app/runtime.

Download all split release assets into a new, empty folder (do not mix releases):

```text
AyAmbo-ComfyUIFlatpak.flatpak.zst.part-*
AyAmbo-ComfyUIFlatpak.flatpak.zst.parts.sha256
AyAmbo-ComfyUIFlatpak.flatpak.zst.sha256
AyAmbo-ComfyUIFlatpak.flatpak.sha256
```

Verify, join, decompress, and install. Stop if any checksum fails:

```bash
sha256sum -c AyAmbo-ComfyUIFlatpak.flatpak.zst.parts.sha256 &&
cat AyAmbo-ComfyUIFlatpak.flatpak.zst.part-* > AyAmbo-ComfyUIFlatpak.flatpak.zst &&
sha256sum -c AyAmbo-ComfyUIFlatpak.flatpak.zst.sha256 &&
zstd -d AyAmbo-ComfyUIFlatpak.flatpak.zst &&
sha256sum -c AyAmbo-ComfyUIFlatpak.flatpak.sha256 &&
flatpak install --user --reinstall ./AyAmbo-ComfyUIFlatpak.flatpak &&
flatpak run io.github.AyAmbo.ComfyUIFlatpak
```

Open:

```text
http://127.0.0.1:8188
```

If you already have the full `.flatpak`, verify its `.sha256` and use the
same `flatpak install --user --reinstall` command above. The startup log should
show ComfyUI **0.37.0**. Test your important workflows after updating.

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

GPU smoke tests were run on two RTX 3060 cards with NVIDIA driver 595.80.

Flatpak usually installs matching GL extensions automatically when available. If needed, install manually, for example:

```bash
flatpak install flathub org.freedesktop.Platform.GL.nvidia-595-80//1.4
```

## Data and extensions

App data lives under `~/.var/app/io.github.AyAmbo.ComfyUIFlatpak/`:

- `data/ComfyUI/`: models, custom nodes, input, output and user settings.
- `data/python/`: user-installed Python packages.
- `cache/`: pip, uv, Hugging Face, torch and other caches.

`/app` is immutable. Extension dependencies are installed into app-private data,
not host Python, and user packages may override bundled ones. Only install custom
nodes and run workflows from sources you trust.

## Extension dependency install / repair commands

The launcher installs changed `requirements*.txt` files from custom nodes.
Success markers live in `data/ComfyUI/user/__flatpak_requirements`; use the repair
command below to retry requirements without manually clearing them.

Manually install a missing package:

```bash
flatpak run --command=comfyui-pip io.github.AyAmbo.ComfyUIFlatpak install accelerate
```

Install from an extension requirement file:

```bash
flatpak run --command=comfyui-pip io.github.AyAmbo.ComfyUIFlatpak install -r ~/.var/app/io.github.AyAmbo.ComfyUIFlatpak/data/ComfyUI/custom_nodes/EXT/requirements.txt
```

The `comfyui-uv pip install/uninstall/sync/list/freeze/show` commands target the
writable Python prefix for the selected profile. For example:

```bash
flatpak run --env=COMFYUI_FLATPAK_PROFILE=testing --command=comfyui-uv io.github.AyAmbo.ComfyUIFlatpak pip install humanize
flatpak run --env=COMFYUI_FLATPAK_PROFILE=testing --command=comfyui-uv io.github.AyAmbo.ComfyUIFlatpak pip list
```

`uv pip check/tree` do not support a prefix selector; those read-only commands
inspect the system interpreter's packages and may omit `/app` and profile packages.
Use `comfyui-pip check` for the app/profile Python environment instead. `pip --help`
and `pip compile` use uv's normal argument handling.

Disable automatic requirement installation for one run:

```bash
flatpak run --env=COMFYUI_FLATPAK_AUTO_INSTALL_REQUIREMENTS=0 io.github.AyAmbo.ComfyUIFlatpak
```

## Repair packages or manage custom nodes

Stop the selected profile before running maintenance. The running-profile lock
requires v0.6 or newer; close older instances manually.
Use `--profile NAME` before the subcommand for a named profile; omit it for default.

```bash
flatpak run --command=comfyui-repair io.github.AyAmbo.ComfyUIFlatpak --help
flatpak run --command=comfyui-repair io.github.AyAmbo.ComfyUIFlatpak requirements
flatpak run --command=comfyui-repair io.github.AyAmbo.ComfyUIFlatpak nodes list
flatpak run --command=comfyui-repair io.github.AyAmbo.ComfyUIFlatpak nodes update NODE
flatpak run --command=comfyui-repair io.github.AyAmbo.ComfyUIFlatpak nodes disable NODE
flatpak run --command=comfyui-repair io.github.AyAmbo.ComfyUIFlatpak nodes restore NODE
```

`requirements` retries every discovered requirements file, ignoring success markers;
it does not force reinstall or upgrade satisfied packages. `nodes update --all`
explicitly tries all nodes. Updates are fast-forward-only for clean ordinary Git
folders; dirty, non-Git and unsafe paths are skipped with a nonzero result.
Disable moves a node outside `custom_nodes` to `.flatpak-disabled-nodes`; restore
refuses collisions. No permanent deletion is provided.

For a broken Python user layer, explicitly back it up and rebuild from requirements:

```bash
flatpak run --command=comfyui-repair io.github.AyAmbo.ComfyUIFlatpak reset-packages
flatpak run --command=comfyui-repair io.github.AyAmbo.ComfyUIFlatpak restore-packages BACKUP_NAME
```

Reset prints the backup path/name and retries requirements. Models, workflows,
configuration and node code are not moved. Packages absent from requirements may
need manual reinstall or restoration. Backups are retained under the app data
`comfyui-flatpak-package-backups/PROFILE`; restore also backs up the current Python
layer and clears markers, without installing anything. Repair supports only the
standard profile paths.

## Multiple ports / GPUs / profiles

Use `--port` to run another instance. For separate data, configuration and Python
packages on different GPUs:

```bash
flatpak run --env=CUDA_VISIBLE_DEVICES=0 io.github.AyAmbo.ComfyUIFlatpak --profile gpu0 --port 8188
flatpak run --env=CUDA_VISIBLE_DEVICES=1 io.github.AyAmbo.ComfyUIFlatpak --profile gpu1 --port 8189
```

Under the app-data folder, named profiles use `data/ComfyUI-profiles/PROFILE`,
`config/ComfyUI-profiles/PROFILE` and `data/python-profiles/PROFILE`.
Several caches (including pip, uv, Hugging Face and torch) are shared;
profiles are not separate security sandboxes.

## Build from source

Install prerequisites:

```bash
sudo apt install flatpak flatpak-builder python3-venv
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install flathub org.freedesktop.Platform//25.08 org.freedesktop.Sdk//25.08
```

For an update, change the upstream commit in the manifest/docs and synchronize
`packaging/sources/python-requirements.in` with upstream and Manager requirements.
Regenerate dependency sources only when requirements/versions change:

```bash
scripts/generate-python-sources.sh
```

Iterate/build locally:

```bash
scripts/build-incremental.sh
scripts/install-local.sh
scripts/test-flatpak.sh
scripts/test-comfyui-flatpak-uv.sh
python3 scripts/test-native-wheels.py
python3 scripts/test-comfyui-flatpak-repair.py
```

The GPU smoke test uses a separate profile and leaves its files for inspection.
To test the HTTP API and a model-free image graph:

```bash
flatpak run io.github.AyAmbo.ComfyUIFlatpak --profile http-smoke --port 8189
# In another terminal, from the source folder:
python3 scripts/api-smoke-test.py --url http://127.0.0.1:8189
```

These tests cover startup, GPU operations and a model-free image graph, not full
model inference or third-party node compatibility.

The generator explicitly selects Linux x86_64 native wheels for `comfy-kitchen` and
`comfy-aimdo`: their universal wheels omit the CUDA and DynamicVRAM libraries.
`scripts/check_native_wheels.py` rejects those stub wheels after generation.

Create release bundle:

```bash
scripts/make-bundle.sh
```

Writes to `release/`; pass an empty directory as the first argument to use another
location. Outputs:

```text
AyAmbo-ComfyUIFlatpak.flatpak
AyAmbo-ComfyUIFlatpak.flatpak.sha256
AyAmbo-ComfyUIFlatpak.flatpak.zst
AyAmbo-ComfyUIFlatpak.flatpak.zst.sha256
AyAmbo-ComfyUIFlatpak.flatpak.zst.parts.sha256
AyAmbo-ComfyUIFlatpak.flatpak.zst.part-*
```

Upload the `.part-*`, `.zst.sha256`, `.parts.sha256`, `.flatpak.sha256`
files to GitHub Releases, not the full `.flatpak` or `.zst`. Parts are below 2 GB.
