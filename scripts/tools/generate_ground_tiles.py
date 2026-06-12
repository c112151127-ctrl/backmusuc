from __future__ import annotations

from pathlib import Path
from random import Random

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[2]
TILES = ROOT / "assets" / "sprites" / "tiles"


def clamp(value: int) -> int:
    return max(0, min(255, value))


def jitter(color: tuple[int, int, int], rng: Random, amount: int) -> tuple[int, int, int, int]:
    return (
        clamp(color[0] + rng.randint(-amount, amount)),
        clamp(color[1] + rng.randint(-amount, amount)),
        clamp(color[2] + rng.randint(-amount, amount)),
        255,
    )


def make_ground_tile(base: tuple[int, int, int], accent: tuple[int, int, int], cracks: tuple[int, int, int], seed: int, stone: bool = False) -> Image.Image:
    rng = Random(seed)
    img = Image.new("RGBA", (32, 32), (*base, 255))
    draw = ImageDraw.Draw(img, "RGBA")
    for y in range(32):
        for x in range(32):
            img.putpixel((x, y), jitter(base, rng, 14))
    for _ in range(28):
        x = rng.randint(0, 31)
        y = rng.randint(0, 31)
        r = rng.randint(1, 3)
        draw.ellipse((x - r, y - r, x + r, y + r), fill=(*accent, rng.randint(38, 90)))
    for _ in range(8 if not stone else 14):
        x = rng.randint(-4, 30)
        y = rng.randint(0, 31)
        points = [(x, y)]
        for _step in range(rng.randint(2, 4)):
            x += rng.randint(4, 10)
            y += rng.randint(-5, 5)
            points.append((x, y))
        draw.line(points, fill=(*cracks, rng.randint(72, 135)), width=1)
    if stone:
        for _ in range(7):
            x = rng.randint(-2, 27)
            y = rng.randint(-2, 27)
            points = [
                (x + rng.randint(0, 3), y),
                (x + rng.randint(8, 17), y + rng.randint(1, 4)),
                (x + rng.randint(9, 18), y + rng.randint(7, 14)),
                (x + rng.randint(0, 5), y + rng.randint(8, 15)),
            ]
            draw.polygon(points, outline=(*cracks, 42), fill=(*jitter(base, rng, 8)[:3], 24))
    return img


def ground_tile(path: Path, base: tuple[int, int, int], accent: tuple[int, int, int], cracks: tuple[int, int, int], seed: int, stone: bool = False) -> None:
    img = make_ground_tile(base, accent, cracks, seed, stone)
    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(path)


def make_road_tile(seed: int) -> Image.Image:
    rng = Random(seed)
    img = Image.new("RGBA", (32, 32), (43, 42, 38, 255))
    draw = ImageDraw.Draw(img, "RGBA")
    for y in range(32):
        for x in range(32):
            img.putpixel((x, y), jitter((43, 42, 38), rng, 12))
    for _ in range(14):
        x = rng.randint(0, 31)
        y = rng.randint(0, 31)
        draw.line((x, y, x + rng.randint(4, 14), y + rng.randint(-6, 6)), fill=(12, 11, 10, rng.randint(90, 160)), width=1)
    if seed % 2 == 0:
        draw.line((15, 2, 15, 12), fill=(210, 164, 82, 120), width=2)
        draw.line((16, 20, 16, 29), fill=(210, 164, 82, 100), width=2)
    return img


def road_tile(path: Path, seed: int) -> None:
    img = make_road_tile(seed)
    img.save(path)


def variant_sheet(path: Path, maker, count: int = 4) -> None:
    sheet = Image.new("RGBA", (32 * count, 32), (0, 0, 0, 0))
    for index in range(count):
        sheet.alpha_composite(maker(index), (index * 32, 0))
    path.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(path)


def main() -> None:
    village = lambda i: make_ground_tile((64, 57, 46), (100, 90, 66), (28, 24, 20), 3101 + i * 17, True)
    guild = lambda i: make_ground_tile((54, 50, 45), (85, 72, 58), (24, 22, 20), 3102 + i * 17, True)
    wasteland = lambda i: make_ground_tile((74, 56, 38), (120, 92, 50), (24, 20, 16), 3103 + i * 17, False)
    toxic = lambda i: make_ground_tile((38, 60, 36), (106, 196, 64), (12, 30, 18), 3105 + i * 17, False)
    road = lambda i: make_road_tile(3104 + i * 17)

    ground_tile(TILES / "village_ground_2p5d.png", (64, 57, 46), (100, 90, 66), (28, 24, 20), 3101, True)
    ground_tile(TILES / "guild_ground_2p5d.png", (54, 50, 45), (85, 72, 58), (24, 22, 20), 3102, True)
    ground_tile(TILES / "wasteland_ground_2p5d.png", (74, 56, 38), (120, 92, 50), (24, 20, 16), 3103, False)
    road_tile(TILES / "wasteland_road_2p5d.png", 3104)
    ground_tile(TILES / "toxic_mud_2p5d.png", (38, 60, 36), (106, 196, 64), (12, 30, 18), 3105, False)

    variant_sheet(TILES / "village_ground_variants_2p5d.png", village)
    variant_sheet(TILES / "guild_ground_variants_2p5d.png", guild)
    variant_sheet(TILES / "wasteland_ground_variants_2p5d.png", wasteland)
    variant_sheet(TILES / "wasteland_road_variants_2p5d.png", road)
    variant_sheet(TILES / "toxic_mud_variants_2p5d.png", toxic)
    print("Generated organic ground tiles")


if __name__ == "__main__":
    main()
