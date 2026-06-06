# Waste Recycler generated pixel assets

These SVG sheets are first-pass pixel-style source assets for the Godot vertical slice.

- `player/recycler_player_sprite_sheet.svg`: 8-direction player frames with action rows.
- `enemies/polluted_enemy_sheet.svg`: six polluted enemy concepts.
- `tiles/wasteland_tileset.svg`: village/wasteland floor, props, resources, and hazard tiles.
- `ui/hud_icons.svg`: HP, EP, scrap, crystal, and core icons.

The game currently generates runtime textures from GDScript so it remains playable without import churn. These sheets are ready to replace the generated textures with real sprite-frame animations later.
