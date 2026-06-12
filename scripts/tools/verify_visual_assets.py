from __future__ import annotations

import hashlib
import json
import re
import sys
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[2]
MOJIBAKE_RE = re.compile(r"�|Ã|Â|嚗|蝛|撱|敶|鈭|瘙|||||\?|\?|\?菟")
HASH_TYPES = {"npc", "structure", "item", "equipment"}


def resolve(path: str) -> Path:
    if path.startswith("res://"):
        return ROOT / path.replace("res://", "", 1)
    return ROOT / path


def fail(message: str, failures: list[str]) -> None:
    failures.append(message)
    print(f"[FAIL] {message}")


def check_image(path: Path, label: str, failures: list[str]) -> bytes | None:
    if not path.exists():
        fail(f"{label} missing: {path}", failures)
        return None
    try:
        image = Image.open(path).convert("RGBA")
    except Exception as exc:  # pragma: no cover - command line validator
        fail(f"{label} cannot load: {path} ({exc})", failures)
        return None
    alpha = image.getchannel("A")
    if alpha.getbbox() is None:
        fail(f"{label} is fully transparent: {path}", failures)
    return path.read_bytes()


def verify_manifest(failures: list[str]) -> None:
    manifest_path = ROOT / "data" / "art" / "visual_assets.json"
    data = json.loads(manifest_path.read_text(encoding="utf-8"))
    assets: dict[str, dict] = data.get("assets", {})
    if len(assets) < 35:
        fail("visual asset manifest has too few entries", failures)
    seen_paths: dict[str, str] = {}
    hashes: dict[str, str] = {}
    for asset_id, asset in assets.items():
        path = str(asset.get("path", ""))
        if not path:
            fail(f"{asset_id} has no path", failures)
            continue
        if path in seen_paths and asset.get("type") in HASH_TYPES:
            fail(f"{asset_id} shares exact path with {seen_paths[path]}: {path}", failures)
        seen_paths[path] = asset_id
        raw = check_image(resolve(path), asset_id, failures)
        if raw is not None and asset.get("type") in HASH_TYPES:
            digest = hashlib.sha256(raw).hexdigest()
            if digest in hashes:
                fail(f"{asset_id} has duplicate PNG hash with {hashes[digest]}", failures)
            hashes[digest] = asset_id
        portrait = str(asset.get("portrait", ""))
        if portrait:
            check_image(resolve(portrait), f"{asset_id} portrait", failures)
        variant_prefix = str(asset.get("variant_prefix", ""))
        variants = int(asset.get("variants", 0))
        if variant_prefix and variants > 0:
            variant_hashes: set[str] = set()
            for index in range(variants):
                variant_path = resolve(f"{variant_prefix}{index}.png")
                raw_variant = check_image(variant_path, f"{asset_id} variant {index}", failures)
                if raw_variant is not None:
                    variant_hashes.add(hashlib.sha256(raw_variant).hexdigest())
            if len(variant_hashes) < min(variants, 4):
                fail(f"{asset_id} has too few visually distinct variants", failures)


def verify_json_references(failures: list[str]) -> None:
    for path in [
        ROOT / "data" / "maps" / "npcs.json",
        ROOT / "data" / "maps" / "quests.json",
        ROOT / "data" / "maps" / "events.json",
        ROOT / "data" / "maps" / "wasteland_routes.json",
        ROOT / "data" / "items" / "equipment.json",
        ROOT / "data" / "items" / "recipes.json",
        ROOT / "data" / "enemies" / "enemies.json",
    ]:
        json.loads(path.read_text(encoding="utf-8"))


def verify_no_mojibake(failures: list[str]) -> None:
    for pattern in ("*.gd", "*.json", "*.md"):
        for path in ROOT.rglob(pattern):
            if ".godot" in path.parts:
                continue
            text = path.read_text(encoding="utf-8", errors="replace")
            match = MOJIBAKE_RE.search(text)
            if match:
                fail(f"mojibake marker in {path.relative_to(ROOT)} near {match.group(0)!r}", failures)


def main() -> int:
    failures: list[str] = []
    verify_manifest(failures)
    verify_json_references(failures)
    verify_no_mojibake(failures)
    if failures:
        print(f"[VERIFY] visual asset validation failed: {len(failures)} issue(s)")
        return 1
    print("[VERIFY] visual assets OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
