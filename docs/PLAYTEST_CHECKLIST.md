# 廢土回收商 PC 測試清單

## 自動驗證

每次提交前請執行：

```powershell
node -e "for (const f of ['data/maps/npcs.json','data/maps/events.json','data/maps/quests.json','data/items/equipment.json','data/items/recipes.json','data/enemies/enemies.json','data/maps/wasteland_params.json']) { JSON.parse(require('fs').readFileSync(f,'utf8')); } console.log('JSON OK')"
& 'C:\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe' --headless --path 'C:\Code\Game\first-game' --quit
& 'C:\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe' --headless --path 'C:\Code\Game\first-game' --scene 'res://scenes/tests/PixelAssetBaker.tscn'
& 'C:\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe' --headless --path 'C:\Code\Game\first-game' --scene 'res://scenes/tests/ValidationRunner.tscn'
& 'C:\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe' --headless --path 'C:\Code\Game\first-game' --scene 'res://scenes/tests/AutomatedPlaytestRunner.tscn'
& 'C:\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe' --path 'C:\Code\Game\first-game' --scene 'res://scenes/tests/VisualReviewRunner.tscn'
```

`VisualReviewRunner` 會更新：

- `docs/visual_review_village.png`
- `docs/visual_review_guild.png`
- `docs/visual_review_wasteland.png`

請檢查截圖中是否有大面積文字重疊、NPC 標籤常駐、建築互動字遮住角色、或地圖邊界露出空白區。

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
6. 按 `I` 開啟人物裝備介面，確認目前左鍵動作、近戰武器、遠程武器、護甲、工具與背包內容可讀。
7. 按 `1` 切到刀類，滑鼠左鍵應觸發近戰揮砍。
8. 按 `2` 切到槍類，滑鼠左鍵應消耗彈藥並射出投射物；按住左鍵應持續射擊。
9. 按 `M` 開啟小地圖，確認目前場景節點與村莊、公會、廢土路線可讀。
10. 前往公會接取「清理廢鐵通道」委託，確認 HUD 顯示任務目標。
11. 進入野外，確認地圖明顯比村莊大，有岩石、枯樹、廢車、毒池、資源點、事件點與敵人。
12. 在野外嘗試走向邊界，確認玩家不會離開可玩區域。
13. 與野外事件點互動，確認出現事件文字與獎勵。
14. 擊倒敵人後確認掉落物可撿取，任務擊殺數會更新。
15. 使用 `F5` 存檔、`F9` 讀檔，確認血量、位置、背包、裝備、任務與已交談 NPC 狀態保留。

## 畫面 Review 重點

- 地圖不應只是一整片重複地板，需要有路徑、裂痕、汙染斑、障礙物與資源點。
- 村莊、公會、野外的色調與功能建築需能區分。
- NPC 與建築不能把大量文字固定顯示在畫面上。
- 角色、NPC、建築和障礙物的 Y ordering 應讓前後關係合理。
- 敵人至少要能從輪廓看出近戰、快速、遠程、重型、飛行、混合型差異。

## 已知限制

- 目前素材是可替換的像素 PNG，已改善輪廓與場景辨識，但仍不是最終商業級精修美術。
- 裝備介面目前是資訊檢視與背包列表，尚未支援拖曳換裝。
- Android 觸控 UI 暫緩，現階段以 PC 鍵鼠體驗為主。
