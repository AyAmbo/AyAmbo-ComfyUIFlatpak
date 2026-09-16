#!/usr/bin/env python3
"""Check a running test-profile server; execute only a small, model-free image graph."""

import argparse
import json
import re
import time
import urllib.parse
import urllib.request

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--url", default="http://127.0.0.1:8189")
parser.add_argument("--expected-version", default="0.36.0")
args = parser.parse_args()


def request(path, payload=None):
    data = None if payload is None else json.dumps(payload).encode()
    req = urllib.request.Request(args.url + path, data=data,
                                 headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=30) as response:
        assert response.status == 200
        return response.read()


stats = json.loads(request("/system_stats"))
assert stats["system"]["comfyui_version"] == args.expected_version, stats
print("API packaged version:", stats["system"]["comfyui_version"])
html = request("/").decode()
assert "<html" in html.lower()
# Optional user.css can legitimately be absent in a fresh profile. Check the
# bundled assets, not user stylesheets or external resources.
assets = re.findall(r'(?:src|href)="((?:\./|/)?assets/[^\"]+\.(?:js|css))"', html)
assert assets, "No bundled frontend JS/CSS assets in index"
for asset in assets[:3]:
    assert request("/" + asset.lstrip("./")), asset
print("Frontend HTML and", min(3, len(assets)), "JS/CSS assets: HTTP 200")
nodes = json.loads(request("/object_info"))
assert "EmptyImage" in nodes and "SaveImage" in nodes
print("Registered node types:", len(nodes))
request("/queue")
prompt = {
    "1": {"class_type": "EmptyImage", "inputs": {
        "width": 64, "height": 64, "batch_size": 1, "color": 0x336699}},
    "2": {"class_type": "SaveImage", "inputs": {
        "images": ["1", 0], "filename_prefix": "flatpak-smoke"}},
}
result = json.loads(request("/prompt", {"prompt": prompt}))
assert not result.get("node_errors"), result
prompt_id = result["prompt_id"]
for _ in range(60):
    history = json.loads(request("/history/" + prompt_id))
    if prompt_id in history:
        item = history[prompt_id]
        assert item["status"]["status_str"] == "success", item
        image = item["outputs"]["2"]["images"][0]
        content = request("/view?" + urllib.parse.urlencode(image))
        assert content.startswith(b"\x89PNG\r\n\x1a\n"), content[:32]
        print("Model-free EmptyImage -> SaveImage: success, PNG bytes:", len(content))
        break
    time.sleep(1)
else:
    raise RuntimeError("Image graph did not complete within 60 seconds")
print("This is not a diffusion/model inference or browser interaction test.")
