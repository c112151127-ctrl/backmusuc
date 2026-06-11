# 像素素材規格

本資料夾保存目前 PC vertical slice 使用的 PNG 像素素材。這些素材以「可玩、可替換、風格一致」為優先，方向是廢土機械、回收據點、污染野外與 2.5D 俯視像素風。

## 玩家

- 檔案：`player/recycler_player_multiaction_8dir.png`
- 規格：7 個動作 × 8 個方向 × 3 frame。
- 單格：48×56。
- 動作列：`idle`、`walk`、`shoot`、`draw_sword`、`slash`、`swap_tool`、`interact`。
- 方向：下、右下、右、右上、上、左上、左、左下。
- 設計重點：機械面罩、回收背包、工具掛點、近戰刀與遠程槍的動作差異。

## NPC

`assets/sprites/npcs/` 每位主要 NPC 都有獨立 PNG：

- `forge_master.png`：鍛造師，橘色護目鏡與工具手。
- `scrap_merchant.png`：補給商，黃色箱包與交易外觀。
- `repair_robot.png`：維修機器人，藍色機體與服務面板。
- `wasteland_survivor.png`：倖存者小隊長，綠色護甲與野外裝備。
- `guild_clerk.png`：公會接待員，紫色公會制服。
- `route_scout.png`：路線偵察員，偵察面罩與標記裝備。

NPC 名稱與互動提示只在玩家靠近時顯示，避免地圖文字重疊。

## 敵人

- 檔案：`enemies/polluted_enemy_six_types.png`
- 規格：六種敵人各一格，目前供 runtime 載入。
- 類型：近戰、快速、遠程、重型、飛行、混合型。
- 設計重點：每種敵人必須有不同輪廓，讓玩家一眼看出危險種類，不再用單純色塊或棋盤格替代。

## 建築與場景物件

`assets/sprites/structures/` 包含村莊、公會、野外入口與功能站：

- 鍛造、合成、補給、改裝、存檔、拆解、村莊出口。
- 公會櫃台、獎勵櫃台、公會野外出口。
- 野外回村入口。

`assets/sprites/props/` 包含可遮擋或裝飾地圖的物件：

- 岩石、枯樹、廢車、廢料牆、毒池、信號塔、路標。

## 地表

- `tiles/village_ground_2p5d.png`
- `tiles/guild_ground_2p5d.png`
- `tiles/wasteland_ground_2p5d.png`

地表由 `WorldBackdrop.gd` 與 runtime PNG 搭配使用，加入路徑、裂痕、汙染斑塊與色調差異，避免整張地圖只有單調重複底紋。

## 生成流程

可用下列命令重新產生目前 runtime 素材：

```powershell
& 'C:\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe' --headless --path 'C:\Code\Game\first-game' --scene 'res://scenes/tests/PixelAssetBaker.tscn'
```

若後續改用人工精修圖，請維持檔名與尺寸契約，避免破壞 Godot runtime 載入流程。
