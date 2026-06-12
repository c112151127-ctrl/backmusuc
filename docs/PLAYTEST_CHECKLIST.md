# 廢土回收商 PC 測試清單

## 自動驗證

每次提交前請執行：

```powershell
node -e "for (const f of ['data/maps/npcs.json','data/maps/events.json','data/maps/quests.json','data/items/equipment.json','data/items/recipes.json','data/enemies/enemies.json','data/maps/wasteland_params.json']) { JSON.parse(require('fs').readFileSync(f,'utf8')); } console.log('JSON OK')"
python scripts\tools\extract_reference_sheet_assets.py
& 'C:\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe' --headless --path 'C:\Code\Game\first-game' --quit
& 'C:\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe' --headless --path 'C:\Code\Game\first-game' --scene 'res://scenes/tests/PixelAssetBaker.tscn'
& 'C:\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe' --headless --path 'C:\Code\Game\first-game' --scene 'res://scenes/tests/ValidationRunner.tscn'
& 'C:\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe' --headless --path 'C:\Code\Game\first-game' --scene 'res://scenes/tests/AutomatedPlaytestRunner.tscn'
& 'C:\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe' --path 'C:\Code\Game\first-game' --scene 'res://scenes/tests/VisualReviewRunner.tscn'
```

`VisualReviewRunner` 會更新：

- `docs/visual_review_village.png`
- `docs/visual_review_inventory_panel.png`
- `docs/visual_review_guild.png`
- `docs/visual_review_wasteland.png`
- `docs/visual_review_wasteland_road.png`
- `docs/visual_review_wasteland_boss.png`

請檢查截圖中是否有大面積文字重疊、NPC 標籤常駐、建築互動字遮住角色、道路不明顯、掉落物像測試色塊、人物裝備面板資訊不足，或地圖邊界露出空白區。

## PC 操作

- `WASD`：移動。
- 滑鼠左鍵：依目前快捷裝備自動決定近戰或射擊。
- `Space`：固定近戰。
- 滑鼠右鍵或 `K`：固定射擊。
- `E`：和靠近的 NPC 或功能站互動。
- `I`：開關人物裝備介面。
- `Q`：切換下一個快捷裝備。
- `1-4`：指定快捷裝備。
- `M`：開關小地圖。
- `H`：開關教學提示。
- `F5`：存檔。
- `F9`：讀檔。

## 手動測試流程

1. 啟動遊戲後確認預設為全螢幕或接近全螢幕視窗，HUD 不遮住角色。
2. 在村莊用 WASD 移動，確認角色不會走出地圖邊界。
3. 靠近鍛造師、補給商、維修機、公會引導 NPC，確認名稱與 `E：交談` 只在靠近時顯示。
4. 按 `E` 與 NPC 交談，確認底部對話框出現 NPC 名稱、身分與繁體中文對話。
5. 重複和同一 NPC 交談，確認一次性獎勵不會重複領取。
6. 按 `Tab` 或 `I` 開啟人物裝備介面，確認目前左鍵動作、近戰武器、遠程武器、護甲、工具與背包內容可讀；快捷裝備列只在面板開啟時出現。
7. 按 `1` 切到刀類，滑鼠左鍵應觸發近戰揮砍。
8. 按 `2` 切到槍類，滑鼠左鍵應消耗彈藥並射出投射物；按住左鍵應持續射擊。
9. 按 `M` 開啟小地圖，確認目前場景節點與村莊、公會、廢土路線可讀。
10. 前往公會接取「清理廢鐵通道」委託，確認 HUD 顯示任務目標。
11. 進入野外，確認地圖明顯比村莊大，有岩石、枯樹、廢車、毒池、資源點、事件點、冒險區域與敵人。
12. 在野外嘗試走向邊界，確認玩家不會離開可玩區域。
13. 與野外事件點互動，確認出現事件文字與獎勵。
14. 確認廢鐵、彈藥、異變核心、汙染晶核掉落物都來自 `docs/art_direction_reference_v3.png` 的圖二風格，有厚輪廓、陰影與獨立圖示，不再是棋盤格或純色測試方塊。
15. 擊倒敵人後確認掉落物可撿取，任務擊殺數會更新。
16. 前往晶化裂隙附近，確認廢土巨像 Boss 存在、尺寸明顯大於普通怪，會造成近身與遠程壓力。
17. 讓玩家死亡或被投射物擊中後切場景，確認 console 不再出現 `Removing a CollisionObject node during a physics callback`。
18. 使用 `F5` 存檔、`F9` 讀檔，確認血量、位置、背包、裝備、任務與已交談 NPC 狀態保留。

## 畫面 Review 重點

- 地圖不應只是一整片重複地板，需要有路徑、裂痕、汙染斑、障礙物與資源點。
- 主道路應能從色塊、邊線、裂痕與路標辨識，不應讓玩家看不出前往公會、廢土或 Boss 區的方向。
- 野外應能看出廢鐵公路、毒沼邊界、晶化裂隙三種區域色調。
- 村莊、公會、野外的色調與功能建築需能區分。
- NPC 與建築不能把大量文字固定顯示在畫面上。
- 角色、NPC、建築和障礙物的 Y ordering 應讓前後關係合理。
- 敵人至少要能從輪廓看出近戰、快速、遠程、重型、飛行、混合型與 Boss 差異。
- 掉落物 icon 需要能辨識資源類型，且不應像測試色塊。
- 人物裝備介面需要顯示角色頭像、目前左鍵行為、近戰武器、遠程武器、護甲、工具、背包與主要數值。
- 任何玩家、敵人、NPC、建築、掉落物、props 若看起來像簡化幾何色塊，視為美術驗收失敗。

## 已知限制

- 目前正式素材已改由 `docs/art_direction_reference_v3.png` 裁切輸出，風格明顯接近圖二；若以正式上市品質為目標，仍需要逐張人工清理邊緣、補足完整 8 方向動畫與製作專用 tileset。
- 裝備介面目前是資訊檢視與背包列表，尚未支援拖曳換裝。
- Android 觸控 UI 暫緩，現階段以 PC 鍵鼠體驗為主。
