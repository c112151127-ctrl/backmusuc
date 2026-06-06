# 廢土回收商 Vertical Slice 實作計畫

## 目前專案狀態

目前專案已具備 Godot 4.6.3 vertical slice：村莊、公會、野外三場景可切換；玩家可移動、近戰、射擊、撿取、背包裝備、快捷欄切換、接取委託、交付獎勵與存讀檔。野外地圖採 seed 生成，具備資源點、事件點、Y-Sort 地標、阻擋障礙、30 名敵人與 200 顆投射物上限。NPC 資料位於 `data/maps/npcs.json`，支援首次交談獎勵與重複交談防重領。

## Vertical Slice 目標

玩家從村莊開始，依 NPC 與公告理解「整備 → 公會接委託 → 進野外 → 近戰/遠程戰鬥 → 撿資源 → 回公會交付 → 回村強化與存檔」循環。若尚未能做正式美術與 Android 匯出，仍必須能用 Godot headless 驗證資料、場景、戰鬥、NPC、任務、存檔與玩家動畫合約。

## 必要修改檔案

- `AGENTS.md`、`AI_HANDOFF.md`、`WORKFLOW.md`：建立 AI 交接、協作、驗證、Git 與 push 規則。
- `docs/IMPLEMENTATION_PLAN.md`：保存可執行實作計畫。
- `docs/PLAYTEST_CHECKLIST.md`：更新繁體中文手動與自動試玩清單。
- `docs/SRS_TRACEABILITY.md`：更新 SRS 與目前實作對照。
- `assets/sprites/README.md`：記錄多角度像素素材規格。
- `scripts/utils/PixelArtFactory.gd`、`scripts/tools/PixelAssetBaker.gd`、`scenes/player/Player.gd`、`scripts/tests/VerticalSliceVerifier.gd`：讓玩家 sprite atlas 與動畫驗證支援 7 動作。
- `data/maps/npcs.json`：若對話導引不足，補強 NPC 指引與一次性獎勵說明。

## 玩家流程

1. 進入村莊，HUD 顯示 HP、EP、彈藥、廢鐵、核心、場景與委託。
2. 與村莊 NPC 交談取得導引與一次性小獎勵。
3. 使用鍛造、合成、商店、改裝、拆解或存檔點整備。
4. 前往公會接取委託。
5. 從村莊或公會進入野外，探索資源、事件、障礙與敵人。
6. 用近戰清空間並回收彈藥，用遠程消耗彈藥處理危險敵人。
7. 撿取掉落與資源後回公會交付委託。
8. 回村強化裝備並存檔，準備下一趟探索。

## NPC 導引與獎勵流程

NPC 第一次交談使用 `line`，給予 `reward` 並將 NPC id 寫入 `GameState.talked_npcs`；第二次以後使用 `repeat_line`，只顯示提示，不重複給獎。驗證重點是：

- 村莊 NPC 引導鍛造、交易、快捷欄、敵人應對與回村整備。
- 公會 NPC 引導接任務、交付與 seed 路線記憶。
- 存檔包含 `talked_npcs`，讀檔後不能重新領取同一 NPC 獎勵。

## 像素角色素材規格

玩家角色採 32x40 frame、Nearest Neighbor、透明背景。正式 atlas 為 7 動作 x 8 方向 x 3 frame，尺寸為 672x320。方向順序沿用目前程式方向索引：0 右、1 右下、2 下、3 左下、4 左、5 左上、6 上、7 右上。

動作列需求：

- `idle`：待機，身體微幅呼吸，武器收在身側。
- `walk`：行走，左右腳與身體有 3 frame 位移。
- `shoot`：射擊，槍口或管線朝當前方向伸出，有開火高亮。
- `draw_sword`：拔刀，手從身側或背後取出刀具。
- `slash`：斬擊，刀光或刀身形成短弧線，清楚區分近戰攻擊。
- `swap_tool`：切換工具或武器，手部與工具核心有橘色高亮。
- `interact`：互動，手向前伸或工具發出綠色掃描光。

## 玩家動作狀態規格

`Player.gd` 的狀態機應能進入：

- `IDLE`：無移動與無動作時。
- `WALK`：WASD 或觸控方向輸入時。
- `SHOOT`：遠程攻擊輸入且彈藥足夠時。
- `DRAW_SWORD`：近戰攻擊剛開始時。
- `SLASH`：拔刀後短時間切到斬擊幀。
- `SWAP_TOOL`：按 `Q`、`1`-`4` 或觸控「切換」時。
- `INTERACT`：按 `E` 或觸控「互動」時。
- `HIT` / `DEAD`：保留給後續受擊與死亡動畫擴充。

## 驗證清單

- `data/maps/npcs.json` 可用 Node JSON.parse 解析。
- Godot `--quit` 可載入專案。
- `PixelAssetBaker.tscn` 可重新輸出玩家、敵人、物品與 tileset PNG。
- `ValidationRunner.tscn` 通過資料、場景、NPC、任務、戰鬥、存檔、觸控與玩家動畫合約。
- `AutomatedPlaytestRunner.tscn` 通過移動、背包、NPC 首次獎勵、公會委託、野外近戰/射擊、存讀檔。
- `git status --short` 在 commit 後乾淨，或清楚列出剩餘 dirty 檔。
- remote 設為 `https://github.com/yuchan27/Game.git` 後執行 `git push -u origin HEAD`。

## 剩餘 TODO

- 補齊 Android export templates、Java SDK、Android SDK、adb、sdkmanager、apksigner 與 keytool 後做 APK 匯出與實機觸控驗證。
- 用正式像素美術替換目前程式生成 atlas，並保留 7 動作 x 8 方向 x 3 frame 格式。
- 擴充 NPC 對話分支、更多公會委託與戰鬥平衡。
- 加入正式受擊、死亡、閃避或職業切換動畫。
