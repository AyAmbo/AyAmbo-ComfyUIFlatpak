# Install or upgrade AyAmbo ComfyUI Flatpak

Unofficial, vibe-coded packaging; not ComfyUI Desktop. No models are included.
Packaging release v0.5 contains ComfyUI 0.35.0, for x86_64 Linux.

## 1. Prepare

Install Flatpak and zstd using your distribution's package manager. On Debian/Ubuntu:

```bash
sudo apt install flatpak zstd
flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install --user flathub org.freedesktop.Platform//25.08
```

NVIDIA use requires a host driver compatible with CUDA 13 and its matching Flatpak
GL extension. Tested with driver 595.80 and RTX 3060; other hardware is not verified.

## 2. Back up before upgrading

Stop ComfyUI (Ctrl+C in its terminal, or close the running app). Copy this whole
hidden folder to a safe location using your file manager (Ctrl+H shows hidden files):

```text
~/.var/app/io.github.AyAmbo.ComfyUIFlatpak
```

It contains models, custom nodes, settings, Python user packages and named profiles.
Back up externally linked models separately. Ensure the backup disk has enough space.
A reinstall keeps app data, but new upstream code/custom nodes may change that data.
Keep the previous release assets if you want to roll back; stop the app before restoring
its backup. Do not use `--delete-data` for an upgrade.

## 3. Verify and install

Download ALL files for this release into a new, otherwise empty folder. Never mix
parts from different releases. Open a terminal in that folder. Allow approximately
10 GB for parts, recombination and decompression, plus space for the installed app/runtime.

```bash
sha256sum -c AyAmbo-ComfyUIFlatpak.flatpak.zst.parts.sha256 && \
cat AyAmbo-ComfyUIFlatpak.flatpak.zst.part-* > AyAmbo-ComfyUIFlatpak.flatpak.zst && \
sha256sum -c AyAmbo-ComfyUIFlatpak.flatpak.zst.sha256 && \
zstd -d AyAmbo-ComfyUIFlatpak.flatpak.zst && \
sha256sum -c AyAmbo-ComfyUIFlatpak.flatpak.sha256 && \
flatpak install --user --reinstall ./AyAmbo-ComfyUIFlatpak.flatpak && \
flatpak run io.github.AyAmbo.ComfyUIFlatpak
```

**Stop if any checksum fails.** Download the failed file again. The full `.flatpak`
is too large for a GitHub release asset; it is reconstructed by the commands above.
If you already have the full local bundle, verify its `.sha256` and install it directly.

Open http://127.0.0.1:8188 in your browser. The startup log should show ComfyUI 0.35.0.
First start may download small Manager registry metadata. Model downloads are separate.
Existing custom-node user packages can override bundled packages; a clean-profile test
does not guarantee an existing heavily customized profile works without dependency repair.

For a separate test profile (without changing your normal profile):

```bash
flatpak run io.github.AyAmbo.ComfyUIFlatpak --profile try-v0.5 --port 8189
```

Open http://127.0.0.1:8189. See README.md for model locations, pip/uv helpers, multiple
GPUs/profiles and custom-node requirements installation. Do not run workflows or install
custom nodes from sources you do not trust.
