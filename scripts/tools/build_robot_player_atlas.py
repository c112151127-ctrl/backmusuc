from __future__ import annotations

from pathlib import Path
from typing import Iterable

from PIL import Image, ImageDraw, ImageEnhance, ImageOps


ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "docs" / "art_direction_reference_v3.png"
OUTPUT = ROOT / "assets" / "sprites" / "player" / "recycler_player_multiaction_8dir.png"

FRAME_W, FRAME_H = 48, 56
ACTIONS = ["idle", "walk", "shoot", "draw_sword", "slash", "swap_tool", "interact"]

# Player.gd direction order:
# 0 right, 1 down-right, 2 down, 3 down-left, 4 left, 5 up-left, 6 up, 7 up-right.
IDLE_BOXES = {
    "front_left": (40, 42, 118, 162),
    "front": (146, 44, 220, 161),
    "front_right": (236, 45, 305, 160),
    "right": (423, 44, 492, 160),
    "back_right": (327, 286, 390, 397),
    "back": (232, 284, 301, 396),
    "back_left": (144, 285, 214, 396),
}
WALK_BOXES = {
    "front_left": [(43, 164, 114, 273), (40, 42, 118, 162), (141, 166, 209, 273)],
    "front": [(43, 164, 114, 273), (146, 44, 220, 161), (141, 166, 209, 273)],
    "front_right": [(141, 166, 209, 273), (236, 45, 305, 160), (231, 168, 299, 273)],
    "right": [(231, 168, 299, 273), (423, 44, 492, 160), (411, 166, 477, 273)],
    "back_right": [(327, 286, 390, 397), (411, 166, 477, 273), (417, 286, 485, 366)],
    "back": [(232, 284, 301, 396), (417, 286, 485, 366), (232, 284, 301, 396)],
    "back_left": [(144, 285, 214, 396), (45, 284, 117, 370), (144, 285, 214, 396)],
}
SWORD_BOXES = [
    (529, 45, 616, 159),
    (640, 43, 780, 153),
    (782, 44, 888, 137),
]
SLASH_BOXES = [
    (531, 168, 623, 274),
    (639, 169, 706, 275),
    (791, 171, 856, 274),
]
SHOOT_BOXES = [
    (527, 287, 624, 397),
    (636, 292, 728, 396),
    (732, 290, 867, 374),
]

DIRECTION_SPECS = {
    0: ("right", False),
    1: ("front_right", False),
    2: ("front", False),
    3: ("front_right", True),
    4: ("right", True),
    5: ("back_right", True),
    6: ("back", False),
    7: ("back_right", False),
}


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


def crop_asset(src: Image.Image, box: tuple[int, int, int, int]) -> Image.Image:
    cropped = remove_preview_background(src.crop(box))
    alpha_box = cropped.getbbox()
    if alpha_box is not None:
        cropped = cropped.crop(alpha_box)
    fitted = ImageOps.contain(cropped, (FRAME_W - 4, FRAME_H - 2), Image.Resampling.LANCZOS)
    fitted = ImageEnhance.Contrast(fitted).enhance(1.08)
    out = Image.new("RGBA", (FRAME_W, FRAME_H), (0, 0, 0, 0))
    out.alpha_composite(fitted, ((FRAME_W - fitted.width) // 2, FRAME_H - fitted.height))
    return out


def direction_angle(direction: int) -> float:
    return direction * 45.0


def direction_vector(direction: int) -> tuple[float, float]:
    import math

    angle = math.radians(direction_angle(direction))
    return math.cos(angle), math.sin(angle)


def mirrored_if_needed(img: Image.Image, mirror: bool) -> Image.Image:
    return img.transpose(Image.Transpose.FLIP_LEFT_RIGHT) if mirror else img


def cyberize(frame: Image.Image, direction: int, action: str, frame_index: int) -> Image.Image:
    draw = ImageDraw.Draw(frame, "RGBA")
    dx, dy = direction_vector(direction)
    mirror = direction in [3, 4, 5]
    body_x = 24
    eye_y = 20 if direction in [0, 1, 2, 3, 4] else 18

    # R-17 is a humanoid android: keep the readable silhouette, but cover the human face
    # with a metal helmet, cyan sensors, chest reactor, and exposed joint highlights.
    if direction not in [5, 6, 7]:
        draw.rounded_rectangle((body_x - 11, eye_y - 8, body_x + 11, eye_y + 8), radius=4, fill=(28, 35, 35, 235), outline=(8, 12, 12, 245), width=2)
        draw.rectangle((body_x - 14, eye_y - 3, body_x - 9, eye_y + 6), fill=(118, 72, 38, 225), outline=(16, 12, 10, 235))
        draw.rectangle((body_x + 9, eye_y - 3, body_x + 14, eye_y + 6), fill=(118, 72, 38, 225), outline=(16, 12, 10, 235))
        draw.line((body_x - 7, eye_y - 8, body_x + 5, eye_y - 8), fill=(151, 164, 154, 190), width=1)
        draw.rounded_rectangle((body_x - 7, eye_y - 2, body_x + 7, eye_y + 3), radius=2, fill=(28, 225, 242, 210), outline=(4, 32, 36, 230), width=1)
        draw.point((body_x - 4, eye_y), fill=(230, 255, 255, 255))
        draw.point((body_x + 4, eye_y), fill=(230, 255, 255, 255))
    else:
        draw.rounded_rectangle((body_x - 10, eye_y - 7, body_x + 10, eye_y + 9), radius=4, fill=(33, 39, 38, 225), outline=(8, 11, 10, 235), width=2)
        draw.rectangle((body_x - 5, eye_y - 8, body_x + 5, eye_y - 5), fill=(135, 84, 43, 200))
        draw.line((body_x - 7, eye_y + 4, body_x + 7, eye_y + 4), fill=(32, 220, 235, 135), width=1)
    draw.rounded_rectangle((body_x - 8, 27, body_x + 8, 41), radius=2, fill=(35, 47, 48, 164), outline=(11, 15, 15, 180), width=1)
    draw.rectangle((body_x - 4, 30, body_x + 4, 37), outline=(20, 34, 38, 235), fill=(22, 180, 210, 125))
    draw.line((body_x - 9, 37, body_x - 14, 43), fill=(152, 169, 159, 210), width=1)
    draw.line((body_x + 9, 37, body_x + 14, 43), fill=(152, 169, 159, 210), width=1)
    draw.ellipse((body_x - 14, 37, body_x - 9, 42), fill=(52, 228, 239, 150), outline=(4, 28, 32, 180))
    draw.ellipse((body_x + 9, 37, body_x + 14, 42), fill=(52, 228, 239, 150), outline=(4, 28, 32, 180))
    draw.ellipse((10, 49, 38, 55), fill=(0, 0, 0, 92))

    if action == "shoot":
        hand = (body_x + dx * 8, 31 + dy * 5)
        muzzle = (body_x + dx * (20 + frame_index * 2), 31 + dy * (10 + frame_index))
        draw.line([hand, muzzle], fill=(28, 24, 21, 255), width=5)
        draw.line([hand, muzzle], fill=(173, 132, 72, 255), width=2)
        if frame_index == 1:
            flash = (muzzle[0] + dx * 5, muzzle[1] + dy * 5)
            draw.ellipse((flash[0] - 4, flash[1] - 4, flash[0] + 4, flash[1] + 4), fill=(255, 218, 84, 245))
            draw.ellipse((flash[0] + dx * 8 - 2, flash[1] + dy * 8 - 2, flash[0] + dx * 8 + 2, flash[1] + dy * 8 + 2), fill=(74, 231, 246, 220))
    elif action == "draw_sword":
        hip_x = body_x - 10 if not mirror else body_x + 10
        draw.line((hip_x, 40, body_x + dx * 14, 30 + dy * 8), fill=(230, 236, 220, 235), width=2)
        draw.line((hip_x, 42, body_x + dx * 10, 35 + dy * 6), fill=(255, 176, 68, 210), width=1)
    elif action == "slash":
        center = (body_x + dx * (8 + frame_index * 4), 28 + dy * (5 + frame_index))
        radius = 15 + frame_index * 4
        start = direction_angle(direction) - 70
        end = direction_angle(direction) + 58
        bbox = (center[0] - radius, center[1] - radius, center[0] + radius, center[1] + radius)
        draw.arc(bbox, start=start, end=end, fill=(255, 198, 70, 245), width=4)
        draw.arc((bbox[0] + 4, bbox[1] + 4, bbox[2] - 4, bbox[3] - 4), start=start, end=end, fill=(67, 229, 242, 180), width=2)
        draw.line((body_x, 32, body_x + dx * (20 + frame_index * 3), 31 + dy * (12 + frame_index * 2)), fill=(235, 238, 216, 245), width=2)
    elif action == "swap_tool":
        pulse = 3 + frame_index
        draw.rounded_rectangle((body_x - pulse, 27 - pulse, body_x + pulse, 27 + pulse), radius=2, outline=(72, 229, 242, 220), width=2)
        draw.rectangle((body_x + 12, 28, body_x + 20, 36), fill=(177, 90, 42, 235), outline=(44, 32, 25, 245))
    elif action == "interact":
        for i in range(3):
            px = body_x + dx * (8 + i * 5)
            py = 28 + dy * (5 + i * 4)
            draw.ellipse((px - 2, py - 2, px + 2, py + 2), fill=(80, 232, 158, 210))

    return frame


def source_frames_for(action: str, direction: int) -> Iterable[tuple[int, int, int, int]]:
    pose, mirror = DIRECTION_SPECS[direction]
    if action == "walk":
        return WALK_BOXES[pose]
    if action == "shoot":
        return SHOOT_BOXES
    if action == "draw_sword":
        return SWORD_BOXES
    if action == "slash":
        return SLASH_BOXES
    if action == "swap_tool":
        return [IDLE_BOXES[pose], WALK_BOXES[pose][1], IDLE_BOXES[pose]]
    if action == "interact":
        return [IDLE_BOXES[pose], WALK_BOXES[pose][0], IDLE_BOXES[pose]]
    return [IDLE_BOXES[pose], WALK_BOXES[pose][1], IDLE_BOXES[pose]]


def main() -> None:
    src = Image.open(SOURCE).convert("RGBA")
    sheet = Image.new("RGBA", (FRAME_W * 3 * len(ACTIONS), FRAME_H * 8), (0, 0, 0, 0))
    for action_i, action in enumerate(ACTIONS):
        for direction in range(8):
            pose, mirror = DIRECTION_SPECS[direction]
            action_mirror = mirror
            if action in ["shoot", "draw_sword", "slash"]:
                action_mirror = direction in [3, 4, 5]
            boxes = list(source_frames_for(action, direction))
            for frame_i in range(3):
                frame = crop_asset(src, boxes[frame_i % len(boxes)])
                frame = mirrored_if_needed(frame, action_mirror)
                frame = cyberize(frame, direction, action, frame_i)
                sheet.alpha_composite(frame, ((action_i * 3 + frame_i) * FRAME_W, direction * FRAME_H))
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(OUTPUT)
    print(f"Wrote humanoid android atlas {OUTPUT} {sheet.size[0]}x{sheet.size[1]}")


if __name__ == "__main__":
    main()
