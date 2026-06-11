from __future__ import annotations

import math
import random
import wave
from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[2]
SPRITES = ROOT / "assets" / "sprites"
AUDIO = ROOT / "assets" / "audio"


def px_rect(draw: ImageDraw.ImageDraw, xy, fill, outline=None) -> None:
    x0, y0, x1, y1 = (int(v) for v in xy)
    if x1 < x0:
        x0, x1 = x1, x0
    if y1 < y0:
        y0, y1 = y1, y0
    draw.rectangle((x0, y0, x1, y1), fill=fill, outline=outline)


def px_poly(draw: ImageDraw.ImageDraw, points, fill, outline=None) -> None:
    draw.polygon([(int(x), int(y)) for x, y in points], fill=fill, outline=outline)


def add_noise(img: Image.Image, amount: int, seed: int) -> None:
    rng = random.Random(seed)
    pix = img.load()
    for _ in range(amount):
        x = rng.randrange(img.width)
        y = rng.randrange(img.height)
        r, g, b, a = pix[x, y]
        if a == 0:
            continue
        shift = rng.choice([-18, -10, 12, 20])
        pix[x, y] = (
            max(0, min(255, r + shift)),
            max(0, min(255, g + shift)),
            max(0, min(255, b + shift)),
            a,
        )


def save_structure(path: Path, w: int, h: int, body, roof, accent, seed: int, variant: str) -> None:
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    shadow = (0, 0, 0, 95)
    px_rect(d, (18, h - 28, w - 18, h - 10), shadow)
    px_rect(d, (32, 54, w - 30, h - 24), body, (24, 27, 28, 255))
    px_poly(d, [(26, 58), (w // 2, 22), (w - 22, 58), (w - 34, 76), (38, 76)], roof, (18, 20, 22, 255))
    px_rect(d, (43, 75, w - 43, h - 36), tuple(max(0, c - 24) for c in body[:3]) + (255,), (17, 18, 20, 255))
    for x in range(48, w - 48, 26):
        px_rect(d, (x, 82, x + 12, h - 44), tuple(min(255, c + 18) for c in body[:3]) + (255,))
        px_rect(d, (x + 3, 86, x + 9, max(86, h - 48)), tuple(max(0, c - 35) for c in body[:3]) + (255,))
    px_rect(d, (w // 2 - 18, h - 58, w // 2 + 18, h - 28), (28, 30, 31, 255), (10, 11, 12, 255))
    px_rect(d, (w // 2 - 10, h - 50, w // 2 + 10, h - 30), accent, (235, 220, 150, 255))
    if variant == "forge":
        px_rect(d, (w - 54, 18, w - 34, 72), (52, 45, 39, 255), (16, 15, 14, 255))
        px_rect(d, (w // 2 - 30, h - 63, w // 2 + 30, h - 44), (210, 92, 34, 255))
        px_rect(d, (w // 2 - 18, h - 59, w // 2 + 18, h - 48), (255, 174, 57, 255))
    elif variant == "craft":
        for x in (42, w - 62):
            px_rect(d, (x, 36, x + 18, 54), accent, (11, 15, 18, 255))
        px_rect(d, (54, h - 54, w - 54, h - 42), (86, 109, 108, 255))
    elif variant == "shop":
        px_rect(d, (36, 42, w - 36, 63), (202, 143, 68, 255), (37, 28, 20, 255))
        for x in range(46, w - 46, 24):
            px_rect(d, (x, 45, x + 10, 60), (238, 184, 83, 255))
    elif variant == "mod":
        for i in range(4):
            x = 48 + i * 26
            px_rect(d, (x, 84, x + 12, h - 44), (45, 226, 238, 255))
            px_rect(d, (x + 4, 88, x + 8, h - 48), (16, 74, 91, 255))
    elif variant == "recycle":
        px_rect(d, (40, 92, w - 40, 118), (70, 142, 94, 255), (20, 40, 28, 255))
        for i in range(3):
            px_poly(d, [(70 + i * 22, 99), (80 + i * 22, 90), (91 + i * 22, 99), (80 + i * 22, 108)], accent)
    elif variant == "save":
        px_rect(d, (w // 2 - 36, 38, w // 2 + 36, 61), (62, 188, 216, 255), (18, 54, 66, 255))
        px_rect(d, (w // 2 - 6, 33, w // 2 + 6, 66), (216, 246, 251, 255))
        px_rect(d, (w // 2 - 24, 45, w // 2 + 24, 53), (216, 246, 251, 255))
    elif variant == "gate":
        px_rect(d, (30, 52, w - 30, h - 28), (46, 72, 53, 255), (11, 17, 13, 255))
        px_rect(d, (w // 2 - 8, 39, w // 2 + 8, h - 28), accent)
        for x in range(46, w - 38, 22):
            px_rect(d, (x, 58, x + 8, h - 31), (28, 37, 31, 255))
    elif variant == "guild":
        px_rect(d, (44, 32, w - 44, 66), (92, 66, 132, 255), (24, 20, 31, 255))
        px_rect(d, (w // 2 - 30, 26, w // 2 + 30, 46), accent, (240, 215, 115, 255))
    elif variant == "board":
        px_rect(d, (30, 40, w - 30, h - 22), (81, 61, 42, 255), (22, 16, 12, 255))
        for y in range(52, h - 34, 14):
            px_rect(d, (44, y, w - 44, y + 5), (190, 150, 92, 255))
        px_rect(d, (w - 62, 50, w - 42, 70), accent)
    elif variant == "counter":
        px_rect(d, (22, 72, w - 22, h - 26), (61, 83, 96, 255), (17, 23, 27, 255))
        px_rect(d, (42, 50, w - 42, 78), accent, (224, 206, 128, 255))
    add_noise(img, w * h // 9, seed)
    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(path)


def save_tile(path: Path, palette, seed: int, cracks: bool) -> None:
    rng = random.Random(seed)
    img = Image.new("RGBA", (32, 32), palette[0])
    d = ImageDraw.Draw(img)
    for y in range(0, 32, 8):
        for x in range(0, 32, 8):
            c = palette[(x // 8 + y // 8 + seed) % len(palette)]
            px_rect(d, (x, y, x + 7, y + 7), c)
            if rng.random() < 0.45:
                px_rect(d, (x, y, x + 7, y), tuple(max(0, v - 28) for v in c[:3]) + (255,))
    if cracks:
        for _ in range(5):
            x = rng.randrange(2, 30)
            y = rng.randrange(2, 30)
            for i in range(rng.randrange(4, 10)):
                if 0 <= x < 32 and 0 <= y < 32:
                    img.putpixel((x, y), (24, 22, 20, 255))
                x += rng.choice([-1, 0, 1])
                y += rng.choice([0, 1])
    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(path)


def save_prop(path: Path, w: int, h: int, kind: str, seed: int) -> None:
    rng = random.Random(seed)
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    if kind == "rust_rock":
        px_poly(d, [(12, h - 20), (28, 16), (w - 18, 24), (w - 8, h - 24), (w // 2, h - 6)], (92, 82, 69, 255), (31, 28, 24, 255))
        px_poly(d, [(30, 22), (w - 22, 28), (w - 40, h - 35)], (134, 111, 82, 255))
    elif kind == "dead_tree":
        px_rect(d, (w // 2 - 6, 28, w // 2 + 8, h - 5), (91, 63, 38, 255), (29, 21, 15, 255))
        for angle in [-0.9, -0.45, 0.45, 0.9]:
            x2 = w // 2 + int(math.cos(angle) * 34)
            y2 = 35 + int(math.sin(angle) * 18)
            d.line((w // 2, 44, x2, y2), fill=(91, 63, 38, 255), width=5)
            d.line((w // 2, 44, x2, y2), fill=(29, 21, 15, 255), width=1)
    elif kind == "scrap_wall":
        px_rect(d, (5, 18, w - 5, h - 8), (71, 77, 78, 255), (22, 24, 25, 255))
        for x in range(10, w - 15, 18):
            px_rect(d, (x, 22, x + 10, h - 14), rng.choice([(139, 76, 42, 255), (101, 111, 112, 255), (43, 49, 53, 255)]))
    elif kind == "toxic_pool":
        px_poly(d, [(9, h - 25), (25, 12), (w - 22, 17), (w - 8, h - 22), (w - 32, h - 6)], (70, 152, 76, 210), (23, 54, 30, 255))
        for _ in range(18):
            x, y = rng.randrange(12, w - 12), rng.randrange(20, h - 12)
            px_rect(d, (x, y, x + 3, y + 3), (167, 236, 91, 230))
    elif kind == "wreck":
        px_rect(d, (8, 22, w - 8, h - 12), (72, 78, 84, 255), (19, 22, 25, 255))
        px_rect(d, (24, 10, w - 24, 32), (112, 76, 50, 255), (31, 20, 15, 255))
        px_rect(d, (w - 34, 35, w - 16, 52), (205, 78, 55, 255))
    elif kind == "signal_pylon":
        px_rect(d, (w // 2 - 4, 8, w // 2 + 4, h - 6), (93, 111, 127, 255), (22, 27, 34, 255))
        px_rect(d, (w // 2 - 27, 24, w // 2 + 27, 34), (93, 111, 127, 255), (22, 27, 34, 255))
        px_rect(d, (w // 2 - 12, 3, w // 2 + 12, 16), (63, 218, 232, 255))
    else:
        px_rect(d, (12, 6, w - 12, h - 8), (177, 135, 62, 255), (42, 33, 18, 255))
    add_noise(img, w * h // 14, seed)
    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(path)


def save_npc(path: Path, palette, accent, seed: int, role: str) -> None:
    rng = random.Random(seed)
    w, h = 56, 72
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    dark, mid, light = palette
    px_rect(d, (10, h - 12, w - 10, h - 5), (0, 0, 0, 88))
    px_rect(d, (19, 50, 27, 65), dark, (12, 13, 14, 255))
    px_rect(d, (30, 50, 38, 65), dark, (12, 13, 14, 255))
    px_rect(d, (17, 27, 39, 54), mid, (13, 15, 16, 255))
    px_rect(d, (20, 31, 36, 45), light)
    px_rect(d, (18, 14, 38, 31), dark, (10, 11, 12, 255))
    px_rect(d, (21, 17, 35, 25), accent, (230, 220, 160, 255))
    px_rect(d, (13, 31, 18, 48), mid, (12, 13, 14, 255))
    px_rect(d, (38, 31, 43, 48), mid, (12, 13, 14, 255))
    if role == "forge":
        px_rect(d, (6, 36, 15, 44), (205, 96, 42, 255), (65, 30, 18, 255))
        px_rect(d, (39, 42, 49, 50), (143, 108, 70, 255), (37, 26, 18, 255))
    elif role == "merchant":
        px_rect(d, (7, 35, 18, 51), (104, 76, 48, 255), (31, 22, 15, 255))
        px_rect(d, (38, 34, 49, 49), (197, 146, 62, 255), (49, 34, 15, 255))
    elif role == "robot":
        px_rect(d, (8, 20, 17, 29), (73, 204, 221, 255), (16, 60, 70, 255))
        px_rect(d, (39, 20, 48, 29), (73, 204, 221, 255), (16, 60, 70, 255))
        px_rect(d, (21, 8, 35, 14), (94, 111, 124, 255))
    elif role == "survivor":
        px_rect(d, (8, 37, 19, 47), (88, 115, 78, 255), (24, 38, 24, 255))
        d.line((41, 28, 50, 18), fill=(135, 116, 67, 255), width=3)
    elif role == "clerk":
        px_rect(d, (10, 46, 46, 55), (77, 59, 112, 255), (26, 21, 36, 255))
        px_rect(d, (23, 8, 33, 13), (223, 188, 89, 255))
    elif role == "scout":
        d.line((40, 35, 50, 22), fill=(127, 110, 76, 255), width=3)
        px_rect(d, (7, 31, 16, 45), (70, 107, 77, 255), (20, 40, 24, 255))
    for _ in range(42):
        x = rng.randrange(14, 43)
        y = rng.randrange(12, 62)
        if img.getpixel((x, y))[3] > 0:
            r, g, b, a = img.getpixel((x, y))
            img.putpixel((x, y), (max(0, r - 18), max(0, g - 18), max(0, b - 18), a))
    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(path)


def synth(path: Path, notes, seconds_per_note: float, volume: float = 0.28, rate: int = 22050) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    frames = []
    for freq, wave_type in notes:
        total = int(seconds_per_note * rate)
        for i in range(total):
            t = i / rate
            env = min(1.0, i / (rate * 0.04)) * min(1.0, (total - i) / (rate * 0.08))
            if wave_type == "noise":
                sample = (random.random() * 2.0 - 1.0) * env
            else:
                s1 = math.sin(2 * math.pi * freq * t)
                s2 = math.sin(2 * math.pi * freq * 2.0 * t) * 0.25
                sample = (s1 + s2) * env
                if wave_type == "square":
                    sample = (1.0 if s1 >= 0 else -1.0) * env
            frames.append(int(max(-1.0, min(1.0, sample * volume)) * 32767))
    with wave.open(str(path), "wb") as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(rate)
        wav.writeframes(b"".join(int(v).to_bytes(2, "little", signed=True) for v in frames))


def main() -> None:
    structs = SPRITES / "structures"
    save_structure(structs / "forge.png", 192, 150, (91, 61, 43, 255), (70, 46, 35, 255), (255, 154, 57, 255), 11, "forge")
    save_structure(structs / "craft.png", 176, 140, (74, 94, 101, 255), (43, 55, 61, 255), (70, 210, 226, 255), 12, "craft")
    save_structure(structs / "shop.png", 184, 132, (94, 74, 48, 255), (68, 50, 34, 255), (239, 182, 79, 255), 13, "shop")
    save_structure(structs / "mod_station.png", 196, 146, (49, 73, 91, 255), (34, 47, 61, 255), (56, 224, 238, 255), 14, "mod")
    save_structure(structs / "recycle_machine.png", 184, 132, (61, 88, 72, 255), (39, 58, 49, 255), (140, 220, 98, 255), 15, "recycle")
    save_structure(structs / "save_station.png", 168, 132, (46, 94, 112, 255), (31, 58, 72, 255), (96, 223, 245, 255), 16, "save")
    save_structure(structs / "wasteland_gate.png", 184, 128, (54, 91, 61, 255), (36, 58, 42, 255), (146, 220, 98, 255), 17, "gate")
    save_structure(structs / "guild_gate.png", 190, 128, (83, 72, 122, 255), (51, 43, 83, 255), (221, 185, 92, 255), 18, "guild")
    save_structure(structs / "guild_contract_board.png", 200, 120, (82, 62, 43, 255), (54, 39, 28, 255), (205, 72, 62, 255), 19, "board")
    save_structure(structs / "guild_reward_counter.png", 200, 120, (61, 82, 98, 255), (39, 51, 65, 255), (74, 198, 222, 255), 20, "counter")
    save_structure(structs / "guild_wasteland_exit.png", 184, 128, (89, 85, 55, 255), (56, 53, 34, 255), (204, 173, 78, 255), 21, "gate")
    save_structure(structs / "village_return_gate.png", 184, 128, (59, 104, 66, 255), (37, 65, 42, 255), (133, 218, 117, 255), 22, "gate")

    tiles = SPRITES / "tiles"
    save_tile(tiles / "village_ground_2p5d.png", [(48, 43, 35, 255), (64, 55, 43, 255), (89, 77, 57, 255), (38, 36, 31, 255)], 30, False)
    save_tile(tiles / "guild_ground_2p5d.png", [(38, 34, 32, 255), (53, 47, 43, 255), (67, 58, 49, 255), (35, 32, 30, 255)], 31, False)
    save_tile(tiles / "wasteland_ground_2p5d.png", [(39, 35, 30, 255), (48, 42, 34, 255), (35, 58, 42, 255), (61, 48, 35, 255)], 32, True)

    props = SPRITES / "props"
    save_prop(props / "rust_rock.png", 72, 62, "rust_rock", 40)
    save_prop(props / "dead_tree.png", 72, 110, "dead_tree", 41)
    save_prop(props / "scrap_wall.png", 96, 66, "scrap_wall", 42)
    save_prop(props / "toxic_pool.png", 88, 54, "toxic_pool", 43)
    save_prop(props / "wreck.png", 104, 78, "wreck", 44)
    save_prop(props / "signal_pylon.png", 72, 128, "signal_pylon", 45)
    save_prop(props / "road_marker.png", 42, 58, "road_marker", 46)

    npcs = SPRITES / "npcs"
    save_npc(npcs / "forge_master.png", [(58, 46, 38, 255), (111, 75, 52, 255), (165, 110, 70, 255)], (245, 142, 53, 255), 51, "forge")
    save_npc(npcs / "scrap_merchant.png", [(55, 43, 31, 255), (116, 82, 49, 255), (178, 132, 70, 255)], (231, 178, 74, 255), 52, "merchant")
    save_npc(npcs / "repair_robot.png", [(35, 55, 65, 255), (60, 105, 124, 255), (92, 168, 188, 255)], (78, 224, 241, 255), 53, "robot")
    save_npc(npcs / "wasteland_survivor.png", [(42, 54, 39, 255), (77, 100, 68, 255), (122, 143, 95, 255)], (171, 224, 95, 255), 54, "survivor")
    save_npc(npcs / "guild_clerk.png", [(46, 37, 65, 255), (82, 66, 121, 255), (128, 104, 172, 255)], (221, 185, 91, 255), 55, "clerk")
    save_npc(npcs / "route_scout.png", [(42, 50, 44, 255), (75, 96, 71, 255), (118, 136, 95, 255)], (111, 209, 132, 255), 56, "scout")

    synth(AUDIO / "music_village.wav", [(196, "sine"), (247, "sine"), (294, "sine"), (247, "sine"), (220, "sine"), (196, "sine"), (165, "sine"), (196, "sine")], 0.38, 0.22)
    synth(AUDIO / "music_guild.wav", [(147, "sine"), (196, "sine"), (220, "sine"), (294, "sine"), (262, "sine"), (220, "sine"), (196, "sine"), (147, "sine")], 0.42, 0.2)
    synth(AUDIO / "music_wasteland.wav", [(110, "square"), (0.1, "noise"), (130, "square"), (0.1, "noise"), (98, "square"), (147, "square")], 0.34, 0.16)
    synth(AUDIO / "sfx_melee.wav", [(420, "square"), (280, "square")], 0.055, 0.42)
    synth(AUDIO / "sfx_shoot.wav", [(760, "square"), (0.1, "noise")], 0.045, 0.38)
    synth(AUDIO / "sfx_hit.wav", [(180, "square"), (90, "square")], 0.05, 0.46)
    synth(AUDIO / "sfx_pickup.wav", [(660, "sine"), (990, "sine")], 0.06, 0.34)
    synth(AUDIO / "sfx_interact.wav", [(360, "sine"), (540, "sine")], 0.07, 0.3)
    synth(AUDIO / "sfx_death.wav", [(220, "square"), (160, "square"), (90, "square")], 0.12, 0.42)
    print("Generated PC pixel art and audio assets.")


if __name__ == "__main__":
    main()
