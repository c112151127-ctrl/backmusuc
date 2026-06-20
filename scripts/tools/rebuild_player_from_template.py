
from __future__ import annotations

# This script is intentionally focused on player graphics only.
# It rebuilds the R-17 player frames from:
#   assets/sprites/player/source/r17_reference.png
#
# Run from the Godot project root:
#   python scripts/tools/rebuild_player_from_template.py

import json
import math
import shutil
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageEnhance, ImageFilter, ImageOps
import scipy.ndimage as ndi

ROOT = Path(__file__).resolve().parents[2]
SPRITES = ROOT / "assets" / "sprites"
PLAYER = SPRITES / "player"
SOURCE = PLAYER / "source" / "r17_reference.png"
FRAME_W = 112
FRAME_H = 128
FRAMES_PER_ACTION = 8
DIRECTIONS = 8
ACTIONS = ["idle", "walk", "shoot", "draw_sword", "slash", "swap_tool", "interact", "hit", "dead"]

BOXES = {
    "idle_down": (66,40,274,308),
    "idle_down_right": (296,41,463,343),
    "idle_up_left": (508,41,619,343),
    "idle_up": (655,41,861,333),
    "idle_right": (1158,41,1327,345),
    "walk0": (36,375,209,592),
    "walk1": (226,375,388,592),
    "walk2": (392,376,561,593),
    "walk3": (571,375,701,592),
    "walk4": (732,373,827,589),
    "walk5": (870,378,999,590),
    "walk6": (1044,378,1186,588),
    "walk7": (1200,378,1358,595),
    "walk_side_blade": (1370,375,1535,595),
    "walk_side_blade2": (1546,392,1685,581),
    "walk_side_blade3": (1690,398,1810,595),
    "slash0": (36,614,233,810),
    "slash1": (275,611,568,815),
    "slash2": (572,614,723,820),
    "slash3": (735,617,974,822),
    "slash4": (984,633,1137,830),
    "shoot0": (1203,633,1387,830),
    "shoot1": (1414,632,1605,823),
    "shoot2": (1622,634,1835,834),
    "shoot3": (25,851,208,1034),
    "shoot4": (242,847,432,1037),
    "shoot5": (471,846,653,1030),
    "shoot6": (693,851,875,1035),
    "shoot7": (918,851,1124,1041),
    "scan0": (1147,858,1326,1052),
    "scan1": (1409,857,1577,1063),
    "tool0": (1639,860,1790,1039),
    "loot0": (33,1065,182,1237),
    "crouch0": (229,1079,346,1237),
    "crouch1": (387,1080,508,1237),
    "drink": (542,1091,686,1237),
    "sit0": (714,1096,849,1237),
    "sit1": (869,1100,1005,1237),
    "sit2": (1046,1099,1163,1237),
    "weapon_claw": (1375,137,1549,256),
    "weapon_saw": (1557,141,1724,260),
    "weapon_barrel": (1370,278,1514,361),
    "weapon_cannon": (1545,277,1679,358),
    "weapon_hook": (1707,290,1821,370),
}

def ensure(path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)

def crop_foreground(sheet: Image.Image, box: tuple[int, int, int, int], pad: int = 2) -> Image.Image:
    crop = sheet.crop(box).convert("RGBA")
    arr = np.array(crop)
    r, g, b, a = arr[:, :, 0], arr[:, :, 1], arr[:, :, 2], arr[:, :, 3]
    maxv = np.maximum.reduce([r, g, b])
    minv = np.minimum.reduce([r, g, b])
    bg = (r < 60) & (g < 65) & (b < 70) & ((maxv - minv) < 20)
    mask = (a > 0) & (~bg) & ((maxv > 55) | ((g > 65) & (b > 50)) | (r > 70) | (a < 250))
    mask = ndi.binary_closing(mask, structure=np.ones((2, 2)))
    mask = ndi.binary_dilation(mask, structure=np.ones((2, 2)))
    ys, xs = np.where(mask)
    if len(xs) == 0:
        return Image.new("RGBA", (1, 1), (0, 0, 0, 0))
    x0, x1 = max(0, xs.min() - pad), min(crop.width, xs.max() + 1 + pad)
    y0, y1 = max(0, ys.min() - pad), min(crop.height, ys.max() + 1 + pad)
    crop2 = crop.crop((x0, y0, x1, y1))
    mask2 = Image.fromarray((mask[y0:y1, x0:x1] * 255).astype("uint8")).filter(ImageFilter.MaxFilter(3))
    out = Image.new("RGBA", crop2.size, (0, 0, 0, 0))
    out.alpha_composite(crop2)
    out.putalpha(mask2)
    return out

def fit_to_frame(subject: Image.Image, action: str, frame: int, tint: str | None = None) -> Image.Image:
    bbox = subject.getbbox()
    if bbox:
        subject = subject.crop(bbox)
    if tint == "hit":
        subject = ImageEnhance.Color(subject).enhance(0.7)
        subject = Image.alpha_composite(subject, Image.new("RGBA", subject.size, (255, 70, 50, 55)))
    canvas = Image.new("RGBA", (FRAME_W, FRAME_H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(canvas, "RGBA")
    draw.ellipse((FRAME_W * 0.18, FRAME_H - 18, FRAME_W * 0.82, FRAME_H - 5), fill=(0, 0, 0, 90))
    if action in {"shoot", "slash", "draw_sword"}:
        fill_h, fill_w = 108, 106
    elif action in {"dead", "interact", "swap_tool"}:
        fill_h, fill_w = 103, 106
    else:
        fill_h, fill_w = 110, 92
    scale = min(fill_w / max(1, subject.width), fill_h / max(1, subject.height), 1.45)
    nw, nh = max(1, int(subject.width * scale)), max(1, int(subject.height * scale))
    res = subject.resize((nw, nh), Image.Resampling.LANCZOS)
    bob = [1, 0, -2, 0, 1, 0, -1, 0][frame % 8] if action == "walk" else 0
    canvas.alpha_composite(res, ((FRAME_W - nw) // 2, FRAME_H - nh - 9 + bob))
    return canvas

def mirrored(image: Image.Image) -> Image.Image:
    return ImageOps.mirror(image)

def build() -> None:
    if not SOURCE.exists():
        raise FileNotFoundError(f"Missing source template: {SOURCE}")
    sheet = Image.open(SOURCE).convert("RGBA")
    cache: dict[str, Image.Image] = {}
    def get(name: str) -> Image.Image:
        if name not in cache:
            cache[name] = crop_foreground(sheet, BOXES[name])
        return cache[name].copy()

    def make_sources(action: str, frame: int) -> dict[int, Image.Image]:
        base = {
            0: get("idle_right"),
            1: get("idle_down_right"),
            2: get("idle_down"),
            5: get("idle_up_left"),
            6: get("idle_up"),
        }
        if action == "walk":
            seq = ["walk0","walk1","walk2","walk3","walk4","walk5","walk6","walk7"]
            current = get(seq[frame % 8])
            base = {
                0: get(["walk_side_blade","walk_side_blade2","walk_side_blade3"][frame % 3]),
                1: current,
                2: current,
                5: get("idle_up_left"),
                6: get("idle_up"),
            }
        elif action in {"shoot", "draw_sword", "slash"}:
            # These action frames intentionally reuse the clean idle body frames.
            # Attack visuals are spawned separately by AttackFlash/Projectile in-game.
            # Do not crop weapon/action poses from the source sheet here; those poses
            # bake a large gun/blade into the player body and look like a foreign object
            # attached to R-17 during shooting/slashing.
            base = {
                0: get("idle_right"),
                1: get("idle_down_right"),
                2: get("idle_down"),
                5: get("idle_up_left"),
                6: get("idle_up"),
            }
        elif action == "swap_tool":
            seq = ["tool0","scan0","scan1","tool0","drink","tool0","scan0","tool0"]
            src = get(seq[frame % 8])
            base = {0: src, 1: src, 2: src, 5: get("idle_up_left"), 6: get("idle_up")}
        elif action == "interact":
            seq = ["loot0","crouch0","crouch1","drink","sit0","sit1","sit2","crouch0"]
            src = get(seq[frame % 8])
            base = {0: src, 1: src, 2: src, 5: get("idle_up_left"), 6: get("idle_up")}
        elif action == "dead":
            seq = ["sit0","sit1","sit2","crouch1","sit2","sit1","sit0","sit0"]
            src = get(seq[frame % 8])
            base = {0: src, 1: src, 2: src, 5: src, 6: src}
        base[3] = mirrored(base[1])
        base[4] = mirrored(base[0])
        base[7] = mirrored(base[5])
        for i in range(8):
            base.setdefault(i, get("idle_down"))
        return base

    frame_dir = PLAYER / "frames"
    action_dir = PLAYER / "actions"
    weapon_dir = PLAYER / "weapons"
    for path in [frame_dir, action_dir, weapon_dir]:
        if path.exists():
            shutil.rmtree(path)
        path.mkdir(parents=True, exist_ok=True)
    atlas = Image.new("RGBA", (FRAME_W * FRAMES_PER_ACTION * len(ACTIONS), FRAME_H * DIRECTIONS), (0,0,0,0))
    for ai, action in enumerate(ACTIONS):
        action_sheet = Image.new("RGBA", (FRAME_W * FRAMES_PER_ACTION, FRAME_H * DIRECTIONS), (0,0,0,0))
        for frame in range(FRAMES_PER_ACTION):
            sources = make_sources(action, frame)
            for direction in range(DIRECTIONS):
                frame_img = fit_to_frame(sources[direction], action, frame, "hit" if action == "hit" and frame % 2 in {0,1} else None)
                out = frame_dir / action / f"dir_{direction}" / f"frame_{frame}.png"
                ensure(out)
                frame_img.save(out)
                atlas.alpha_composite(frame_img, ((ai * FRAMES_PER_ACTION + frame) * FRAME_W, direction * FRAME_H))
                action_sheet.alpha_composite(frame_img, (frame * FRAME_W, direction * FRAME_H))
        action_sheet.save(action_dir / f"{action}.png")
    atlas.save(PLAYER / "recycler_player_multiaction_8dir.png")
    write_manifest()
    build_diagnostic()
    print("Player template frames rebuilt.")

def write_manifest() -> None:
    path = ROOT / "data" / "art" / "player_animation_manifest.json"
    ensure(path)
    manifest = {
        "frame_size": [FRAME_W, FRAME_H],
        "directions": DIRECTIONS,
        "frames_per_action": FRAMES_PER_ACTION,
        "atlas_path": "res://assets/sprites/player/recycler_player_multiaction_8dir.png",
        "split_frame_dir": "res://assets/sprites/player/frames",
        "action_sheet_dir": "res://assets/sprites/player/actions",
        "reference_path": "res://assets/sprites/player/source/r17_reference.png",
        "direction_order": ["right", "down_right", "down", "down_left", "left", "up_left", "up", "up_right"],
        "actions": [{"id": a, "frames": FRAMES_PER_ACTION, "loop": a in {"idle","walk"}, "fps": 8 if a in {"idle","walk"} else 14} for a in ACTIONS],
    }
    path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

def build_diagnostic() -> None:
    labels = [("idle",0,0),("idle",4,0),("walk",0,2),("walk",4,6),("shoot",0,4),("shoot",4,4),("slash",0,5),("slash",4,5),("interact",2,3),("dead",2,6)]
    docs = ROOT / "docs"
    docs.mkdir(parents=True, exist_ok=True)
    scale = 2
    preview = Image.new("RGBA", (FRAME_W * scale * len(labels), FRAME_H * scale + 28), (16,18,20,255))
    draw = ImageDraw.Draw(preview, "RGBA")
    for i, (action, direction, frame) in enumerate(labels):
        image = Image.open(PLAYER / "frames" / action / f"dir_{direction}" / f"frame_{frame}.png").convert("RGBA").resize((FRAME_W * scale, FRAME_H * scale), Image.Resampling.NEAREST)
        x = i * FRAME_W * scale
        preview.alpha_composite(image, (x, 0))
        draw.text((x + 8, FRAME_H * scale + 5), f"{action} d{direction} f{frame}", fill=(230,230,220,255))
    preview.save(docs / "player_split_frame_diagnostic.png")

if __name__ == "__main__":
    build()
