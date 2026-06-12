from __future__ import annotations

from pathlib import Path
from random import Random

from PIL import Image, ImageDraw, ImageEnhance, ImageOps


ROOT = Path(__file__).resolve().parents[2]
SPRITES = ROOT / "assets" / "sprites"
FRAME_W, FRAME_H = 48, 56
ACTIONS = ["idle", "walk", "shoot", "draw_sword", "slash", "swap_tool", "interact", "hit", "dead"]
DIRECTIONS = 8


def ensure(path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)


def rgba(color: tuple[int, int, int], alpha: int = 255) -> tuple[int, int, int, int]:
    return color[0], color[1], color[2], alpha


def direction_vector(direction: int) -> tuple[float, float]:
    import math

    angle = math.radians(direction * 45.0)
    return math.cos(angle), math.sin(angle)


def draw_robot_frame(action: str, direction: int, frame: int) -> Image.Image:
    img = Image.new("RGBA", (FRAME_W, FRAME_H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img, "RGBA")
    dx, dy = direction_vector(direction)
    front = direction in [0, 1, 2, 3, 4]
    side = direction in [0, 4]
    mirrored = direction in [3, 4, 5]
    walk = [-1, 0, 1][frame] if action == "walk" else 0
    bob = abs(walk) if action == "walk" else 0
    if action == "hit":
        walk += -2 if frame == 1 else 1
    cx, cy = 24 + walk, 29 + bob

    d.ellipse((8, 48, 40, 55), fill=(0, 0, 0, 86))
    if action == "dead":
        d.ellipse((8, 42, 40, 53), fill=(0, 0, 0, 110))
        d.rounded_rectangle((11, 35, 38, 47), radius=5, fill=(171, 178, 164, 245), outline=(38, 43, 39, 255), width=2)
        d.ellipse((17, 38, 23, 44), fill=(35, 220, 232, 210))
        d.line((31, 35, 40, 28), fill=(201, 118, 54, 220), width=3)
        d.line((15, 46, 8, 51), fill=(88, 92, 86, 230), width=3)
        return img

    # Legs and arms are long and rounded, giving R-17 an original wilderness android silhouette.
    leg_offset = 3 if frame == 1 and action == "walk" else 0
    d.line((cx - 7, cy + 14, cx - 10 - leg_offset, cy + 23), fill=(132, 139, 130, 245), width=5)
    d.line((cx + 7, cy + 14, cx + 10 + leg_offset, cy + 23), fill=(132, 139, 130, 245), width=5)
    d.ellipse((cx - 15 - leg_offset, cy + 21, cx - 6 - leg_offset, cy + 27), fill=(50, 54, 51, 245))
    d.ellipse((cx + 6 + leg_offset, cy + 21, cx + 15 + leg_offset, cy + 27), fill=(50, 54, 51, 245))

    body_fill = (177, 182, 166) if action != "hit" else (225, 150, 130)
    body_shadow = (92, 98, 91)
    d.ellipse((cx - 14, cy - 8, cx + 14, cy + 19), fill=rgba(body_shadow, 245), outline=(34, 38, 35, 255), width=2)
    d.ellipse((cx - 12, cy - 10, cx + 12, cy + 15), fill=rgba(body_fill, 255))
    d.arc((cx - 11, cy - 8, cx + 12, cy + 16), 200, 330, fill=(226, 229, 209, 220), width=2)
    d.rectangle((cx - 5, cy + 2, cx + 5, cy + 11), fill=(44, 170, 184, 190), outline=(25, 67, 70, 230))

    arm_swing = 3 if action == "walk" and frame != 1 else 0
    left_arm = (cx - 14, cy - 1, cx - 20 - arm_swing, cy + 15)
    right_arm = (cx + 14, cy - 1, cx + 20 + arm_swing, cy + 15)
    if action in ["shoot", "draw_sword", "slash", "interact"]:
        reach = 13 + frame * 3
        right_arm = (cx + dx * 9, cy + dy * 3, cx + dx * reach, cy + dy * (reach * 0.62))
        left_arm = (cx - dx * 5, cy - dy * 2, cx - dx * 11, cy - dy * 4)
    if mirrored:
        left_arm, right_arm = right_arm, left_arm
    d.line(left_arm, fill=(123, 128, 119, 245), width=5)
    d.line(right_arm, fill=(123, 128, 119, 245), width=5)
    for px, py in [(left_arm[2], left_arm[3]), (right_arm[2], right_arm[3])]:
        d.ellipse((px - 4, py - 4, px + 4, py + 4), fill=(42, 219, 226, 220), outline=(22, 60, 63, 245))

    neck_y = cy - 13
    d.line((cx, neck_y + 4, cx, neck_y + 11), fill=(88, 93, 87, 245), width=4)
    if front:
        d.ellipse((cx - 10, neck_y - 11, cx + 10, neck_y + 7), fill=(185, 190, 176, 255), outline=(42, 47, 43, 255), width=2)
        d.arc((cx - 8, neck_y - 9, cx + 9, neck_y + 6), 190, 320, fill=(238, 240, 222, 230), width=2)
        d.ellipse((cx - 7, neck_y - 3, cx - 2, neck_y + 3), fill=(35, 226, 236, 240))
        d.ellipse((cx + 2, neck_y - 3, cx + 7, neck_y + 3), fill=(35, 226, 236, 240))
        d.point((cx - 5, neck_y - 1), fill=(240, 255, 255, 255))
        d.point((cx + 4, neck_y - 1), fill=(240, 255, 255, 255))
    else:
        d.ellipse((cx - 10, neck_y - 10, cx + 10, neck_y + 7), fill=(151, 158, 147, 255), outline=(38, 43, 39, 255), width=2)
        d.arc((cx - 7, neck_y - 7, cx + 7, neck_y + 5), 20, 160, fill=(219, 224, 207, 210), width=2)
        d.line((cx - 5, neck_y + 2, cx + 5, neck_y + 2), fill=(36, 210, 226, 130), width=1)
    d.line((cx - 2, neck_y - 11, cx - 2, neck_y - 17), fill=(71, 77, 72, 230), width=2)
    d.point((cx - 2, neck_y - 18), fill=(37, 225, 238, 220))

    # Tools and weapon feedback.
    weapon_start = (cx + dx * 8, cy + dy * 3)
    weapon_end = (cx + dx * (19 + frame * 3), cy + dy * (12 + frame))
    if action == "shoot":
        d.line([weapon_start, weapon_end], fill=(42, 38, 34, 255), width=5)
        d.line([weapon_start, weapon_end], fill=(168, 123, 68, 255), width=2)
        if frame >= 1:
            mx, my = weapon_end
            d.ellipse((mx - 4, my - 4, mx + 4, my + 4), fill=(255, 210, 72, 245))
            d.line((mx, my, mx + dx * 10, my + dy * 10), fill=(54, 230, 243, 220), width=2)
    elif action == "draw_sword":
        d.line((cx - 10, cy + 8, weapon_end[0], weapon_end[1]), fill=(230, 233, 210, 245), width=2)
        d.line((cx - 11, cy + 10, cx - 3, cy + 3), fill=(204, 124, 55, 230), width=2)
    elif action == "slash":
        radius = 14 + frame * 5
        center = (cx + dx * (7 + frame * 2), cy + dy * (4 + frame * 2))
        bbox = (center[0] - radius, center[1] - radius, center[0] + radius, center[1] + radius)
        d.arc(bbox, direction * 45 - 70, direction * 45 + 70, fill=(255, 190, 68, 250), width=4)
        d.arc((bbox[0] + 5, bbox[1] + 5, bbox[2] - 5, bbox[3] - 5), direction * 45 - 50, direction * 45 + 50, fill=(41, 230, 240, 210), width=2)
        d.line((cx, cy + 2, weapon_end[0], weapon_end[1]), fill=(238, 240, 218, 245), width=2)
    elif action == "swap_tool":
        pulse = 5 + frame * 2
        d.ellipse((cx - pulse, cy - pulse, cx + pulse, cy + pulse), outline=(42, 225, 235, 210), width=2)
        d.rectangle((cx + 12, cy - 2, cx + 20, cy + 8), fill=(199, 116, 55, 230), outline=(40, 32, 26, 240))
    elif action == "interact":
        for i in range(3):
            px = cx + dx * (10 + i * 5)
            py = cy + dy * (5 + i * 4)
            d.ellipse((px - 2, py - 2, px + 2, py + 2), fill=(82, 235, 160, 220))

    # Dust and damage scratches.
    d.line((cx - 9, cy - 3, cx - 4, cy - 1), fill=(121, 96, 58, 160), width=1)
    d.line((cx + 5, cy + 7, cx + 10, cy + 4), fill=(120, 90, 55, 150), width=1)
    return img


def build_player_atlas() -> None:
    sheet = Image.new("RGBA", (FRAME_W * 3 * len(ACTIONS), FRAME_H * DIRECTIONS), (0, 0, 0, 0))
    for action_i, action in enumerate(ACTIONS):
        for direction in range(DIRECTIONS):
            for frame in range(3):
                sheet.alpha_composite(draw_robot_frame(action, direction, frame), ((action_i * 3 + frame) * FRAME_W, direction * FRAME_H))
    out = SPRITES / "player" / "recycler_player_multiaction_8dir.png"
    ensure(out)
    sheet.save(out)


def draw_icon(kind: str, seed: int) -> Image.Image:
    rng = Random(seed)
    img = Image.new("RGBA", (80, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(img, "RGBA")
    d.ellipse((16, 48, 64, 59), fill=(0, 0, 0, 80))
    rust = (167, 93, 45)
    steel = (112, 119, 113)
    cyan = (43, 221, 232)
    green = (116, 212, 72)
    purple = (177, 84, 235)
    red = (211, 52, 58)
    gold = (227, 176, 72)
    if kind == "scrap":
        for i in range(5):
            x = 14 + i * 8 + rng.randint(-2, 2)
            d.rounded_rectangle((x, 22 - i % 2 * 3, x + 22, 31 + i % 2 * 4), radius=2, fill=rgba((82, 76, 66), 245), outline=rgba((30, 27, 23), 255), width=1)
        d.line((12, 39, 54, 18), fill=rgba(gold, 230), width=3)
    elif kind == "ammo":
        d.rounded_rectangle((16, 17, 50, 42), radius=3, fill=rgba((69, 90, 57), 255), outline=rgba((28, 33, 26), 255), width=2)
        d.rectangle((22, 15, 41, 19), fill=rgba(gold, 230))
        for x in [54, 60, 66]:
            d.rounded_rectangle((x, 24, x + 5, 45), radius=2, fill=rgba(gold, 255), outline=rgba((72, 45, 22), 255))
    elif kind == "mutant_core":
        d.ellipse((22, 12, 58, 48), fill=rgba((66, 15, 22), 255), outline=rgba((23, 9, 10), 255), width=2)
        d.ellipse((30, 18, 52, 41), fill=rgba(red, 255))
        for end in [(18, 8), (64, 20), (18, 48), (59, 52)]:
            d.line((40, 30, end[0], end[1]), fill=rgba((96, 196, 80), 180), width=2)
    elif kind == "bio_crystal":
        points = [(40, 8), (24, 40), (40, 55), (56, 40)]
        d.polygon(points, fill=rgba(purple, 245), outline=rgba((42, 24, 62), 255))
        d.polygon([(40, 8), (32, 38), (40, 55)], fill=rgba((102, 235, 190), 205))
        d.line((42, 13, 50, 40), fill=(255, 230, 255, 170), width=2)
    elif kind in ["rust_blade", "spark_cutter"]:
        d.line((18, 45, 58, 14), fill=rgba((230, 232, 211), 255), width=5)
        d.line((19, 46, 41, 30), fill=rgba(cyan if kind == "spark_cutter" else rust, 230), width=3)
        d.rectangle((15, 42, 28, 49), fill=rgba((62, 42, 30), 255))
        if kind == "spark_cutter":
            d.arc((20, 8, 67, 55), 280, 40, fill=rgba((255, 190, 70), 230), width=3)
    elif kind == "breaker_hammer":
        d.rounded_rectangle((36, 12, 64, 30), radius=3, fill=rgba(steel, 255), outline=rgba((29, 31, 30), 255), width=2)
        d.line((20, 47, 47, 24), fill=rgba(rust, 255), width=6)
        d.line((18, 49, 26, 41), fill=rgba(gold, 220), width=2)
    elif kind in ["pipe_rifle", "coil_launcher", "acid_sprayer"]:
        body = cyan if kind == "coil_launcher" else ((108, 180, 70) if kind == "acid_sprayer" else rust)
        d.rounded_rectangle((16, 27, 58, 37), radius=3, fill=rgba((45, 39, 34), 255), outline=rgba((19, 18, 16), 255), width=2)
        d.rectangle((30, 21, 54, 28), fill=rgba(body, 245))
        d.rectangle((56, 29, 70, 33), fill=rgba(gold, 245))
        if kind == "coil_launcher":
            d.arc((21, 17, 50, 45), 0, 360, fill=rgba(cyan, 220), width=2)
        if kind == "acid_sprayer":
            d.ellipse((65, 27, 72, 35), fill=rgba(green, 220))
    elif kind in ["patched_armor", "crystal_guard", "industrial_exoshell"]:
        color = (88, 95, 88) if kind == "patched_armor" else (118, 70, 154) if kind == "crystal_guard" else (98, 83, 64)
        d.rounded_rectangle((24, 12, 56, 48), radius=6, fill=rgba(color, 255), outline=rgba((20, 22, 20), 255), width=2)
        d.rectangle((31, 20, 49, 34), fill=rgba(cyan if kind != "crystal_guard" else purple, 180))
        if kind == "industrial_exoshell":
            d.line((20, 18, 12, 42), fill=rgba(steel, 230), width=4)
            d.line((60, 18, 68, 42), fill=rgba(steel, 230), width=4)
    else:
        d.rounded_rectangle((18, 22, 60, 44), radius=5, fill=rgba((93, 78, 54), 255), outline=rgba((25, 22, 18), 255), width=2)
        d.ellipse((28, 14, 52, 38), fill=rgba(cyan if kind == "magnet_breaker" else green, 190))
        d.line((20, 47, 61, 17), fill=rgba(rust, 220), width=3)
    for _ in range(18):
        x = rng.randint(10, 68)
        y = rng.randint(10, 52)
        if img.getpixel((x, y))[3] > 0:
            r, g, b, a = img.getpixel((x, y))
            img.putpixel((x, y), (min(255, r + 35), min(255, g + 35), min(255, b + 35), a))
    return img


def build_items() -> None:
    ids = [
        "scrap", "ammo", "mutant_core", "bio_crystal",
        "rust_blade", "spark_cutter", "breaker_hammer", "pipe_rifle", "coil_launcher", "acid_sprayer",
        "patched_armor", "crystal_guard", "industrial_exoshell", "recycler_glove", "magnet_breaker",
    ]
    for i, kind in enumerate(ids):
        out = SPRITES / "items" / f"{kind if kind not in ['scrap', 'ammo', 'mutant_core', 'bio_crystal'] else {'scrap':'scrap_bundle','ammo':'ammo_crate','mutant_core':'mutant_core','bio_crystal':'bio_crystal'}[kind]}.png"
        ensure(out)
        draw_icon(kind, 2000 + i * 37).save(out)
    atlas = Image.new("RGBA", (80 * 4, 64), (0, 0, 0, 0))
    for i, kind in enumerate(["scrap", "ammo", "mutant_core", "bio_crystal"]):
        atlas.alpha_composite(draw_icon(kind, 3000 + i), (i * 80, 0))
    atlas.save(SPRITES / "items" / "recycler_item_icons.png")


def build_enemy_standups() -> None:
    atlas_path = SPRITES / "enemies" / "polluted_enemy_six_types.png"
    if not atlas_path.exists():
        return
    atlas = Image.open(atlas_path).convert("RGBA")
    enemy_ids = [
        "scrap_biter",
        "toxic_runner",
        "spore_gunner",
        "rust_brute",
        "rot_wing",
        "mech_husk",
        "waste_titan",
    ]
    for index, enemy_id in enumerate(enemy_ids):
        frame = atlas.crop((index * 96, 0, index * 96 + 96, 72))
        out = SPRITES / "enemies" / f"{enemy_id}.png"
        ensure(out)
        frame.save(out)


def add_unique_badge(path: Path, color: tuple[int, int, int], seed: int) -> None:
    if not path.exists():
        return
    img = Image.open(path).convert("RGBA")
    d = ImageDraw.Draw(img, "RGBA")
    rng = Random(seed)
    x = max(4, img.width - 28)
    y = max(4, img.height - 28)
    d.rounded_rectangle((x, y, x + 18, y + 12), radius=2, fill=rgba(color, 170), outline=rgba((24, 20, 16), 220))
    for _ in range(24):
        px = rng.randint(0, img.width - 1)
        py = rng.randint(max(0, img.height // 2), img.height - 1)
        r, g, b, a = img.getpixel((px, py))
        if a > 16:
            img.putpixel((px, py), (min(255, r + color[0] // 7), min(255, g + color[1] // 9), min(255, b + color[2] // 9), a))
    img.save(path)


def build_unique_existing_assets() -> None:
    badges = {
        "forge.png": (240, 128, 45),
        "craft.png": (62, 222, 232),
        "shop.png": (232, 190, 78),
        "mod_station.png": (150, 92, 232),
        "recycle_machine.png": (104, 212, 86),
        "save_station.png": (76, 192, 232),
        "guild_gate.png": (83, 110, 220),
        "guild_contract_board.png": (190, 170, 82),
        "guild_reward_counter.png": (112, 220, 180),
        "wasteland_gate.png": (226, 116, 64),
        "village_return_gate.png": (102, 228, 116),
        "guild_wasteland_exit.png": (196, 90, 230),
    }
    for index, (name, color) in enumerate(badges.items()):
        add_unique_badge(SPRITES / "structures" / name, color, 4100 + index)
    npc_colors = {
        "forge_master": (238, 126, 48),
        "scrap_merchant": (230, 184, 72),
        "repair_robot": (50, 220, 232),
        "wasteland_survivor": (128, 204, 82),
        "guild_clerk": (166, 112, 232),
        "route_scout": (114, 166, 96),
    }
    for index, (name, color) in enumerate(npc_colors.items()):
        sprite = SPRITES / "npcs" / f"{name}.png"
        add_unique_badge(sprite, color, 5100 + index)
        if sprite.exists():
            img = Image.open(sprite).convert("RGBA")
            portrait = ImageOps.contain(img, (104, 128), Image.Resampling.NEAREST)
            canvas = Image.new("RGBA", (112, 132), (18, 20, 22, 210))
            draw = ImageDraw.Draw(canvas, "RGBA")
            draw.rounded_rectangle((2, 2, 109, 129), radius=6, outline=rgba(color, 190), width=2)
            canvas.alpha_composite(portrait, ((112 - portrait.width) // 2, 128 - portrait.height))
            canvas.save(SPRITES / "npcs" / f"{name}_portrait.png")


def build_prop_variants() -> None:
    variant_dir = SPRITES / "props" / "variants"
    variant_dir.mkdir(parents=True, exist_ok=True)
    prop_ids = ["rust_rock", "dead_tree", "scrap_wall", "toxic_pool", "wreck", "signal_pylon", "road_marker", "scrap_barricade"]
    for p_index, prop_id in enumerate(prop_ids):
        src_path = SPRITES / "props" / f"{prop_id}.png"
        if not src_path.exists():
            continue
        base = Image.open(src_path).convert("RGBA")
        for variant in range(8):
            rng = Random(7000 + p_index * 97 + variant)
            img = base.copy()
            if variant % 3 == 1:
                img = ImageEnhance.Color(img).enhance(1.08)
            elif variant % 3 == 2:
                img = ImageEnhance.Brightness(img).enhance(0.92)
            d = ImageDraw.Draw(img, "RGBA")
            tint = [(216, 119, 52), (103, 210, 72), (174, 84, 230), (68, 214, 225)][variant % 4]
            for _ in range(18):
                x = rng.randint(2, max(2, img.width - 3))
                y = rng.randint(max(2, img.height // 3), max(2, img.height - 3))
                if img.getpixel((x, y))[3] > 0:
                    d.ellipse((x - 1, y - 1, x + 1, y + 1), fill=rgba(tint, 95))
            if variant % 2 == 1:
                d.line((rng.randint(0, img.width // 2), rng.randint(img.height // 4, img.height - 2), rng.randint(img.width // 2, img.width - 1), rng.randint(img.height // 4, img.height - 2)), fill=(18, 14, 10, 130), width=1)
            img.save(variant_dir / f"{prop_id}_{variant}.png")


def main() -> None:
    build_player_atlas()
    build_items()
    build_enemy_standups()
    build_unique_existing_assets()
    build_prop_variants()
    print("Generated formal visual assets")


if __name__ == "__main__":
    main()
