from __future__ import annotations

import hashlib
import json
import sys
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[2]
HASH_TYPES = {"npc", "structure", "item", "equipment", "enemy", "boss", "weapon_overlay"}
TEXT_SCAN_DIRS = ["data", "scenes", "scripts", "docs"]
MOJIBAKE_MARKERS = [
    "\ufffd",
    "嚗",
    "敶",
    "蝝",
    "銝",
    "瘝",
    "憪",
    "摮",
    "鈭",
    "餈",
    "皜",
    "撱",
    "璈",
    "鋆",
    "詻",
    "",
    "",
    ""
]


def resolve(path: str) -> Path:
    if path.startswith("res://"):
        return ROOT / path.replace("res://", "", 1)
    return ROOT / path


def fail(message: str, failures: list[str]) -> None:
    failures.append(message)
    print(f"[FAIL] {message}")


def read_json(path: Path, failures: list[str]) -> dict:
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except Exception as exc:
        fail(f"JSON parse failed: {path.relative_to(ROOT)} ({exc})", failures)
        return {}
    return data if isinstance(data, dict) else {}


def check_image(path: Path, label: str, failures: list[str]) -> bytes | None:
    if not path.exists():
        fail(f"{label} missing: {path.relative_to(ROOT)}", failures)
        return None
    try:
        image = Image.open(path).convert("RGBA")
    except Exception as exc:
        fail(f"{label} cannot load: {path.relative_to(ROOT)} ({exc})", failures)
        return None
    alpha = image.getchannel("A")
    if alpha.getbbox() is None:
        fail(f"{label} is fully transparent: {path.relative_to(ROOT)}", failures)
    if image.size[0] < 8 or image.size[1] < 8:
        fail(f"{label} is too small to be a production asset: {path.relative_to(ROOT)}", failures)
    return path.read_bytes()


def verify_manifest(failures: list[str]) -> None:
    manifest_path = ROOT / "data" / "art" / "visual_assets.json"
    data = read_json(manifest_path, failures)
    assets: dict[str, dict] = data.get("assets", {}) if isinstance(data.get("assets", {}), dict) else {}
    if len(assets) < 35:
        fail("visual asset manifest has too few entries", failures)

    seen_paths: dict[str, str] = {}
    hashes: dict[str, str] = {}
    for asset_id, asset in assets.items():
        path = str(asset.get("path", ""))
        asset_type = str(asset.get("type", ""))
        if not path:
            fail(f"{asset_id} has no path", failures)
            continue
        if bool(asset.get("unique_required", False)) and path in seen_paths:
            fail(f"{asset_id} shares exact path with {seen_paths[path]}: {path}", failures)
        seen_paths[path] = asset_id

        raw = check_image(resolve(path), asset_id, failures)
        if raw is not None and asset_type in HASH_TYPES and bool(asset.get("unique_required", False)):
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
        ROOT / "data" / "art" / "player_animation_manifest.json",
    ]:
        read_json(path, failures)


def verify_player_manifest(failures: list[str]) -> None:
    manifest = read_json(ROOT / "data" / "art" / "player_animation_manifest.json", failures)
    frame_size = manifest.get("frame_size", [])
    directions = int(manifest.get("directions", 0))
    frames = int(manifest.get("frames_per_action", 0))
    actions = manifest.get("actions", [])
    if frame_size != [80, 96]:
        fail("R-17 player manifest frame_size must be [80, 96]", failures)
    if directions != 8 or frames != 4 or len(actions) != 9:
        fail("R-17 player manifest must define 9 actions, 8 directions, 4 frames", failures)

    atlas_path = resolve(str(manifest.get("atlas_path", "")))
    if atlas_path.exists():
        image = Image.open(atlas_path).convert("RGBA")
        if image.size != (2880, 768):
            fail(f"R-17 atlas size must be 2880x768, got {image.size}", failures)


def verify_no_mojibake(failures: list[str]) -> None:
    for directory in TEXT_SCAN_DIRS:
        base = ROOT / directory
        if not base.exists():
            continue
        for path in base.rglob("*"):
            if ".godot" in path.parts or path.suffix.lower() not in {".gd", ".json", ".md", ".txt"}:
                continue
            text = path.read_text(encoding="utf-8", errors="replace")
            for marker in MOJIBAKE_MARKERS:
                index = text.find(marker)
                if index >= 0:
                    near = text[max(0, index - 18): index + 18].replace("\n", " ")
                    fail(f"mojibake marker in {path.relative_to(ROOT)} near {near!r}", failures)
                    break


def main() -> int:
    failures: list[str] = []
    verify_manifest(failures)
    verify_json_references(failures)
    verify_player_manifest(failures)
    verify_no_mojibake(failures)
    if failures:
        print(f"[VERIFY] visual asset validation failed: {len(failures)} issue(s)")
        return 1
    print("[VERIFY] visual assets OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
