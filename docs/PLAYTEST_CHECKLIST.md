# 廢土回收商 PC 版 Playtest Checklist

## 自動驗證

```powershell
node -e "for (const f of ['data/maps/npcs.json','data/maps/events.json','data/maps/quests.json','data/maps/wasteland_routes.json','data/items/equipment.json','data/items/recipes.json','data/enemies/enemies.json','data/maps/wasteland_params.json']) { JSON.parse(require('fs').readFileSync(f,'utf8')); } console.log('JSON OK')"
python scripts\tools\build_robot_player_atlas.py
& 'C:\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe' --headless --path 'C:\Code\Game\first-game' --quit
& 'C:\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe' --headless --path 'C:\Code\Game\first-game' --scene 'res://scenes/tests/PixelAssetBaker.tscn'
& 'C:\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe' --headless --path 'C:\Code\Game\first-game' --scene 'res://scenes/tests/ValidationRunner.tscn'
& 'C:\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe' --headless --path 'C:\Code\Game\first-game' --scene 'res://scenes/tests/AutomatedPlaytestRunner.tscn'
& 'C:\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe' --path 'C:\Code\Game\first-game' --scene 'res://scenes/tests/VisualReviewRunner.tscn'
```

## 啟動與存檔

- 開啟遊戲時預設全螢幕。
- 若已有存檔，標題畫面顯示「繼續遊戲」且可讀取原進度。
- 新遊戲會顯示 R-17 背景故事導入。
- 存檔點會修復 HP / EP 並保存。
- 關閉遊戲後重新開啟，HP、資源、裝備、任務、路線、NPC 一次性獎勵狀態仍保留。

## 村莊

- 村莊是十字據點，四個方向都有出口。
- 靠近 NPC 才顯示名稱與 `E：交談`。
- 離開 NPC 範圍後對話框自動關閉。
- 鍛造、合成、商店、改裝、拆解、存檔、公會入口都可互動。
- NPC 對話文字全部為繁體中文，沒有亂碼。

## UI

- 一般遊玩時底部顯示小型提示列與快捷欄。
- 開啟人物裝備、教學、地圖或對話時，底部提示與快捷欄不重疊、不遮住面板。
- `Tab / I` 可開關人物裝備面板。
- 人物面板顯示 R-17、目前左鍵行動、近戰武器、遠程武器、護甲、工具、背包與屬性加成。
- `M` 可開關小地圖，`H` 可開關教學，`Esc` 可關閉面板。

## 戰鬥

- 快捷欄選刀時，滑鼠左鍵是近戰揮砍。
- 快捷欄選槍時，滑鼠左鍵是射擊。
- 彈藥不足時顯示可讀提示。
- 敵人受擊會顯示傷害數字、血條、受擊震動、污染液或火花效果。
- 敵人死亡會掉落圖二風格物品，掉落物會漂浮提示。
- Boss 路線會生成 Boss，Boss 受擊也要顯示血量回饋。
- Console 不應再出現 physics callback 直接切場景的 CollisionObject 移除錯誤。

## 四個廢土區

- 北門：紫晶裂隙，有紫色 / 晶核氛圍與 Boss。
- 南門：廢鐵公路，有道路、車骸、廢鐵與近戰敵人。
- 西門：毒沼排水區，有毒池、管線、快速敵人與污染晶核。
- 東門：舊工廠外圍，有工業障礙物、機械敵人與 Boss。
- 四個區域的地板、路線、地標、敵人混合與資源配置要能明顯區分。

## 視覺 Review

- 主角看起來是 R-17 機器人，不是人類背包角色。
- NPC、建築、敵人、掉落物、props 使用高細節廢土像素風。
- 地板不再像單調棋盤格，路線與地標能引導玩家方向。
- Y-sort 讓玩家能被建築、樹、牆、工業物件遮擋。
- UI 不應遮住核心戰鬥區或重要互動提示。
