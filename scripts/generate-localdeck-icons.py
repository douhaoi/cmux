#!/usr/bin/env python3
"""Render the editable LocalDeck mark into every native app-icon consumer.

Requires rsvg-convert (librsvg). No network is used.
"""

from __future__ import annotations

import copy
import json
import shutil
import struct
import subprocess
import tempfile
import xml.etree.ElementTree as ET
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "Resources/Branding/LocalDeck.svg"


def main() -> None:
    renderer = shutil.which("rsvg-convert")
    if renderer is None:
        raise SystemExit("rsvg-convert is required; install librsvg before generating icons")
    tree = ET.parse(SOURCE)
    root = tree.getroot()
    if root.attrib.get("viewBox") != "0 0 1024 1024":
        raise SystemExit("LocalDeck.svg must use a 1024-square viewBox")

    destinations: dict[int, list[Path]] = {}
    for catalog in sorted((ROOT / "Assets.xcassets").glob("AppIcon*.appiconset")):
        contents = json.loads((catalog / "Contents.json").read_text())
        for entry in contents["images"]:
            pixels = int(entry["size"].split("x")[0]) * int(entry["scale"][0])
            destinations.setdefault(pixels, []).append(catalog / entry["filename"])
    for name in ("AppIconLight", "AppIconDark"):
        destinations.setdefault(1024, []).append(ROOT / f"Assets.xcassets/{name}.imageset/{name}.png")

    with tempfile.TemporaryDirectory(prefix="localdeck-icons-") as temporary:
        rendered_sizes: dict[int, bytes] = {}
        for pixels, targets in sorted(destinations.items()):
            rendered = Path(temporary) / f"{pixels}.png"
            subprocess.run([renderer, "--width", str(pixels), "--height", str(pixels), "--output", str(rendered), str(SOURCE)], check=True)
            for target in targets:
                shutil.copyfile(rendered, target)
            rendered_sizes[pixels] = rendered.read_bytes()
        # macOS 14+ supports these standard PNG-backed ICNS representations.
        representations = {b"icp4": 16, b"icp5": 32, b"icp6": 64, b"ic07": 128,
                           b"ic08": 256, b"ic09": 512, b"ic10": 1024,
                           b"ic11": 32, b"ic12": 64, b"ic13": 256, b"ic14": 512}
        chunks = b"".join(struct.pack(">4sI", kind, len(rendered_sizes[pixels]) + 8) + rendered_sizes[pixels]
                          for kind, pixels in representations.items())
        SOURCE.with_suffix(".icns").write_bytes(struct.pack(">4sI", b"icns", len(chunks) + 8) + chunks)

    # Icon Composer supplies the platform tile; keep only our foreground mark.
    foreground = copy.deepcopy(root)
    for child in list(foreground):
        if child.attrib.get("id") == "background":
            foreground.remove(child)
    ET.register_namespace("", "http://www.w3.org/2000/svg")
    composer = ROOT / "AppIcon.icon"
    assets = composer / "Assets"
    foreground_path = assets / "LocalDeck.svg"
    ET.ElementTree(foreground).write(foreground_path, encoding="unicode", xml_declaration=False)
    original = json.loads((composer / "icon.json").read_text())
    retired_images = [layer.get("image-name") for group in original["groups"] for layer in group["layers"]]
    original["fill"] = {"linear-gradient": ["extended-srgb:0.145,0.243,0.259,1", "extended-srgb:0.063,0.118,0.137,1"]}
    original["groups"] = [{
        "layers": [{"glass": False, "image-name": "LocalDeck.svg", "name": "LocalDeck Workspace"}],
        "lighting": "individual",
        "shadow": {"kind": "none", "opacity": 0},
        "translucency": {"enabled": False, "value": 0},
    }]
    (composer / "icon.json").write_text(json.dumps(original, indent=2) + "\n")
    for name in retired_images:
        if name and name != foreground_path.name and Path(name).name == name:
            (assets / name).unlink(missing_ok=True)
    print(f"Rendered {sum(map(len, destinations.values()))} PNG assets at {len(destinations)} sizes; Icon Composer foreground updated.")


if __name__ == "__main__":
    main()
