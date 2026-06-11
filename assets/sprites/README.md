# 像素素材說明

本專案目前使用可替換的 PNG 像素素材，目標是先讓 PC vertical slice 看起來像完整遊戲，而不是臨時色塊。

## 玩家

- `player/recycler_player_multiaction_8dir.png`
- 格式：7 動作 x 8 方向 x 3 frame。
- 單格：48x56。
- atlas：1008x448。
- 動作順序：`idle`、`walk`、`shoot`、`draw_sword`、`slash`、`swap_tool`、`interact`。
- 方向順序：下、右下、右、右上、上、左上、左、左下。

## NPC

`assets/sprites/npcs/` 內每位 NPC 都有獨立 PNG：

- `forge_master.png`：鐵匠。
- `scrap_merchant.png`：補給商。
- `repair_robot.png`：維修機器人。
- `wasteland_survivor.png`：廢土倖存者。
- `guild_clerk.png`：公會櫃台。
- `route_scout.png`：路線偵查員。

## 建築與互動設施

`assets/sprites/structures/` 提供村莊、公會與出口 PNG：

- 鍛造爐、合成台、商店、改裝站、拆解機、維修存檔點。
- 公會委託看板、獎勵櫃台、公會出口、村莊回程門、廢土出口。

## 地圖與物件

- `tiles/village_ground_2p5d.png`
- `tiles/guild_ground_2p5d.png`
- `tiles/wasteland_ground_2p5d.png`
- `props/`：岩石、枯樹、廢鐵牆、毒池、廢棄車體、訊號塔、路標。

## 生成方式

目前 PC 端 PNG 與 WAV 由 `scripts/tools/generate_pc_assets.py` 產生。Godot 場景使用 `scripts/utils/RuntimeAssetLoader.gd` 直接載入 PNG/WAV，因此不需要等待 Godot editor 產生 `.import` 檔也能顯示。

若後續使用正式美術，只要保持檔名與大致尺寸，不需要改場景邏輯。
