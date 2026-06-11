# 廢土回收商實作計畫

## 目前狀態

專案是 Godot 4.6.3 PC 優先 vertical slice。現在已可從村莊出發，前往公會接委託，進入廢土戰鬥與回收資源，再回村使用設施強化與存讀檔。

## 本階段目標

本階段優先處理玩家回饋指出的問題：

- 畫面不能再像臨時色塊。
- 村莊、公會、廢土區塊不得大面積重疊。
- 先完成 PC 操作，不做手機按鈕。
- 玩家可用滑鼠左鍵按住射擊，空白鍵近戰。
- 每位 NPC、每個主要設施、公會與廢土出口都要有 PNG 美術。
- 剛進入遊戲要有基本操作提示，完整教學用 H 開關。
- 加入音樂、攻擊、射擊、受擊、撿取、互動、死亡音效。

## 主要修改檔案

- `scenes/levels/village/Village.gd`
- `scenes/levels/guild/Guild.gd`
- `scenes/levels/wasteland/Wasteland.gd`
- `scenes/ui/HUD.gd`
- `scenes/player/Player.gd`
- `scripts/autoload/GameState.gd`
- `scripts/autoload/AudioManager.gd`
- `scripts/utils/RuntimeAssetLoader.gd`
- `scripts/utils/PixelArtFactory.gd`
- `scripts/tools/generate_pc_assets.py`
- `scripts/tests/VisualReviewRunner.gd`
- `assets/sprites/player/recycler_player_multiaction_8dir.png`
- `assets/sprites/npcs/*.png`
- `assets/sprites/structures/*.png`
- `assets/sprites/props/*.png`
- `assets/audio/*.wav`

## 玩家流程

1. 進入村莊，閱讀底部 PC 操作提示。
2. 使用 WASD 移動，E 與 NPC / 設施互動。
3. 到公會接委託。
4. 前往廢土，滑鼠左鍵按住射擊，空白鍵近戰。
5. 擊倒污染體並回收資源。
6. 返回村莊，用資源補給、鍛造、合成、改裝或存檔。

## NPC 指引流程

NPC 使用 `data/maps/npcs.json` 的首次對話、重複對話與 reward。首次交談會寫入 `GameState.talked_npcs`，避免重複領獎。

## 美術規格

玩家 atlas：

- 7 動作：待機、走路、射擊、拔刀、砍擊、切換工具、互動。
- 8 方向：下、右下、右、右上、上、左上、左、左下。
- 每動作每方向 3 frame。
- 單格 48x56，atlas 1008x448。

場景 PNG：

- 村莊：鍛造、合成、商店、改裝、拆解、存檔、出口。
- 公會：委託看板、獎勵櫃台、廢土出口、村莊出口。
- 廢土：回村門、資源點、props、事件點。
- NPC：每位 NPC 一張獨立 PNG。

## 驗證清單

- JSON parse 通過。
- Godot `--quit` 通過。
- `PixelAssetBaker.tscn` 通過。
- `ValidationRunner.tscn` 通過。
- `AutomatedPlaytestRunner.tscn` 通過。
- `VisualReviewRunner.tscn` 成功輸出三張截圖。
- 人工檢查截圖確認主要區塊不再大面積重疊。

## 剩餘 TODO

- 將本地生成音樂與音效替換為正式授權素材。
- 精修像素美術細節，讓建築陰影、地面與角色比例更接近正式遊戲。
- 補 Android 匯出與觸控 UI。
- 加入更多打擊震動、受擊閃爍與死亡 UI。
