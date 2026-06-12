from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

from PIL import Image, ImageOps


ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "docs" / "art_direction_reference_v3.png"
SPRITES = ROOT / "assets" / "sprites"
DOCS = ROOT / "docs"


Box = tuple[int, int, int, int]
Size = tuple[int, int]


@dataclass(frozen=True)
class AssetCrop:
    name: str
    box: Box
    size: Size


def is_preview_background(pixel: tuple[int, int, int, int]) -> bool:
    r, g, b, a = pixel
    if a < 8:
        return True
    dark_checker = 8 <= r <= 58 and 8 <= g <= 58 and 8 <= b <= 64 and max(r, g, b) - min(r, g, b) <= 18
    near_black_checker = 13 <= r <= 34 and 13 <= g <= 34 and 13 <= b <= 40
    return dark_checker or near_black_checker


def remove_preview_background(img: Image.Image) -> Image.Image:
    rgba = img.convert("RGBA")
    pix = rgba.load()
    width, height = rgba.size
    queue: list[tuple[int, int]] = []
    seen = bytearray(width * height)

    def push_if_background(x: int, y: int) -> None:
        index = y * width + x
        if seen[index]:
            return
        if is_preview_background(pix[x, y]):
            seen[index] = 1
            queue.append((x, y))

    for x in range(width):
        push_if_background(x, 0)
        push_if_background(x, height - 1)
    for y in range(height):
        push_if_background(0, y)
        push_if_background(width - 1, y)

    for x, y in queue:
        pix[x, y] = (0, 0, 0, 0)
        if x > 0:
            push_if_background(x - 1, y)
        if x < width - 1:
            push_if_background(x + 1, y)
        if y > 0:
            push_if_background(x, y - 1)
        if y < height - 1:
            push_if_background(x, y + 1)

    return rgba


def crop_asset(src: Image.Image, box: Box, size: Size, bottom_align: bool = True) -> Image.Image:
    cropped = remove_preview_background(src.crop(box))
    alpha_box = cropped.getbbox()
    if alpha_box is not None:
        cropped = cropped.crop(alpha_box)
    fitted = ImageOps.contain(cropped, (max(1, size[0] - 4), max(1, size[1] - 4)), Image.Resampling.LANCZOS)
    out = Image.new("RGBA", size, (0, 0, 0, 0))
    y = size[1] - fitted.height if bottom_align else (size[1] - fitted.height) // 2
    out.alpha_composite(fitted, ((size[0] - fitted.width) // 2, max(0, y)))
    return out


def crop_tile(src: Image.Image, box: Box, size: Size) -> Image.Image:
    tile = src.crop(box).convert("RGBA")
    return tile.resize(size, Image.Resampling.LANCZOS)


def save_asset(src: Image.Image, out: Path, box: Box, size: Size) -> Image.Image:
    out.parent.mkdir(parents=True, exist_ok=True)
    img = crop_asset(src, box, size)
    img.save(out)
    return img


def save_tile(src: Image.Image, out: Path, box: Box, size: Size = (32, 32)) -> Image.Image:
    out.parent.mkdir(parents=True, exist_ok=True)
    img = crop_tile(src, box, size)
    img.save(out)
    return img


def paste_cell(atlas: Image.Image, cell_img: Image.Image, cell: Size, column: int, row: int) -> None:
    atlas.alpha_composite(cell_img, (column * cell[0], row * cell[1]))


def build_player_atlas(src: Image.Image) -> Image.Image:
    cell = (48, 56)
    directions = 8
    frames = 3
    actions = 7
    atlas = Image.new("RGBA", (cell[0] * actions * frames, cell[1] * directions), (0, 0, 0, 0))

    # Direction order matches Player.gd: down, down-left, left, up-left, up, up-right, right, down-right.
    idle = [
        (40, 42, 118, 162),
        (146, 44, 220, 161),
        (236, 45, 305, 160),
        (326, 44, 394, 161),
        (423, 44, 492, 160),
        (326, 44, 394, 161),
        (236, 45, 305, 160),
        (146, 44, 220, 161),
    ]
    walk = [
        (43, 164, 114, 273),
        (141, 166, 209, 273),
        (231, 168, 299, 273),
        (315, 167, 385, 273),
        (411, 166, 477, 273),
        (315, 167, 385, 273),
        (231, 168, 299, 273),
        (141, 166, 209, 273),
    ]
    back = [
        (45, 284, 117, 370),
        (144, 285, 214, 396),
        (232, 284, 301, 396),
        (327, 286, 390, 397),
        (417, 286, 485, 366),
        (327, 286, 390, 397),
        (232, 284, 301, 396),
        (144, 285, 214, 396),
    ]
    sword = [
        (529, 45, 616, 159),
        (640, 43, 780, 153),
        (782, 44, 888, 137),
    ]
    sword_row2 = [
        (531, 168, 623, 274),
        (639, 169, 706, 275),
        (791, 171, 856, 274),
    ]
    shoot = [
        (527, 287, 624, 397),
        (636, 292, 728, 396),
        (732, 290, 867, 374),
    ]

    def place_action(action: int, source_rows: list[list[Box]], mirror_right: bool = False) -> None:
        for direction in range(directions):
            source = source_rows[min(direction, len(source_rows) - 1)]
            for frame in range(frames):
                img = crop_asset(src, source[frame % len(source)], cell)
                if mirror_right and direction in [5, 6, 7]:
                    img = img.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
                paste_cell(atlas, img, cell, action * frames + frame, direction)

    place_action(0, [[idle[i], walk[i], idle[i]] for i in range(directions)])
    place_action(1, [[walk[i], idle[i], walk[(i + 1) % directions]] for i in range(directions)])
    place_action(2, [shoot] * directions, True)
    place_action(3, [sword] * directions, True)
    place_action(4, [sword_row2] * directions, True)
    place_action(5, [[idle[i], back[i], idle[i]] for i in range(directions)])
    place_action(6, [[idle[i], walk[i], idle[i]] for i in range(directions)])

    out = SPRITES / "player" / "recycler_player_multiaction_8dir.png"
    out.parent.mkdir(parents=True, exist_ok=True)
    atlas.save(out)
    return atlas


def build_enemy_atlas(src: Image.Image) -> Image.Image:
    cell = (96, 72)
    boxes: list[Box] = [
        (1002, 51, 1188, 199),
        (1226, 67, 1399, 213),
        (1412, 50, 1550, 231),
        (1002, 249, 1188, 428),
        (1409, 276, 1551, 438),
        (1292, 477, 1384, 616),
        (1567, 38, 2029, 444),
    ]
    atlas = Image.new("RGBA", (cell[0] * len(boxes), cell[1]), (0, 0, 0, 0))
    for i, box in enumerate(boxes):
        paste_cell(atlas, crop_asset(src, box, cell), cell, i, 0)
    out = SPRITES / "enemies" / "polluted_enemy_six_types.png"
    out.parent.mkdir(parents=True, exist_ok=True)
    atlas.save(out)
    return atlas


def build_item_atlas(src: Image.Image) -> Image.Image:
    cell = (80, 64)
    boxes: list[Box] = [
        (61, 447, 229, 575),
        (262, 456, 439, 599),
        (486, 444, 629, 591),
        (674, 457, 787, 584),
    ]
    atlas = Image.new("RGBA", (cell[0] * len(boxes), cell[1]), (0, 0, 0, 0))
    for i, box in enumerate(boxes):
        paste_cell(atlas, crop_asset(src, box, cell), cell, i, 0)
    out = SPRITES / "items" / "recycler_item_icons.png"
    out.parent.mkdir(parents=True, exist_ok=True)
    atlas.save(out)
    return atlas


def build_npcs(src: Image.Image) -> list[Image.Image]:
    npcs = SPRITES / "npcs"
    crops = [
        AssetCrop("forge_master.png", (885, 458, 1067, 656), (56, 72)),
        AssetCrop("scrap_merchant.png", (1077, 462, 1222, 651), (56, 72)),
        AssetCrop("repair_robot.png", (1292, 477, 1384, 616), (56, 72)),
        AssetCrop("wasteland_survivor.png", (1503, 465, 1616, 654), (56, 72)),
        AssetCrop("guild_clerk.png", (1675, 463, 1788, 658), (56, 72)),
        AssetCrop("route_scout.png", (1871, 466, 1984, 654), (56, 72)),
    ]
    return [save_asset(src, npcs / crop.name, crop.box, crop.size) for crop in crops]


def build_structures(src: Image.Image) -> list[Image.Image]:
    structures = SPRITES / "structures"
    crops = [
        AssetCrop("forge.png", (35, 936, 430, 1320), (192, 150)),
        AssetCrop("craft.png", (500, 945, 850, 1315), (176, 140)),
        AssetCrop("shop.png", (500, 945, 850, 1315), (184, 132)),
        AssetCrop("guild_gate.png", (955, 942, 1328, 1318), (190, 128)),
        AssetCrop("guild_contract_board.png", (955, 942, 1328, 1318), (200, 120)),
        AssetCrop("guild_reward_counter.png", (955, 942, 1328, 1318), (200, 120)),
        AssetCrop("mod_station.png", (1505, 920, 2030, 1288), (196, 146)),
        AssetCrop("recycle_machine.png", (1505, 920, 2030, 1288), (184, 132)),
        AssetCrop("save_station.png", (35, 936, 430, 1320), (168, 132)),
        AssetCrop("wasteland_gate.png", (1505, 920, 2030, 1288), (184, 128)),
        AssetCrop("guild_wasteland_exit.png", (1505, 920, 2030, 1288), (184, 128)),
        AssetCrop("village_return_gate.png", (955, 942, 1328, 1318), (184, 128)),
    ]
    return [save_asset(src, structures / crop.name, crop.box, crop.size) for crop in crops]


def build_props(src: Image.Image) -> list[Image.Image]:
    props = SPRITES / "props"
    crops = [
        AssetCrop("toxic_pool.png", (41, 668, 276, 838), (88, 54)),
        AssetCrop("rust_rock.png", (362, 655, 481, 787), (72, 62)),
        AssetCrop("scrap_wall.png", (558, 682, 704, 816), (96, 66)),
        AssetCrop("dead_tree.png", (668, 718, 787, 836), (72, 110)),
        AssetCrop("road_marker.png", (814, 692, 959, 848), (42, 58)),
        AssetCrop("wreck.png", (1036, 687, 1177, 849), (104, 78)),
        AssetCrop("signal_pylon.png", (1222, 712, 1474, 855), (72, 128)),
        AssetCrop("scrap_barricade.png", (1539, 754, 1718, 862), (104, 70)),
    ]
    return [save_asset(src, props / crop.name, crop.box, crop.size) for crop in crops]


def build_tiles(src: Image.Image) -> list[Image.Image]:
	tiles = SPRITES / "tiles"
	return [
		save_tile(src, tiles / "wasteland_ground_2p5d.png", (126, 884, 158, 916)),
		save_tile(src, tiles / "village_ground_2p5d.png", (390, 880, 422, 912)),
		save_tile(src, tiles / "guild_ground_2p5d.png", (430, 886, 462, 918)),
		save_tile(src, tiles / "wasteland_road_2p5d.png", (682, 884, 714, 916)),
		save_tile(src, tiles / "toxic_mud_2p5d.png", (1102, 882, 1134, 914)),
	]


def make_preview(images: Iterable[tuple[str, Image.Image]]) -> None:
    entries = list(images)
    cell_w, cell_h = 160, 120
    columns = 6
    rows = (len(entries) + columns - 1) // columns
    preview = Image.new("RGBA", (columns * cell_w, rows * cell_h), (19, 21, 23, 255))
    for index, (_name, img) in enumerate(entries):
        fitted = ImageOps.contain(img, (cell_w - 16, cell_h - 16), Image.Resampling.NEAREST)
        x = (index % columns) * cell_w + (cell_w - fitted.width) // 2
        y = (index // columns) * cell_h + (cell_h - fitted.height) // 2
        preview.alpha_composite(fitted, (x, y))
    preview.save(DOCS / "art_extraction_preview_v3.png")


def validate_outputs() -> None:
    expected = {
        SPRITES / "player" / "recycler_player_multiaction_8dir.png": (1008, 448),
        SPRITES / "enemies" / "polluted_enemy_six_types.png": (672, 72),
        SPRITES / "items" / "recycler_item_icons.png": (320, 64),
        SPRITES / "tiles" / "village_ground_2p5d.png": (32, 32),
        SPRITES / "tiles" / "wasteland_ground_2p5d.png": (32, 32),
        SPRITES / "tiles" / "wasteland_road_2p5d.png": (32, 32),
    }
    for path, size in expected.items():
        with Image.open(path) as img:
            if img.size != size:
                raise ValueError(f"{path} has size {img.size}, expected {size}")
            if img.convert("RGBA").getbbox() is None:
                raise ValueError(f"{path} is blank")


def main() -> None:
    if not SOURCE.exists():
        raise FileNotFoundError(f"Missing reference sheet: {SOURCE}")
    src = Image.open(SOURCE).convert("RGBA")
    if src.size != (2082, 1370):
        raise ValueError(f"Unexpected reference size {src.size}; expected the user-provided 2082x1370 sheet")

    preview_entries: list[tuple[str, Image.Image]] = []
    preview_entries.append(("player", build_player_atlas(src)))
    preview_entries.append(("enemy", build_enemy_atlas(src)))
    preview_entries.append(("items", build_item_atlas(src)))
    preview_entries.extend((f"npc-{i}", img) for i, img in enumerate(build_npcs(src)))
    preview_entries.extend((f"structure-{i}", img) for i, img in enumerate(build_structures(src)))
    preview_entries.extend((f"prop-{i}", img) for i, img in enumerate(build_props(src)))
    preview_entries.extend((f"tile-{i}", img) for i, img in enumerate(build_tiles(src)))
    make_preview(preview_entries)
    validate_outputs()
    print("Extracted high-detail reference sheet assets into Godot sprite folders.")
    print(f"Preview: {DOCS / 'art_extraction_preview_v3.png'}")


if __name__ == "__main__":
    main()
