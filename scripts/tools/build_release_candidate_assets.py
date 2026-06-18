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
    r"C:\Users\wuwu6\AppData\Local\Temp\codex-clipboard-23e1c8dd-9b16-4a6a-a8a0-fe0a591e045d.png"
)
REFERENCE_FALLBACKS = [
    Path(r"C:\Users\wuwu6\.codex\generated_images\019e9e33-9677-73b2-8b87-c6acad59966e\ig_0754933d1d3f43ca016a2c1881a16881919ef893001a05800f.png"),
    DOCS / "art_direction_reference_r17_full_body.png",
    DOCS / "art_direction_reference_r17_v4.png",
]
REFERENCE_COPY = DOCS / "art_direction_reference_r17_full_body.png"

FRAME_W = 112
FRAME_H = 128
FRAMES_PER_ACTION = 8
DIRECTIONS = 8
PLAYER_FRAME_DIR = SPRITES / "player" / "frames"
PLAYER_ACTION_DIR = SPRITES / "player" / "actions"
PLAYER_WEAPON_DIR = SPRITES / "player" / "weapons"
PLAYER_CLEANUP_AUDIT = DOCS / "player_asset_cleanup_audit.md"
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


SOURCE_BOXES = {
    0: (210, 18, 364, 250),    # right
    1: (764, 18, 914, 250),    # down-right
    2: (38, 18, 198, 250),     # down/front
    5: (366, 18, 520, 250),    # up-left/back-left
    6: (515, 18, 706, 250),    # up/back
}

MIRROR_FROM = {
    3: 1,  # down-left mirrors down-right
    4: 0,  # left mirrors right
    7: 5,  # up-right mirrors up-left
}

WEAPON_MODULE_BOXES = {
    "spark_cutter": (1250, 126, 1340, 200),
    "pipe_rifle": (1105, 218, 1226, 279),
    "coil_launcher": (1220, 218, 1350, 278),
    "acid_sprayer": (1365, 222, 1489, 286),
    "recycler_glove": (1410, 124, 1505, 186),
    "magnet_breaker": (1138, 135, 1225, 196),
}

RESOURCE_MODULE_BOXES = {
    "ammo_crate": (1088, 892, 1165, 975),
    "scrap_bundle": (1290, 893, 1358, 975),
}


def ensure(path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)


def load_reference() -> Image.Image:
    source = REFERENCE_SOURCE if REFERENCE_SOURCE.exists() else None
    if source is None:
        source = next((candidate for candidate in REFERENCE_FALLBACKS if candidate.exists()), None)
    if source is None or not source.exists():
        raise FileNotFoundError("Missing full-body R-17 reference image")
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


def _transparent_polygon(canvas: Image.Image, points: list[tuple[float, float]]) -> None:
    mask = Image.new("L", canvas.size, 0)
    ImageDraw.Draw(mask).polygon(points, fill=255)
    canvas.paste(Image.new("RGBA", canvas.size, (0, 0, 0, 0)), (0, 0), mask)


def _clear_reference_arm_artifacts(canvas: Image.Image) -> None:
    # The source sheet contains large side-arm silhouettes in some poses. They read
    # as extra blades after normalization, so locomotion/action arms are redrawn
    # consistently below instead of trusting each crop.
    _transparent_polygon(canvas, [(0, 54), (24, 55), (35, 102), (24, 126), (0, 126)])
    _transparent_polygon(canvas, [(112, 54), (88, 55), (77, 102), (88, 126), (112, 126)])


def _draw_segmented_arm(draw: ImageDraw.ImageDraw, points: list[tuple[float, float]], hand_radius: int = 5) -> None:
    if len(points) < 2:
        return
    for joint in points[:-1]:
        draw.ellipse((joint[0] - 7, joint[1] - 7, joint[0] + 7, joint[1] + 7), fill=(24, 22, 19, 235))
        draw.ellipse((joint[0] - 5, joint[1] - 5, joint[0] + 5, joint[1] + 5), fill=(190, 184, 162, 230))
    for a, b in zip(points, points[1:]):
        draw.line((a, b), fill=(26, 24, 22, 255), width=10)
        draw.line((a, b), fill=(148, 145, 130, 255), width=6)
        draw.line((a[0] + 1, a[1] - 1, b[0] + 1, b[1] - 1), fill=(221, 222, 197, 205), width=2)
    hand = points[-1]
    draw.ellipse((hand[0] - hand_radius - 1, hand[1] - hand_radius - 1, hand[0] + hand_radius + 1, hand[1] + hand_radius + 1), fill=(23, 32, 33, 255))
    draw.ellipse((hand[0] - hand_radius, hand[1] - hand_radius, hand[0] + hand_radius, hand[1] + hand_radius), fill=(47, 222, 233, 245))


def _draw_robot_arms(canvas: Image.Image, action: str, direction: int, frame: int) -> None:
    draw = ImageDraw.Draw(canvas, "RGBA")
    dx, dy = direction_vector(direction)
    nx, ny = -dy, dx
    progress = frame / max(1, FRAMES_PER_ACTION - 1)
    walk_cycle = math.sin(progress * math.tau)
    cx, cy = FRAME_W * 0.5, FRAME_H * 0.66
    depth_shift = -dy * 3
    left_shoulder = (cx - 15 - dx * 2, cy - 17 + depth_shift)
    right_shoulder = (cx + 15 - dx * 2, cy - 17 + depth_shift)

    if action == "walk":
        left_hand = (
            left_shoulder[0] - 9 - dx * 2 + walk_cycle * 5,
            left_shoulder[1] + 36 - walk_cycle * 4 + abs(dy) * 2,
        )
        right_hand = (
            right_shoulder[0] + 9 - dx * 2 - walk_cycle * 5,
            right_shoulder[1] + 36 + walk_cycle * 4 + abs(dy) * 2,
        )
    elif action in {"shoot", "slash", "draw_sword"}:
        active_side = -1 if dx < -0.2 else 1
        reach = 17 + progress * (5 if action == "shoot" else 9)
        active_shoulder = left_shoulder if active_side < 0 else right_shoulder
        inactive_shoulder = right_shoulder if active_side < 0 else left_shoulder
        active_hand = (cx + dx * reach + active_side * abs(ny) * 4, cy + 13 + dy * (10 + progress * 5))
        if action == "shoot":
            inactive_hand = (inactive_shoulder[0] - active_side * 7 - dx * 2, inactive_shoulder[1] + 33)
        else:
            inactive_hand = (inactive_shoulder[0] - active_side * 8 - dx * 2, inactive_shoulder[1] + 31)
        if active_side < 0:
            left_hand = active_hand
            right_hand = inactive_hand
        else:
            right_hand = active_hand
            left_hand = inactive_hand
    elif action == "swap_tool":
        pulse = math.sin(progress * math.pi)
        left_hand = (left_shoulder[0] - 12, left_shoulder[1] + 30 - pulse * 5)
        right_hand = (right_shoulder[0] + 12, right_shoulder[1] + 30 - pulse * 5)
    elif action == "interact":
        left_hand = (cx - 24, cy + 14 - math.sin(progress * math.pi) * 8)
        right_hand = (cx + 24, cy + 14 - math.sin(progress * math.pi) * 8)
    elif action == "dead":
        left_hand = (cx - 28, cy + 29)
        right_hand = (cx + 28, cy + 31)
    else:
        idle = math.sin(progress * math.tau) * 1.5
        left_hand = (left_shoulder[0] - 7 - dx * 2, left_shoulder[1] + 36 + idle)
        right_hand = (right_shoulder[0] + 7 - dx * 2, right_shoulder[1] + 36 - idle)

    left_elbow = ((left_shoulder[0] + left_hand[0]) * 0.5 - 4, (left_shoulder[1] + left_hand[1]) * 0.5 + 2)
    right_elbow = ((right_shoulder[0] + right_hand[0]) * 0.5 + 4, (right_shoulder[1] + right_hand[1]) * 0.5 + 2)
    _draw_segmented_arm(draw, [left_shoulder, left_elbow, left_hand])
    _draw_segmented_arm(draw, [right_shoulder, right_elbow, right_hand])


def fit_to_frame(sprite: Image.Image, action: str, direction: int, frame: int) -> Image.Image:
    canvas = Image.new("RGBA", (FRAME_W, FRAME_H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(canvas, "RGBA")
    draw.ellipse((FRAME_W * 0.18, FRAME_H - 19, FRAME_W * 0.82, FRAME_H - 5), fill=(0, 0, 0, 92))

    body = sprite.copy()
    target_h = 102 if action not in {"dead", "slash"} else 98
    scale = min(1.0, target_h / max(1, body.height))
    body = body.resize((max(1, int(body.width * scale)), max(1, int(body.height * scale))), Image.Resampling.LANCZOS)
    bob = 0
    if action == "walk":
        bob = [1, 0, -2, 0, 1, 0, -1, 0][frame % FRAMES_PER_ACTION]
    if action == "hit":
        body = ImageEnhance.Color(body).enhance(0.45)
        body = ImageEnhance.Brightness(body).enhance(1.22)
    x = (FRAME_W - body.width) // 2
    y = FRAME_H - body.height - 11 + bob
    if action == "dead":
        body = body.rotate(-72 if direction in [0, 1, 7] else 72, expand=True, resample=Image.Resampling.BICUBIC)
        x = (FRAME_W - body.width) // 2
        y = FRAME_H - body.height - 10
    canvas.alpha_composite(body, (x, y))
    if action != "dead":
        _clear_reference_arm_artifacts(canvas)
    _draw_robot_arms(canvas, action, direction, frame)
    _draw_body_action_cues(canvas, action, direction, frame)
    return canvas


def _draw_body_action_cues(canvas: Image.Image, action: str, direction: int, frame: int) -> None:
    draw = ImageDraw.Draw(canvas, "RGBA")
    dx, dy = direction_vector(direction)
    cx, cy = FRAME_W * 0.5, FRAME_H * 0.60
    progress = frame / max(1, FRAMES_PER_ACTION - 1)
    active_side = -1 if dx < -0.2 else 1
    hand = (cx + dx * (17 + progress * 5), cy + 13 + dy * (10 + progress * 5))

    # Weapon art is intentionally not baked into body frames.  The runtime
    # WeaponOverlay owns blades, guns, muzzle flashes and slash arcs so the
    # body can be split into stable per-frame PNGs without duplicated arms.
    if action == "shoot":
        recoil = math.sin(progress * math.pi)
        draw.ellipse((hand[0] - 7, hand[1] - 7, hand[0] + 7, hand[1] + 7), outline=(46, 231, 240, 130 + int(recoil * 70)), width=2)
        draw.line((hand[0] - active_side * 5, hand[1] + 8, hand[0] + active_side * 5, hand[1] + 8), fill=(238, 166, 70, 160), width=2)
    elif action == "draw_sword":
        radius = 5 + progress * 4
        draw.ellipse((hand[0] - radius, hand[1] - radius, hand[0] + radius, hand[1] + radius), outline=(50, 228, 240, 190), width=2)
        draw.line((cx + active_side * 10, cy + 4, hand[0], hand[1]), fill=(42, 229, 238, 95), width=2)
    elif action == "slash":
        pulse = math.sin(progress * math.pi)
        draw.ellipse((hand[0] - 6, hand[1] - 6, hand[0] + 6, hand[1] + 6), outline=(255, 182, 54, 120 + int(pulse * 80)), width=2)
        draw.line((cx + active_side * 10, cy + 8, hand[0], hand[1]), fill=(255, 182, 54, 95), width=2)
    elif action == "swap_tool":
        pulse = 12 + progress * 30
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


def save_player_split_frame(action: str, direction: int, frame: int, image: Image.Image) -> None:
    out = PLAYER_FRAME_DIR / action / f"dir_{direction}" / f"frame_{frame}.png"
    ensure(out)
    image.save(out)


def save_player_action_sheet(action: str, frames: dict[tuple[int, int], Image.Image]) -> None:
    sheet = Image.new("RGBA", (FRAME_W * FRAMES_PER_ACTION, FRAME_H * DIRECTIONS), (0, 0, 0, 0))
    for direction in range(DIRECTIONS):
        for frame in range(FRAMES_PER_ACTION):
            sheet.alpha_composite(frames[(direction, frame)], (frame * FRAME_W, direction * FRAME_H))
    out = PLAYER_ACTION_DIR / f"{action}.png"
    ensure(out)
    sheet.save(out)


def build_player_atlas() -> None:
    ref = load_reference()
    base_sprites = {idx: crop_foreground(ref, box) for idx, box in SOURCE_BOXES.items()}
    sheet = Image.new("RGBA", (FRAME_W * FRAMES_PER_ACTION * len(ACTIONS), FRAME_H * DIRECTIONS), (0, 0, 0, 0))
    for action_index, action in enumerate(ACTIONS):
        generated_frames: dict[tuple[int, int], Image.Image] = {}
        for direction in SOURCE_BOXES.keys():
            for frame in range(FRAMES_PER_ACTION):
                generated_frames[(direction, frame)] = fit_to_frame(base_sprites[direction], action, direction, frame)
        for target, source in MIRROR_FROM.items():
            for frame in range(FRAMES_PER_ACTION):
                generated_frames[(target, frame)] = ImageOps.mirror(generated_frames[(source, frame)])
        for direction in range(DIRECTIONS):
            for frame in range(FRAMES_PER_ACTION):
                frame_image = generated_frames[(direction, frame)]
                save_player_split_frame(action, direction, frame, frame_image)
                sheet.alpha_composite(frame_image, ((action_index * FRAMES_PER_ACTION + frame) * FRAME_W, direction * FRAME_H))
        save_player_action_sheet(action, generated_frames)
    out = SPRITES / "player" / "recycler_player_multiaction_8dir.png"
    ensure(out)
    sheet.save(out)


def build_player_split_diagnostic() -> None:
    labels = [
        ("idle", 0, 0),
        ("idle", 4, 0),
        ("walk", 0, 2),
        ("walk", 4, 6),
        ("shoot", 0, 4),
        ("shoot", 4, 4),
        ("slash", 0, 5),
        ("slash", 4, 5),
        ("hit", 2, 3),
        ("dead", 2, 6),
    ]
    scale = 2
    tile_w = FRAME_W * scale
    tile_h = FRAME_H * scale + 28
    preview = Image.new("RGBA", (tile_w * len(labels), tile_h), (16, 18, 20, 255))
    draw = ImageDraw.Draw(preview, "RGBA")
    for index, (action, direction, frame) in enumerate(labels):
        path = PLAYER_FRAME_DIR / action / f"dir_{direction}" / f"frame_{frame}.png"
        image = Image.open(path).convert("RGBA").resize((FRAME_W * scale, FRAME_H * scale), Image.Resampling.NEAREST)
        x = index * tile_w
        preview.alpha_composite(image, (x, 0))
        draw.text((x + 8, FRAME_H * scale + 5), f"{action} d{direction} f{frame}", fill=(230, 230, 220, 255))
    out = DOCS / "player_split_frame_diagnostic.png"
    ensure(out)
    preview.save(out)


def write_player_cleanup_audit() -> None:
    active_roots = [
        PLAYER_FRAME_DIR.relative_to(ROOT),
        PLAYER_ACTION_DIR.relative_to(ROOT),
        PLAYER_WEAPON_DIR.relative_to(ROOT),
        Path("assets/sprites/player/recycler_player_multiaction_8dir.png"),
        Path("data/art/player_animation_manifest.json"),
    ]
    legacy_candidates = [
        Path("assets/sprites/player/recycler_player_sprite_sheet.svg"),
        Path("assets/sprites/player/recycler_player_sprite_sheet.svg.import"),
        Path("assets/sprites/player/recycler_player_sprite_sheet.png"),
        Path("assets/sprites/player/recycler_player_sprite_sheet.png.import"),
        Path("assets/sprites/player/recycler_player_multiaction_8dir.svg"),
    ]
    lines = [
        "# Player Asset Cleanup Audit",
        "",
        "本輪依專案規則沒有批量刪除任何檔案。正式玩家資產已改成分離式 PNG：身體逐格、動作 sheet、武器 overlay 各自管理。",
        "",
        "## 目前正式使用",
    ]
    for path in active_roots:
        lines.append(f"- `{path.as_posix()}`")
    lines.extend([
        "",
        "## 建議人工確認後單檔刪除的舊候選",
        "",
        "下列檔案若未被 Godot import 或 README 文件引用，可由使用者人工逐一刪除；AI 不會使用批量刪除命令。",
    ])
    for path in legacy_candidates:
        status = "存在" if (ROOT / path).exists() else "不存在"
        lines.append(f"- `{path.as_posix()}`：{status}")
    lines.extend([
        "",
        "## 驗證規則",
        "",
        "- 玩家身體幀不應包含刀、槍、槍口火光或大型揮砍弧光。",
        "- 走路與待機幀必須保留左右手，不可因裁切消失。",
        "- 武器圖只從 `assets/sprites/player/weapons/` 讀取，避免重複手臂與重複武器。",
    ])
    ensure(PLAYER_CLEANUP_AUDIT)
    PLAYER_CLEANUP_AUDIT.write_text("\n".join(lines) + "\n", encoding="utf-8")


def icon_canvas() -> tuple[Image.Image, ImageDraw.ImageDraw]:
    img = Image.new("RGBA", (88, 72), (0, 0, 0, 0))
    d = ImageDraw.Draw(img, "RGBA")
    d.ellipse((12, 54, 76, 68), fill=(0, 0, 0, 88))
    return img, d


def fit_reference_asset(ref: Image.Image, box: tuple[int, int, int, int], canvas_size: tuple[int, int], fill: float = 0.82) -> Image.Image:
    subject = crop_foreground(ref, box)
    bbox = subject.getbbox()
    out = Image.new("RGBA", canvas_size, (0, 0, 0, 0))
    d = ImageDraw.Draw(out, "RGBA")
    d.ellipse((canvas_size[0] * 0.12, canvas_size[1] * 0.78, canvas_size[0] * 0.88, canvas_size[1] * 0.95), fill=(0, 0, 0, 88))
    if bbox is None:
        return out
    subject = subject.crop(bbox)
    scale = min(canvas_size[0] * fill / max(1, subject.width), canvas_size[1] * fill / max(1, subject.height))
    resized = subject.resize((max(1, int(subject.width * scale)), max(1, int(subject.height * scale))), Image.Resampling.LANCZOS)
    x = (canvas_size[0] - resized.width) // 2
    y = int(canvas_size[1] * 0.50 - resized.height * 0.52)
    y = max(0, min(canvas_size[1] - resized.height, y))
    out.alpha_composite(resized, (x, y))
    return out


def save_reference_icon(ref: Image.Image, name: str, box: tuple[int, int, int, int]) -> None:
    out = SPRITES / "items" / f"{name}.png"
    ensure(out)
    fit_reference_asset(ref, box, (88, 72), 0.88).save(out)


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
        d.polygon([(17, 56), (57, 18), (72, 11), (65, 27), (26, 58)], fill=(31, 28, 24, 255))
        d.polygon([(23, 51), (59, 18), (69, 14), (62, 25), (31, 53)], fill=(224, 220, 196, 255))
        d.polygon([(28, 48), (57, 22), (64, 18), (55, 31), (35, 49)], fill=accent + (235,))
        d.line((32, 50, 60, 21), fill=(255, 245, 198, 170), width=2)
        d.rounded_rectangle((12, 47, 31, 60), radius=4, fill=rust + (255,), outline=(22, 18, 15, 255), width=2)
        for bolt in [(18, 52), (26, 55)]:
            d.ellipse((bolt[0] - 2, bolt[1] - 2, bolt[0] + 2, bolt[1] + 2), fill=gold + (255,))
    elif kind == "hammer":
        d.line((20, 56, 54, 29), fill=(34, 28, 22, 255), width=10)
        d.line((22, 54, 55, 29), fill=rust + (255,), width=6)
        d.rounded_rectangle((47, 13, 80, 34), radius=5, fill=(122, 126, 116, 255), outline=(23, 23, 22, 255), width=3)
        d.rectangle((54, 16, 74, 31), fill=accent + (170,))
        for x in [51, 61, 75]:
            d.ellipse((x - 2, 20, x + 2, 24), fill=gold + (255,))
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
    ref = load_reference()
    specs = {
        "scrap_bundle": ("resource", (176, 99, 48)),
        "ammo_crate": ("resource", (92, 118, 65)),
        "mutant_core": ("resource", (214, 52, 58)),
        "bio_crystal": ("resource", (180, 88, 236)),
        "rust_blade": ("blade", (198, 112, 52)),
        "spark_cutter": ("blade", (55, 224, 238)),
        "breaker_hammer": ("hammer", (210, 168, 84)),
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
        source_box = WEAPON_MODULE_BOXES.get(name, RESOURCE_MODULE_BOXES.get(name))
        if source_box is not None:
            save_reference_icon(ref, name, source_box)
        else:
            save_icon(name, kind, accent)
    atlas = Image.new("RGBA", (88 * 4, 72), (0, 0, 0, 0))
    for i, name in enumerate(["scrap_bundle", "ammo_crate", "mutant_core", "bio_crystal"]):
        atlas.alpha_composite(Image.open(SPRITES / "items" / f"{name}.png").convert("RGBA"), (i * 88, 0))
    atlas.save(SPRITES / "items" / "recycler_item_icons.png")


def build_weapon_overlays() -> None:
    ref = load_reference()
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
    out_dir = PLAYER_WEAPON_DIR
    out_dir.mkdir(parents=True, exist_ok=True)
    for name, (kind, accent) in specs.items():
        source_box = WEAPON_MODULE_BOXES.get(name)
        if source_box is not None:
            weapon = fit_reference_asset(ref, source_box, (128, 80), 0.76)
            d = ImageDraw.Draw(weapon, "RGBA")
            d.ellipse((18, 62, 110, 77), fill=(0, 0, 0, 52))
            d.rounded_rectangle((10, 9, 118, 70), radius=8, outline=(54, 234, 244, 28), width=1)
            weapon.save(out_dir / f"{name}_overlay.png")
            continue
        img = Image.new("RGBA", (128, 80), (0, 0, 0, 0))
        d = ImageDraw.Draw(img, "RGBA")
        d.ellipse((18, 62, 110, 77), fill=(0, 0, 0, 66))
        if kind == "blade":
            d.polygon([(14, 59), (82, 15), (111, 8), (93, 35), (33, 65)], fill=(18, 15, 13, 255))
            d.polygon([(23, 53), (81, 18), (104, 12), (88, 30), (38, 57)], fill=(224, 221, 199, 255))
            d.polygon([(31, 50), (78, 22), (95, 17), (80, 32), (44, 51)], fill=accent + (225,))
            d.line((38, 51, 88, 19), fill=(255, 244, 201, 190), width=2)
            d.line((70, 29, 92, 21), fill=(45, 230, 240, 180), width=2)
            d.rounded_rectangle((10, 49, 39, 68), radius=5, fill=(159, 83, 38, 255), outline=(22, 18, 14, 255), width=3)
            d.rectangle((30, 45, 44, 54), fill=(44, 35, 25, 255), outline=(19, 16, 12, 255))
            for bolt in [(18, 55), (31, 62), (35, 50)]:
                d.ellipse((bolt[0] - 2, bolt[1] - 2, bolt[0] + 2, bolt[1] + 2), fill=(224, 170, 73, 255))
        elif kind == "hammer":
            d.line((19, 66, 74, 28), fill=(21, 17, 13, 255), width=15)
            d.line((23, 63, 76, 28), fill=(172, 88, 42, 255), width=9)
            d.rounded_rectangle((66, 12, 118, 40), radius=6, fill=(119, 124, 112, 255), outline=(22, 22, 20, 255), width=3)
            d.rectangle((78, 17, 108, 35), fill=accent + (176,))
            d.line((71, 17, 114, 37), fill=(230, 220, 185, 150), width=2)
            d.rectangle((62, 19, 71, 36), fill=(88, 74, 52, 255), outline=(22, 18, 14, 255))
            for bolt in [(73, 20), (90, 25), (110, 33)]:
                d.ellipse((bolt[0] - 2, bolt[1] - 2, bolt[0] + 2, bolt[1] + 2), fill=(226, 174, 78, 245))
        elif kind == "rifle":
            d.rounded_rectangle((18, 36, 92, 51), radius=5, fill=(29, 27, 24, 255), outline=(12, 11, 10, 255), width=3)
            d.rectangle((40, 25, 84, 37), fill=accent + (245,), outline=(18, 20, 18, 255))
            d.rectangle((88, 40, 120, 44), fill=(232, 176, 72, 255), outline=(34, 24, 13, 255))
            d.line((29, 52, 45, 69), fill=(171, 94, 48, 255), width=6)
            d.ellipse((53, 31, 63, 41), fill=(45, 230, 240, 220), outline=(11, 31, 34, 255), width=2)
        else:
            d.rounded_rectangle((46, 24, 84, 55), radius=9, fill=accent + (235,), outline=(24, 22, 18, 255), width=3)
            d.ellipse((55, 13, 75, 34), fill=(56, 226, 236, 170), outline=(15, 44, 47, 220), width=2)
            d.line((28, 62, 101, 24), fill=(175, 96, 47, 230), width=5)
            for x in [50, 64, 78]:
                d.line((x, 28, x + 8, 52), fill=(235, 230, 202, 70), width=2)
        img.save(out_dir / f"{name}_overlay.png")


def write_manifest() -> None:
    manifest = {
        "frame_size": [FRAME_W, FRAME_H],
        "directions": DIRECTIONS,
        "frames_per_action": FRAMES_PER_ACTION,
        "atlas_path": "res://assets/sprites/player/recycler_player_multiaction_8dir.png",
        "split_frame_dir": "res://assets/sprites/player/frames",
        "action_sheet_dir": "res://assets/sprites/player/actions",
        "reference_path": "res://docs/art_direction_reference_r17_full_body.png",
        "direction_order": ["right", "down_right", "down", "down_left", "left", "up_left", "up", "up_right"],
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


def synth_music(path: Path, seconds: float, roots: list[float], mood: str) -> None:
    ensure(path)
    sample_rate = 22050
    total = int(sample_rate * seconds)
    bpm = 82.0 if mood in {"intro", "village"} else 96.0
    beat = 60.0 / bpm
    with wave.open(str(path), "w") as out:
        out.setnchannels(1)
        out.setsampwidth(2)
        out.setframerate(sample_rate)
        frames = bytearray()
        for i in range(total):
            t = i / sample_rate
            section = int(t / (beat * 8.0)) % len(roots)
            root = roots[section]
            step = int(t / (beat * 0.5))
            phase = (t % (beat * 0.5)) / (beat * 0.5)
            fade_in = min(1.0, t / 3.0)
            fade_out = min(1.0, max(0.0, (seconds - t) / 3.0))
            env = fade_in * fade_out

            chord = (
                math.sin(t * root * 2 * math.pi) * 0.23
                + math.sin(t * root * 1.5 * 2 * math.pi) * 0.16
                + math.sin(t * root * 2.0 * 2 * math.pi) * 0.11
            )
            bass = math.sin(t * root * 0.5 * 2 * math.pi) * 0.20
            arp_notes = [1.0, 1.25, 1.5, 2.0, 1.5, 1.25, 1.0, 0.75]
            lead_freq = root * arp_notes[step % len(arp_notes)]
            pluck_env = max(0.0, 1.0 - phase) ** 2
            lead = math.sin(t * lead_freq * 2 * math.pi) * 0.16 * pluck_env
            lead += math.sin(t * lead_freq * 2.01 * math.pi) * 0.05 * pluck_env

            wind = (
                math.sin(t * 0.37 * 2 * math.pi)
                + math.sin(t * 0.19 * 2 * math.pi + 1.7)
                + math.sin(t * 7.1 * 2 * math.pi) * 0.08
            ) * 0.045
            percussion = 0.0
            if mood in {"wasteland", "guild"}:
                hit_phase = t % (beat * 2.0)
                if hit_phase < 0.045:
                    percussion = (1.0 - hit_phase / 0.045) * math.sin(t * 78.0 * 2 * math.pi) * 0.22
            if mood == "intro":
                lead *= 0.58
                wind *= 1.45
            elif mood == "village":
                chord *= 1.15
                wind *= 0.55
            elif mood == "wasteland":
                bass *= 1.25
                wind *= 2.1
                lead *= 0.75

            sample_value = (chord + bass + lead + wind + percussion) * env * 0.62
            sample = int(max(-1.0, min(1.0, sample_value)) * 32767)
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
    synth_music(audio / "music_intro.wav", 56.0, [146.8, 174.6, 130.8, 196.0, 220.0], "intro")
    synth_music(audio / "music_village.wav", 32.0, [196.0, 246.9, 220.0, 174.6], "village")
    synth_music(audio / "music_guild.wav", 30.0, [164.8, 196.0, 220.0, 246.9], "guild")
    synth_music(audio / "music_wasteland.wav", 34.0, [110.0, 130.8, 98.0, 146.8], "wasteland")


def main() -> None:
    build_player_atlas()
    build_player_split_diagnostic()
    build_item_icons()
    build_weapon_overlays()
    build_audio()
    write_manifest()
    write_player_cleanup_audit()
    print("Built release-candidate R-17 assets, item icons, audio, and animation manifest")


if __name__ == "__main__":
    main()
