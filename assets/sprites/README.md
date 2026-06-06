# 廢土回收商像素素材

這些檔案是 Godot vertical slice 使用的第一版像素風素材與可替換規格。

- `player/recycler_player_sprite_sheet.svg`：早期 8 方向玩家概念圖。
- `player/recycler_player_multiaction_8dir.png`：目前可玩版玩家 atlas，單格 32x40，7 種動作、8 方向、每方向 3 frame。動作順序是 `idle`、`walk`、`shoot`、`draw_sword`、`slash`、`swap_tool`、`interact`。
- `enemies/polluted_enemy_sheet.svg`：六種污染敵人概念。
- `tiles/wasteland_tileset.svg`：村莊、廢土地面、地標、資源與危險地形概念。
- `ui/hud_icons.svg`：HP、EP、廢鐵、晶體與核心 icon。

目前遊戲會用 GDScript 生成可用像素素材，確保沒有正式美術時仍可玩。後續可用正式像素圖替換玩家 atlas，但必須保留相同的 7 動作、8 方向、每方向 3 frame 版面，否則需要同步更新 `Player.gd` 與 `VerticalSliceVerifier.gd`。
