from pathlib import Path
from PIL import Image
import shutil

ROOT = Path(__file__).resolve().parents[2]

SOURCE_ATLAS = ROOT / "docs" / "recycler_player_multiaction_8dir_preview.png"
OUT_DIR = ROOT / "assets" / "sprites" / "player" / "frames"

FRAME_W = 112
FRAME_H = 128
FRAMES_PER_ACTION = 8
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

EXPECTED_W = FRAME_W * FRAMES_PER_ACTION * len(ACTIONS)
EXPECTED_H = FRAME_H * DIRECTIONS


def main() -> None:
    if not SOURCE_ATLAS.exists():
        raise FileNotFoundError(f"Missing source atlas: {SOURCE_ATLAS}")

    atlas = Image.open(SOURCE_ATLAS).convert("RGBA")

    if atlas.size != (EXPECTED_W, EXPECTED_H):
        raise ValueError(
            f"Atlas size mismatch: got {atlas.size}, expected {(EXPECTED_W, EXPECTED_H)}. "
            "請確認 docs/recycler_player_multiaction_8dir_preview.png 是完整 9 動作 x 8 幀 x 8 方向的 atlas。"
        )

    if OUT_DIR.exists():
        shutil.rmtree(OUT_DIR)

    for action_index, action in enumerate(ACTIONS):
        for direction_index in range(DIRECTIONS):
            for frame_index in range(FRAMES_PER_ACTION):
                x = (action_index * FRAMES_PER_ACTION + frame_index) * FRAME_W
                y = direction_index * FRAME_H

                frame = atlas.crop((x, y, x + FRAME_W, y + FRAME_H))

                target = OUT_DIR / action / f"dir_{direction_index}" / f"frame_{frame_index}.png"
                target.parent.mkdir(parents=True, exist_ok=True)
                frame.save(target)

    print(f"Split player atlas completed: {OUT_DIR}")


if __name__ == "__main__":
    main()