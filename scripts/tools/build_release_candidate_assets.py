from __future__ import annotations

import json
import math
import shutil
import wave
from pathlib import Path

from PIL import Image, ImageDraw, ImageEnhance, ImageFilter, ImageOps


ROOT = Path(__file__).resolve().parents[2]
SPRITES = ROOT / "assets" / "sprites"
DOCS = ROOT / "docs"
REFERENCE_SOURCE = Path(
    r"C:\Users\wuwu6\.codex\generated_images\019e9e33-9677-73b2-8b87-c6acad59966e\ig_0754933d1d3f43ca016a2c1881a16881919ef893001a05800f.png"
)
REFERENCE_COPY = DOCS / "art_direction_reference_r17_v4.png"

FRAME_W = 80
FRAME_H = 96
FRAMES_PER_ACTION = 4
DIRECTIONS = 8
ACTIONS = [
    "idle",
    "walk",
    "shoot",
    "draw_sword",
    "slash",
    "swap_tool",
    "interact",
    "hit",
    "dead",
]


BASE_BOXES = {
    0: (800, 50, 873, 111),   # right
    1: (585, 50, 661, 114),   # down-right
    2: (111, 34, 185, 114),   # down/front
    3: (423, 50, 498, 120),   # down-left
    4: (274, 26, 350, 120),   # left
    5: (422, 122, 507, 190),  # up-left
    6: (267, 119, 350, 196),  # up/back
    7: (582, 120, 663, 193),  # up-right
}


def ensure(path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)


def load_reference() -> Image.Image:
    source = REFERENCE_SOURCE if REFERENCE_SOURCE.exists() else REFERENCE_COPY
    if not source.exists():
        raise FileNotFoundError(f"Missing R-17 reference image: {source}")
    ensure(REFERENCE_COPY)
    if source.resolve() != REFERENCE_COPY.resolve():
        shutil.copyfile(source, REFERENCE_COPY)
    return Image.open(source).convert("RGBA")


def is_checker_background(r: int, g: int, b: int) -> bool:
    return r < 46 and g < 49 and b < 54 and max(r, g, b) - min(r, g, b) < 16


def crop_foreground(sheet: Image.Image, box: tuple[int, int, int, int]) -> Image.Image:
    crop = sheet.crop((box[0], box[1], box[2] + 1, box[3] + 1)).convert("RGBA")
    w, h = crop.size
    pixels = crop.load()
    strong = Image.new("L", (w, h), 0)
    mask_pixels = strong.load()
    for y in range(h):
        for x in range(w):
            r, g, b, a = pixels[x, y]
            if a > 0 and not is_checker_background(r, g, b):
                if max(r, g, b) > 58 or (g > 70 and b > 55) or (r > 72 and g > 45):
                    mask_pixels[x, y] = 255
    mask = strong.filter(ImageFilter.MaxFilter(5))
    bbox = mask.getbbox()
    if bbox is None:
        return Image.new("RGBA", (FRAME_W, FRAME_H), (0, 0, 0, 0))
    crop = crop.crop(bbox)
    mask = mask.crop(bbox)
    out = Image.new("RGBA", crop.size, (0, 0, 0, 0))
    out.alpha_composite(crop)
    out.putalpha(mask)
    return out


def direction_vector(direction: int) -> tuple[float, float]:
    angle = math.radians(direction * 45.0)
    return math.cos(angle), math.sin(angle)


def fit_to_frame(sprite: Image.Image, action: str, direction: int, frame: int) -> Image.Image:
    canvas = Image.new("RGBA", (FRAME_W, FRAME_H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(canvas, "RGBA")
    draw.ellipse((17, 82, 63, 93), fill=(0, 0, 0, 92))

    body = sprite.copy()
    target_h = 72 if action not in {"dead", "slash"} else 68
    scale = min(1.0, target_h / max(1, body.height))
    body = body.resize((max(1, int(body.width * scale)), max(1, int(body.height * scale))), Image.Resampling.LANCZOS)
    bob = 0
    if action == "walk":
        bob = [1, -2, 1, 0][frame % 4]
    if action == "hit":
        body = ImageEnhance.Color(body).enhance(0.45)
        body = ImageEnhance.Brightness(body).enhance(1.22)
    x = (FRAME_W - body.width) // 2
    y = FRAME_H - body.height - 9 + bob
    if action == "dead":
        body = body.rotate(-72 if direction in [0, 1, 7] else 72, expand=True, resample=Image.Resampling.BICUBIC)
        x = (FRAME_W - body.width) // 2
        y = FRAME_H - body.height - 12
    canvas.alpha_composite(body, (x, y))
    _draw_action_overlay(canvas, action, direction, frame)
    return canvas


def _draw_action_overlay(canvas: Image.Image, action: str, direction: int, frame: int) -> None:
    draw = ImageDraw.Draw(canvas, "RGBA")
    dx, dy = direction_vector(direction)
    cx, cy = 40, 54
    if action == "shoot":
        recoil = [0, -4, -2, 1][frame]
        start = (cx + dx * 10 + recoil * dx, cy + dy * 6 + recoil * dy)
        end = (cx + dx * 34 + recoil * dx, cy + dy * 23 + recoil * dy)
        draw.line((start, end), fill=(26, 23, 20, 255), width=7)
        draw.line((start, end), fill=(208, 143, 70, 255), width=3)
        draw.line((start[0] - dy * 5, start[1] + dx * 5, end[0] - dy * 5, end[1] + dx * 5), fill=(73, 229, 241, 210), width=2)
        if frame in [1, 2]:
            muzzle = (end[0] + dx * 5, end[1] + dy * 5)
            draw.ellipse((muzzle[0] - 6, muzzle[1] - 6, muzzle[0] + 6, muzzle[1] + 6), fill=(255, 205, 70, 230))
            draw.line((muzzle[0], muzzle[1], muzzle[0] + dx * 18, muzzle[1] + dy * 18), fill=(58, 239, 250, 210), width=3)
    elif action == "draw_sword":
        grip = (cx - dx * 8, cy + 18)
        tip = (cx + dx * (14 + frame * 6), cy + dy * (8 + frame * 5))
        draw.line((grip, tip), fill=(245, 239, 210, 255), width=3)
        draw.line((grip[0] - dy * 5, grip[1] + dx * 5, grip[0] + dy * 5, grip[1] - dx * 5), fill=(205, 112, 45, 255), width=3)
    elif action == "slash":
        radius = 22 + frame * 7
        center = (cx + dx * 13, cy + dy * 10)
        bbox = (center[0] - radius, center[1] - radius, center[0] + radius, center[1] + radius)
        start = direction * 45 - 74
        end = direction * 45 + 74
        draw.arc(bbox, start, end, fill=(255, 180, 54, 250), width=6)
        draw.arc((bbox[0] + 7, bbox[1] + 7, bbox[2] - 7, bbox[3] - 7), start + 10, end - 10, fill=(47, 229, 240, 220), width=3)
        sword_tip = (cx + dx * (24 + frame * 5), cy + dy * (14 + frame * 4))
        draw.line(((cx, cy + 5), sword_tip), fill=(242, 236, 210, 250), width=3)
    elif action == "swap_tool":
        pulse = 12 + frame * 5
        draw.ellipse((cx - pulse, cy - pulse, cx + pulse, cy + pulse), outline=(48, 232, 243, 160), width=3)
        draw.rounded_rectangle((cx + 18, cy - 8, cx + 35, cy + 9), radius=4, fill=(198, 112, 49, 230), outline=(36, 30, 24, 245), width=2)
    elif action == "interact":
        for i in range(4):
            px = cx + dx * (14 + i * 8)
            py = cy + dy * (8 + i * 5)
            draw.ellipse((px - 3, py - 3, px + 3, py + 3), fill=(84, 240, 168, 210))
    elif action == "hit":
        for off in [8, 22, 41]:
            draw.line((off, 25, off + 16, 7), fill=(255, 210, 82, 170), width=2)
        draw.ellipse((33, 47, 47, 61), outline=(255, 82, 58, 150), width=2)
    elif action == "dead":
        draw.arc((18, 49, 62, 91), 190, 348, fill=(42, 230, 238, 130), width=2)
        for off in [23, 36, 51]:
            draw.ellipse((off - 2, 72 - 2, off + 2, 72 + 2), fill=(44, 230, 238, 190))


def build_player_atlas() -> None:
    ref = load_reference()
    base_sprites = {idx: crop_foreground(ref, box) for idx, box in BASE_BOXES.items()}
    sheet = Image.new("RGBA", (FRAME_W * FRAMES_PER_ACTION * len(ACTIONS), FRAME_H * DIRECTIONS), (0, 0, 0, 0))
    for action_index, action in enumerate(ACTIONS):
        for direction in range(DIRECTIONS):
            for frame in range(FRAMES_PER_ACTION):
                sprite = base_sprites[direction]
                frame_image = fit_to_frame(sprite, action, direction, frame)
                sheet.alpha_composite(frame_image, ((action_index * FRAMES_PER_ACTION + frame) * FRAME_W, direction * FRAME_H))
    out = SPRITES / "player" / "recycler_player_multiaction_8dir.png"
    ensure(out)
    sheet.save(out)


def icon_canvas() -> tuple[Image.Image, ImageDraw.ImageDraw]:
    img = Image.new("RGBA", (88, 72), (0, 0, 0, 0))
    d = ImageDraw.Draw(img, "RGBA")
    d.ellipse((12, 54, 76, 68), fill=(0, 0, 0, 88))
    return img, d


def save_icon(name: str, kind: str, accent: tuple[int, int, int]) -> None:
    img, d = icon_canvas()
    rust = (174, 96, 48)
    steel = (152, 158, 144)
    cyan = (54, 224, 236)
    gold = (232, 174, 70)
    green = (105, 214, 76)
    red = (215, 52, 58)
    purple = (183, 88, 236)
    if kind == "blade":
        d.line((18, 54, 63, 15), fill=(38, 34, 30, 255), width=9)
        d.line((21, 51, 64, 14), fill=(238, 233, 205, 255), width=5)
        d.line((25, 48, 51, 25), fill=accent + (230,), width=3)
        d.rounded_rectangle((12, 48, 30, 59), radius=3, fill=rust + (255,), outline=(26, 21, 17, 255), width=2)
    elif kind == "rifle":
        d.rounded_rectangle((12, 33, 62, 45), radius=4, fill=(38, 34, 30, 255), outline=(14, 12, 11, 255), width=2)
        d.rectangle((28, 25, 58, 34), fill=accent + (245,))
        d.rectangle((58, 36, 78, 40), fill=gold + (255,))
        d.line((18, 47, 30, 58), fill=rust + (255,), width=6)
        d.ellipse((66, 30, 78, 42), outline=cyan + (220,), width=2)
    elif kind == "armor":
        d.rounded_rectangle((25, 12, 63, 57), radius=8, fill=accent + (245,), outline=(23, 24, 22, 255), width=3)
        d.rectangle((34, 25, 54, 42), fill=cyan + (180,), outline=(20, 62, 64, 230), width=2)
        d.line((25, 24, 16, 46), fill=steel + (220,), width=4)
        d.line((63, 24, 74, 46), fill=steel + (220,), width=4)
    elif kind == "resource":
        if name == "mutant_core":
            d.ellipse((25, 14, 62, 51), fill=(69, 14, 20, 255), outline=(22, 8, 10, 255), width=3)
            d.ellipse((34, 21, 56, 43), fill=red + (255,))
            for end in [(16, 8), (74, 24), (19, 57), (66, 62)]:
                d.line((44, 33, end[0], end[1]), fill=green + (190,), width=2)
        elif name == "bio_crystal":
            d.polygon([(45, 8), (25, 45), (45, 65), (65, 45)], fill=purple + (245,), outline=(42, 24, 62, 255))
            d.polygon([(45, 8), (35, 43), (45, 65)], fill=(107, 240, 202, 210))
            d.line((49, 15, 58, 43), fill=(255, 235, 255, 180), width=2)
        elif name in {"ammo", "ammo_crate"}:
            d.rounded_rectangle((15, 18, 55, 48), radius=4, fill=(70, 92, 56, 255), outline=(25, 28, 22, 255), width=2)
            d.rectangle((25, 15, 48, 21), fill=gold + (255,))
            for x in [60, 67, 74]:
                d.rounded_rectangle((x, 26, x + 5, 53), radius=2, fill=gold + (255,), outline=(80, 45, 20, 255))
        else:
            for i in range(5):
                x = 12 + i * 8
                d.rounded_rectangle((x, 25 - (i % 2) * 4, x + 25, 36 + (i % 2) * 4), radius=3, fill=(92, 84, 70, 255), outline=(26, 22, 18, 255), width=2)
            d.line((12, 52, 65, 18), fill=gold + (230,), width=4)
    else:
        d.rounded_rectangle((18, 23, 68, 51), radius=7, fill=accent + (245,), outline=(24, 20, 16, 255), width=2)
        d.ellipse((29, 14, 59, 44), fill=cyan + (125,))
        d.line((21, 55, 69, 20), fill=rust + (230,), width=4)
    out = SPRITES / "items" / f"{name}.png"
    ensure(out)
    img.save(out)


def build_item_icons() -> None:
    specs = {
        "scrap_bundle": ("resource", (176, 99, 48)),
        "ammo_crate": ("resource", (92, 118, 65)),
        "mutant_core": ("resource", (214, 52, 58)),
        "bio_crystal": ("resource", (180, 88, 236)),
        "rust_blade": ("blade", (198, 112, 52)),
        "spark_cutter": ("blade", (55, 224, 238)),
        "breaker_hammer": ("blade", (210, 168, 84)),
        "pipe_rifle": ("rifle", (170, 92, 46)),
        "coil_launcher": ("rifle", (48, 220, 236)),
        "acid_sprayer": ("rifle", (102, 215, 76)),
        "patched_armor": ("armor", (95, 104, 94)),
        "crystal_guard": ("armor", (118, 68, 158)),
        "industrial_exoshell": ("armor", (124, 93, 58)),
        "recycler_glove": ("tool", (66, 210, 188)),
        "magnet_breaker": ("tool", (124, 188, 228)),
    }
    for name, (kind, accent) in specs.items():
        save_icon(name, kind, accent)
    atlas = Image.new("RGBA", (88 * 4, 72), (0, 0, 0, 0))
    for i, name in enumerate(["scrap_bundle", "ammo_crate", "mutant_core", "bio_crystal"]):
        atlas.alpha_composite(Image.open(SPRITES / "items" / f"{name}.png").convert("RGBA"), (i * 88, 0))
    atlas.save(SPRITES / "items" / "recycler_item_icons.png")


def build_weapon_overlays() -> None:
    specs = {
        "rust_blade": ("blade", (198, 112, 52)),
        "spark_cutter": ("blade", (55, 224, 238)),
        "breaker_hammer": ("hammer", (226, 174, 78)),
        "pipe_rifle": ("rifle", (174, 96, 48)),
        "coil_launcher": ("rifle", (54, 224, 236)),
        "acid_sprayer": ("rifle", (104, 218, 78)),
        "recycler_glove": ("tool", (66, 210, 188)),
        "magnet_breaker": ("tool", (124, 188, 228)),
    }
    out_dir = SPRITES / "player" / "weapons"
    out_dir.mkdir(parents=True, exist_ok=True)
    for name, (kind, accent) in specs.items():
        img = Image.new("RGBA", (96, 64), (0, 0, 0, 0))
        d = ImageDraw.Draw(img, "RGBA")
        if kind == "blade":
            d.line((20, 48, 74, 13), fill=(22, 19, 17, 255), width=8)
            d.line((23, 45, 75, 12), fill=(240, 235, 210, 255), width=4)
            d.line((30, 40, 64, 19), fill=accent + (240,), width=2)
            d.rounded_rectangle((14, 44, 31, 55), radius=3, fill=(172, 93, 44, 255), outline=(24, 20, 16, 255), width=2)
        elif kind == "hammer":
            d.line((23, 51, 59, 25), fill=(178, 98, 48, 255), width=7)
            d.rounded_rectangle((50, 10, 82, 31), radius=4, fill=(126, 130, 120, 255), outline=(28, 29, 27, 255), width=3)
            d.line((56, 14, 79, 28), fill=accent + (210,), width=2)
        elif kind == "rifle":
            d.rounded_rectangle((18, 31, 74, 43), radius=4, fill=(33, 30, 27, 255), outline=(12, 11, 10, 255), width=2)
            d.rectangle((34, 23, 66, 32), fill=accent + (245,))
            d.rectangle((70, 34, 91, 38), fill=(232, 176, 72, 255))
            d.line((25, 44, 38, 58), fill=(171, 94, 48, 255), width=5)
        else:
            d.rounded_rectangle((34, 20, 66, 45), radius=7, fill=accent + (235,), outline=(24, 22, 18, 255), width=2)
            d.ellipse((42, 12, 58, 29), fill=(56, 226, 236, 170))
            d.line((24, 47, 74, 20), fill=(175, 96, 47, 230), width=4)
        img.save(out_dir / f"{name}_overlay.png")


def write_manifest() -> None:
    manifest = {
        "frame_size": [FRAME_W, FRAME_H],
        "directions": DIRECTIONS,
        "frames_per_action": FRAMES_PER_ACTION,
        "atlas_path": "res://assets/sprites/player/recycler_player_multiaction_8dir.png",
        "reference_path": "res://docs/art_direction_reference_r17_v4.png",
        "actions": [
            {"id": action, "frames": FRAMES_PER_ACTION, "loop": action in {"idle", "walk"}, "fps": 8 if action in {"idle", "walk"} else 14}
            for action in ACTIONS
        ],
    }
    path = ROOT / "data" / "art" / "player_animation_manifest.json"
    ensure(path)
    path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def synth(path: Path, seconds: float, freq: float, volume: float, kind: str) -> None:
    ensure(path)
    sample_rate = 22050
    total = int(sample_rate * seconds)
    with wave.open(str(path), "w") as out:
        out.setnchannels(1)
        out.setsampwidth(2)
        out.setframerate(sample_rate)
        frames = bytearray()
        for i in range(total):
            t = i / sample_rate
            env = max(0.0, 1.0 - t / seconds)
            if kind == "noise":
                value = math.sin(t * freq * 2 * math.pi) * 0.55 + math.sin(t * freq * 5.1 * math.pi) * 0.30
            elif kind == "ui":
                value = math.sin(t * freq * 2 * math.pi) * math.sin(t * 26)
            else:
                value = math.sin(t * freq * 2 * math.pi) + math.sin(t * freq * 1.5 * 2 * math.pi) * 0.35
            sample = int(max(-1, min(1, value * env * volume)) * 32767)
            frames += sample.to_bytes(2, byteorder="little", signed=True)
        out.writeframes(frames)


def build_audio() -> None:
    audio = ROOT / "assets" / "audio"
    specs = {
        "sfx_melee_heavy.wav": (0.22, 180.0, 0.42, "noise"),
        "sfx_shoot_coil.wav": (0.18, 640.0, 0.34, "noise"),
        "sfx_player_hurt.wav": (0.30, 96.0, 0.48, "noise"),
        "sfx_level_up.wav": (0.62, 520.0, 0.30, "tone"),
        "sfx_ui_select.wav": (0.12, 820.0, 0.22, "ui"),
        "sfx_transition.wav": (0.70, 160.0, 0.28, "tone"),
    }
    for name, data in specs.items():
        synth(audio / name, *data)


def main() -> None:
    build_player_atlas()
    build_item_icons()
    build_weapon_overlays()
    build_audio()
    write_manifest()
    print("Built release-candidate R-17 assets, item icons, audio, and animation manifest")


if __name__ == "__main__":
    main()
