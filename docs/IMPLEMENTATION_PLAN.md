# 廢土回收商實作計畫

## 目前狀態

本專案已是可操作的 Godot 4.6.3 PC vertical slice，不再只以 MVP 為目標。現在包含村莊、公會、野外三個主要場景，玩家可以移動、互動、接委託、戰鬥、撿取資源、使用快捷裝備、開啟裝備介面、小地圖、教學提示與存讀檔。

本輪更新的重點是降低畫面混亂、補強 PC 操作邏輯、建立對話框、加入裝備檢視、改善敵人樣式、擴大野外地圖、增加邊界與障礙物，讓畫面更接近參考圖的 2.5D 廢土據點與野外探索感。

## Vertical Slice 目標

1. 玩家進入村莊後能看到基本 HUD、快捷列與操作提示。
2. 靠近 NPC 或功能建築時才出現互動提示，避免全地圖文字重疊。
3. 按 `E` 會開啟底部對話框，顯示 NPC 名稱、身分與對話內容。
4. 按 `I` 開啟人物裝備介面，確認近戰、遠程、護甲、工具、目前左鍵動作與背包內容。
5. 滑鼠左鍵依目前快捷裝備決定動作：刀類觸發揮砍，槍類觸發射擊。
6. 玩家能從村莊前往公會接委託，再進入野外擊倒敵人、觸發事件、撿資源並回村。
7. 野外地圖要比村莊大很多，具備邊界、障礙物、資源點、事件點、敵人與背景差異。

## 已修改 / 需維護檔案

- `scripts/autoload/GameState.gd`：輸入設定、快捷裝備、左鍵攻擊模式、NPC 對話訊號。
- `scenes/player/Player.gd`：PC 操作、左鍵依裝備攻擊、相機與世界邊界限制。
- `scenes/ui/HUD.gd`：HUD、對話框、裝備介面、小地圖、教學提示。
- `scripts/ui/MiniMapView.gd`：小地圖繪製。
- `scripts/components/DialogueNpc.gd`：NPC 顯示邏輯與對話觸發。
- `scripts/components/Interactable.gd`：互動提示只在靠近時顯示。
- `scenes/levels/village/Village.gd`：村莊配置、障礙、邊界、功能站提示。
- `scenes/levels/guild/Guild.gd`：公會配置、櫃台互動、邊界。
- `scenes/levels/wasteland/Wasteland.gd`：大型野外、敵人、事件、資源、邊界。
- `scripts/systems/WorldBackdrop.gd`：2.5D 地表、路徑、裂痕、汙染斑塊。
- `scripts/utils/PixelArtFactory.gd`：敵人像素圖、地表與 runtime 美術生成。
- `data/maps/npcs.json`：NPC 對話與一次性獎勵。
- `data/maps/events.json`：野外事件文字與獎勵。
- `data/maps/quests.json`：委託名稱、目標與獎勵。
- `data/items/equipment.json`：裝備名稱、攻擊模式與顯示資料。
- `data/enemies/enemies.json`：六種敵人定位與數值。
- `data/maps/wasteland_params.json`：野外尺寸、生成數量與 seed 參數。

## 玩家流程

1. 開始在村莊中央，先閱讀底部操作提示。
2. 用 `WASD` 移動；靠近 NPC 或建築才會出現 `E` 互動提示。
3. 和鍛造師、補給商、維修機等角色互動，取得彈藥、資源或提示。
4. 按 `I` 開啟裝備介面，確認目前裝備與左鍵攻擊動作。
5. 按 `1-4` 切換快捷裝備；刀類讓左鍵近戰，槍類讓左鍵射擊。
6. 前往公會接委託，再進入野外。
7. 在野外避開障礙、擊倒敵人、觸發事件、撿資源。
8. 回村合成、強化、補給與存檔。

## NPC 指引流程

NPC 只在玩家靠近時顯示名稱、身分與 `E：交談`，按下互動後由底部對話框呈現完整對話。此設計避免畫面上方與地圖區域塞滿文字，並讓玩家透過實際靠近探索來理解據點功能。

目前 NPC 包含：

- 鍛造老陳：提醒先補彈、接委託、再出村。
- 補給商阿洛：說明彈藥與遠程武器用途。
- 維修機 R-17：說明存檔與核心維修。
- 倖存者小隊長：引導玩家前往冒險公會。
- 公會接待員：說明委託循環。
- 路線偵察員：提醒野外障礙與資源點。

## 互動與一次性獎勵驗證

`GameState.talked_npcs` 會記錄已交談 NPC。第一次交談可發放獎勵，之後再次交談只顯示對話，不重複給獎。自動測試已驗證鍛造師第一次交談會給彈藥，且此行為可用於後續 NPC 教學獎勵。

## 像素角色多角度規格

玩家角色 atlas：

- 檔案：`assets/sprites/player/recycler_player_multiaction_8dir.png`
- 格式：7 個動作列 × 8 個方向 × 每方向 3 frame。
- 單格：48×56。
- 動作列：待機、走路、射擊、拔刀、砍擊、切換工具、互動。
- 方向：下、右下、右、右上、上、左上、左、左下。
- 美術方向：廢土回收商、機械護甲、亮色面罩、背包與工具掛點。

敵人圖像：

- 檔案：`assets/sprites/enemies/polluted_enemy_six_types.png`
- 六種敵人：腐爛掠食者、毒脊爬行獸、砲囊爆裂者、巨噬腐肉獸、腐化飛行體、汙染機械體。
- 每種敵人需有不同輪廓、顏色重點與攻擊辨識點，不再使用單純色塊。

## 玩家動作狀態規格

- `idle`：沒有輸入時站立，方向保留最後面向。
- `walking`：WASD 移動，角色依方向切換動畫。
- `shooting`：遠程武器射擊，消耗彈藥並生成投射物。
- `drawing sword`：近戰攻擊前搖，用於提升揮砍重量感。
- `slashing`：近戰命中判定，依面向打擊前方敵人。
- `switching tools / weapons`：按 `Q` 或 `1-4` 切換快捷欄。
- `interacting`：靠近 NPC 或功能站按 `E`，顯示對話或執行功能。

## 驗證清單

1. JSON 檔案必須能解析。
2. Godot headless 專案載入必須成功。
3. `PixelAssetBaker.tscn` 必須能產生玩家、NPC、建築、敵人與地表素材。
4. `ValidationRunner.tscn` 必須通過資料、輸入、HUD、NPC、裝備與存檔檢查。
5. `AutomatedPlaytestRunner.tscn` 必須通過村莊、公會、野外戰鬥與存讀檔流程。
6. `VisualReviewRunner.tscn` 必須產出村莊、公會、野外截圖，確認文字不大量重疊、NPC 提示只在靠近時顯示。
7. 手動測試需確認左鍵依裝備切換：刀類近戰、槍類射擊。

## 剩餘 TODO

- 目前美術仍是 runtime / script 生成像素圖，已比色塊版本清楚，但還不是最終商業級手繪品質。
- 建議後續用專職美術流程重畫高解析概念圖，再切成 Godot 可用的 tile、prop、NPC、enemy atlas。
- 野外已擴大並有障礙與事件，但還可以加入更多非戰鬥玩法，例如修復裝置、護送、回收路線解謎、天氣與夜晚威脅。
- 裝備介面已能顯示裝備與背包，但尚未加入拖曳換裝、詳細比較、套裝外觀預覽。
- 對話框已完成基本顯示，後續可加入逐字顯示、選項分支、任務接受確認。
