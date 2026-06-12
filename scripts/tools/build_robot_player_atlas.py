from pathlib import Path
from PIL import Image, ImageDraw, ImageEnhance
import math

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "assets" / "sprites" / "npcs" / "repair_robot.png"
OUTPUT = ROOT / "assets" / "sprites" / "player" / "recycler_player_multiaction_8dir.png"

FRAME_W, FRAME_H = 48, 56
ACTIONS = ["idle", "walk", "shoot", "draw_sword", "slash", "swap_tool", "interact"]


def alpha_bbox(img: Image.Image):
    return img.getchannel("A").getbbox()


def fit_sprite(src: Image.Image, max_w: int, max_h: int) -> Image.Image:
    box = alpha_bbox(src)
    if box:
        src = src.crop(box)
    src.thumbnail((max_w, max_h), Image.Resampling.LANCZOS)
    return src


def draw_line(draw: ImageDraw.ImageDraw, p0, p1, fill, width=2):
    draw.line([p0, p1], fill=fill, width=width)


def draw_arc(draw: ImageDraw.ImageDraw, cx, cy, r, direction_index, frame_index):
    start = direction_index * 45 - 60 + frame_index * 14
    end = start + 72
    bbox = [cx - r, cy - r, cx + r, cy + r]
    draw.arc(bbox, start=start, end=end, fill=(255, 199, 82, 235), width=3)
    draw.arc([bbox[0] + 4, bbox[1] + 4, bbox[2] - 4, bbox[3] - 4], start=start, end=end, fill=(86, 224, 238, 160), width=1)


def paste_robot(frame: Image.Image, robot: Image.Image, action_i: int, direction_i: int, frame_i: int):
    draw = ImageDraw.Draw(frame, "RGBA")
    bob = 0
    sway = 0
    if action_i == 1:
        sway = [-2, 0, 2][frame_i]
        bob = abs(sway)
    elif action_i in [2, 4, 5]:
        sway = [1, 0, -1][frame_i]
    draw.ellipse((11, 47, 37, 55), fill=(0, 0, 0, 80))
    x = (FRAME_W - robot.width) // 2 + sway
    y = FRAME_H - robot.height - 4 + bob
    facing_left = direction_i in [3, 4, 5]
    bot = robot.transpose(Image.Transpose.FLIP_LEFT_RIGHT) if facing_left else robot
    frame.alpha_composite(bot, (x, y))

    angle = direction_i * math.pi / 4.0
    dx, dy = math.cos(angle), math.sin(angle)
    hand = (24 + dx * 10 + sway, 31 + dy * 5 + bob)
    tip = (24 + dx * 23 + sway, 31 + dy * 12 + bob)

    if action_i == 2:
        recoil = [0, -3, 1][frame_i]
        muzzle = (24 + dx * (25 + recoil), 31 + dy * (14 + recoil))
        draw_line(draw, hand, muzzle, (45, 38, 30, 255), 4)
        draw_line(draw, hand, muzzle, (160, 126, 75, 255), 2)
        if frame_i == 1:
            draw.ellipse((muzzle[0] - 3, muzzle[1] - 3, muzzle[0] + 4, muzzle[1] + 4), fill=(255, 214, 80, 240))
            draw.ellipse((muzzle[0] + dx * 7 - 2, muzzle[1] + dy * 7 - 2, muzzle[0] + dx * 7 + 2, muzzle[1] + dy * 7 + 2), fill=(75, 222, 238, 210))
    elif action_i == 3:
        hip = (24 - dx * 8, 43)
        draw_line(draw, hip, hand, (230, 180, 90, 240), 2)
        draw_line(draw, (hip[0], hip[1] + 3), tip, (235, 235, 204, 220), 1)
    elif action_i == 4:
        draw_arc(draw, 24 + sway, 28 + bob, 22 + frame_i * 2, direction_i, frame_i)
        draw_line(draw, hand, tip, (235, 235, 210, 245), 2)
    elif action_i == 5:
        draw.rectangle((int(hand[0]) - 5, int(hand[1]) - 5, int(hand[0]) + 5, int(hand[1]) + 5), fill=(173, 92, 44, 230))
        draw.rectangle((int(hand[0]) - 2, int(hand[1]) - 2, int(hand[0]) + 2, int(hand[1]) + 2), fill=(72, 224, 238, 240))
    elif action_i == 6:
        for i in range(3):
            px = hand[0] + dx * (5 + i * 5)
            py = hand[1] + dy * (5 + i * 5)
            draw.ellipse((px - 2, py - 2, px + 2, py + 2), fill=(82, 228, 154, 210))


def main():
    src = Image.open(SOURCE).convert("RGBA")
    robot = fit_sprite(src, 38, 50)
    robot = ImageEnhance.Contrast(robot).enhance(1.08)
    sheet = Image.new("RGBA", (FRAME_W * 3 * len(ACTIONS), FRAME_H * 8), (0, 0, 0, 0))
    for action_i, _action in enumerate(ACTIONS):
        for direction_i in range(8):
            for frame_i in range(3):
                frame = Image.new("RGBA", (FRAME_W, FRAME_H), (0, 0, 0, 0))
                paste_robot(frame, robot, action_i, direction_i, frame_i)
                sheet.alpha_composite(frame, ((action_i * 3 + frame_i) * FRAME_W, direction_i * FRAME_H))
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(OUTPUT)
    print(f"Wrote {OUTPUT} {sheet.size[0]}x{sheet.size[1]}")


if __name__ == "__main__":
    main()
