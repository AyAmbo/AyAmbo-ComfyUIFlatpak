#!/usr/bin/env bash
# Regression checks for uv argument dispatch without network or a Flatpak install.
set -euo pipefail
cd "$(dirname "$0")/.."
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/bin"
cat > "$TMP/bin/python3" <<'EOF'
#!/usr/bin/env bash
printf '%s\0' "$@" > "$UV_TEST_CAPTURE"
printf '%s' "$PYTHONUSERBASE" > "$UV_TEST_BASE"
exit "${UV_TEST_EXIT:-0}"
EOF
chmod +x "$TMP/bin/python3"
export PATH="$TMP/bin:$PATH"
export XDG_DATA_HOME="$TMP/data with spaces" XDG_CACHE_HOME="$TMP/cache"
export COMFYUI_FLATPAK_PROFILE='gpu/1'
unset COMFYUI_FLATPAK_PY_USER_BASE
export UV_TEST_CAPTURE="$TMP/args" UV_TEST_BASE="$TMP/base"
BASE="$XDG_DATA_HOME/python-profiles/gpu_1"

check_args() {
  local expected=("$@") actual=()
  mapfile -d '' -t actual < "$UV_TEST_CAPTURE"
  test "${#actual[@]}" -eq "${#expected[@]}"
  for i in "${!expected[@]}"; do
    test "${actual[$i]}" = "${expected[$i]}"
  done
  test "$(cat "$UV_TEST_BASE")" = "$BASE"
}

for cmd in install uninstall sync list freeze show; do
  bash packaging/comfyui-flatpak-uv pip "$cmd" 'argument with spaces'
  check_args -m uv pip "$cmd" --system --prefix "$BASE" 'argument with spaces'
done
for cmd in check tree; do
  bash packaging/comfyui-flatpak-uv pip "$cmd" --help
  check_args -m uv pip "$cmd" --system --help
done
for arg in --help --version compile invalid-command; do
  bash packaging/comfyui-flatpak-uv pip "$arg"
  check_args -m uv pip "$arg"
done
bash packaging/comfyui-flatpak-uv --version
check_args -m uv --version
bash packaging/comfyui-flatpak-uv pip
check_args -m uv pip
export UV_TEST_EXIT=37
status=0
bash packaging/comfyui-flatpak-uv pip invalid-command || status=$?
test "$status" -eq 37
unset UV_TEST_EXIT
export COMFYUI_FLATPAK_PROFILE=default
BASE="$XDG_DATA_HOME/python"
bash packaging/comfyui-flatpak-uv pip list
check_args -m uv pip list --system --prefix "$BASE"
export COMFYUI_FLATPAK_PY_USER_BASE="$TMP/explicit prefix"
BASE="$COMFYUI_FLATPAK_PY_USER_BASE"
bash packaging/comfyui-flatpak-uv pip show example
check_args -m uv pip show --system --prefix "$BASE" example
printf 'uv helper dispatch, quoting, exit codes and profile paths: PASS\n'
