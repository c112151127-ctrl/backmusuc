# 廢土回收商實作計畫

## 目前狀態

本專案是 Godot 4.6.3 製作的 PC 優先像素風偽 3D vertical slice。現在已具備村莊、公會、野外探索、NPC 對話、任務、近戰、射擊、掉落、撿取、裝備、存讀檔、音效、音樂與自動驗證場景。

本輪重點已轉向「不像 MVP、而像完整遊戲的可上市方向」：優先改善美術方向、道路感、掉落物辨識、敵人輪廓、Boss 區域、個人裝備面板與玩家逐幀攻擊動作。

## Vertical Slice 目標

玩家進入遊戲後應能完成下列流程：

1. 在村莊看見清楚的功能建築、道路與 NPC。
2. 透過教學提示理解 WASD、滑鼠左鍵、右鍵、E、I、M、H、F5、F9 的用途。
3. 靠近 NPC 才看到交談提示，使用對話框取得引導或一次性獎勵。
4. 開啟人物裝備介面，確認目前左鍵會依裝備變成揮刀或射擊。
5. 到公會接任務後前往廢土。
6. 在大型野外地圖沿著明顯道路、毒沼、晶化裂隙探索。
7. 擊敗不同輪廓敵人與 Boss，撿取有明確圖示的廢鐵、彈藥、異變核心、汙染晶核。
8. 回村強化、補給、存檔，形成「整備 → 出村 → 戰鬥 → 回收 → 強化」循環。

## 必要修改檔案

- `scripts/utils/PixelArtFactory.gd`：玩家多動作 atlas、敵人 atlas、掉落物 atlas 的核心產生邏輯。
- `scripts/systems/WorldBackdrop.gd`：村莊、公會、野外地表、道路、裂痕、汙染與 2.5D 層次。
- `scenes/ui/HUD.gd`：人物裝備介面、HUD、教學、小地圖、對話框。
- `scenes/levels/village/Village.gd`：村莊配置、建築/NPC/出口動線。
- `scenes/levels/guild/Guild.gd`：公會任務與出口動線。
- `scenes/levels/wasteland/Wasteland.gd`：大型野外、障礙、事件、資源、敵人、Boss 與邊界。
- `scripts/components/Pickup.gd`：掉落物圖示、撿取提示、物件比例。
- `scripts/tests/VerticalSliceVerifier.gd`：素材尺寸與核心流程驗證。
- `scripts/tests/VisualReviewRunner.gd`：產出村莊、公會、野外、道路、Boss、人物面板截圖供人工 review。
- `assets/sprites/player/recycler_player_multiaction_8dir.png`：玩家 7 動作 × 8 方向 × 3 frame。
- `assets/sprites/enemies/polluted_enemy_six_types.png`：六種敵人與 Boss。
- `assets/sprites/items/recycler_item_icons.png`：四種主要掉落物。
- `docs/art_direction_reference.png`：本輪使用 imagegen 產生的美術方向參考圖。

## 玩家流程

- 村莊：補給、合成、鍛造、改裝、拆解、存檔、前往公會或廢土。
- 公會：接取委託、查看獎勵、前往野外。
- 野外：沿道路探索，辨識毒沼與晶化裂隙，擊殺敵人、打 Boss、撿資源。
- 回村：使用資源補給與強化，再次出發。

## NPC 指引流程

NPC 只在玩家靠近時顯示名稱、職業與 `E：交談`。交談時底部對話框顯示 NPC 名稱、身分與繁體中文對話。

主要 NPC 分工：

- 鍛造老陳：提醒先補彈、再接任務，首次給彈藥。
- 補給商阿洛：引導購買彈藥與資源補給。
- 維修機 R-17：引導存檔與機械修復。
- 倖存者小隊長：引導公會委託與野外風險。
- 公會接待員：引導接取「清理廢鐵通道」。
- 路線偵察員：提示道路、毒沼與晶化裂隙方向。

## 互動與獎勵驗證

- `GameState.talked_npcs` 記錄已交談 NPC，防止一次性獎勵重複領取。
- `data/maps/npcs.json` 保留 NPC 對話、身分、位置與 reward。
- `ValidationRunner.tscn` 驗證 NPC 資料、輸入、HUD、裝備與左鍵攻擊模式。
- `AutomatedPlaytestRunner.tscn` 驗證可從村莊前往公會、接任務、進野外、戰鬥、撿取與回村。

## 像素多角度角色規格

玩家素材檔案：`assets/sprites/player/recycler_player_multiaction_8dir.png`

- 規格：7 動作 × 8 方向 × 3 frame。
- 單格：48×56。
- 方向：下、右下、右、右上、上、左上、左、左下。
- 角色特徵：機械面罩、青色護目鏡、回收背包、肩甲、工具掛點、刀與管線釘槍。
- 動作需要逐幀有重心變化，不能只是平移或靜態換圖。

## 玩家動作狀態規格

- `idle`：呼吸與站姿微動，保留面向。
- `walking`：腳步與身體上下起伏，8 方向移動。
- `shooting`：依滑鼠方向舉槍，三幀包含預備、槍口火光、後座回彈。
- `drawing sword`：切到刀或按近戰時先拔刀，手臂與刀柄有出鞘感。
- `slashing`：三幀包含蓄力、斬擊弧、收刀；左鍵裝備刀時觸發。
- `switching tools / weapons`：按 `Q` 或 `1-4` 時短暫切工具，HUD 快捷欄同步高亮。
- `interacting`：靠近 NPC 或功能站按 `E`，角色面向目標並顯示對話框或功能結果。
- `hit`：受擊短暫閃爍與擊退。
- `dead`：血量歸零時顯示死亡提示並安全切回村莊。

## 美術方向

參考圖檔：`docs/art_direction_reference.png`

整體方向：

- 深色廢土背景，避免單調純色地板。
- 物件有厚輪廓、暗部、鏽蝕橘、污染綠、核心紅、晶體紫與冷色高光。
- 地圖需要道路、裂痕、廢車、路標、毒池、晶化礦脈與工業設施。
- 敵人不能只是色塊，要從輪廓能辨識近戰、快速、遠程、重型、飛行、混合型與 Boss。
- 掉落物要像獨立戰利品：廢鐵束、彈藥箱、異變核心、汙染晶核。
- 文字提示必須收斂：NPC 與功能提示只在靠近時顯示，避免覆蓋地圖。

## 驗證清單

提交前執行：

```powershell
node -e "for (const f of ['data/maps/npcs.json','data/maps/events.json','data/maps/quests.json','data/items/equipment.json','data/items/recipes.json','data/enemies/enemies.json','data/maps/wasteland_params.json']) { JSON.parse(require('fs').readFileSync(f,'utf8')); } console.log('JSON OK')"
& 'C:\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe' --headless --path 'C:\Code\Game\first-game' --quit
& 'C:\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe' --headless --path 'C:\Code\Game\first-game' --scene 'res://scenes/tests/PixelAssetBaker.tscn'
& 'C:\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe' --headless --path 'C:\Code\Game\first-game' --scene 'res://scenes/tests/ValidationRunner.tscn'
& 'C:\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe' --headless --path 'C:\Code\Game\first-game' --scene 'res://scenes/tests/AutomatedPlaytestRunner.tscn'
& 'C:\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe' --path 'C:\Code\Game\first-game' --scene 'res://scenes/tests/VisualReviewRunner.tscn'
```

Visual review 需人工確認：

- 村莊功能建築不重疊，NPC 提示只在靠近時出現。
- 人物裝備介面清楚顯示角色、裝備、數值、背包與目前左鍵動作。
- 野外道路清楚，能辨識廢鐵公路、毒沼與晶化裂隙。
- 掉落物、敵人、Boss 不再像測試色塊。
- 角色和建築/障礙物的前後層次合理。

## 剩餘 TODO

- 將所有程式生成素材逐步替換為人工精修 PNG tileset、角色、建築、敵人與 UI icon。
- 裝備介面增加拖曳換裝、角色紙娃娃、裝備比較與套裝效果。
- 野外增加更多非戰鬥玩法，例如解謎、資源採集小遊戲、隨機商人、受困倖存者與環境危害。
- 對話系統加入選項分支、任務確認、逐字動畫與重要 NPC 立繪。
- 增加更多冒險地圖：廢鐵公路、毒沼邊界、晶化礦坑、舊工廠。
- 音效與音樂仍需正式製作或採購授權素材，現階段為可驗證占位版本。
