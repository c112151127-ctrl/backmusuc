# 廢土回收商 PC 版 Playtest Checklist

## 自動驗證

```powershell
node -e "for (const f of ['data/maps/npcs.json','data/maps/events.json','data/maps/quests.json','data/maps/wasteland_routes.json','data/items/equipment.json','data/items/recipes.json','data/enemies/enemies.json','data/art/visual_assets.json']) { JSON.parse(require('fs').readFileSync(f,'utf8')); console.log('JSON OK', f); }"
python scripts\tools\build_release_candidate_assets.py
python scripts\tools\verify_visual_assets.py
& 'C:\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe' --headless --path 'C:\Code\Game\first-game' --quit
& 'C:\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe' --headless --path 'C:\Code\Game\first-game' --scene 'res://scenes/tests/PixelAssetBaker.tscn'
& 'C:\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe' --headless --path 'C:\Code\Game\first-game' --scene 'res://scenes/tests/ValidationRunner.tscn'
& 'C:\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe' --headless --path 'C:\Code\Game\first-game' --scene 'res://scenes/tests/AutomatedPlaytestRunner.tscn'
& 'C:\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe' --path 'C:\Code\Game\first-game' --scene 'res://scenes/tests/VisualReviewRunner.tscn'
```

## 啟動與存檔

- 啟動後若有存檔，主選單顯示「繼續遊戲 / 新遊戲」。
- 新遊戲第一次進入會播放 R-17 背景導入、專用音樂與繁中旁白；按「開始行動」後旁白會停止。
- 在村莊、接任務、完成任務或使用存檔點後，關閉再開遊戲可保留 HP、資源、任務、路線與 NPC 一次性獎勵狀態。
- 存檔損壞時不應崩潰，應回到新遊戲流程。

## 移動與主角外觀

- `A` 往左、`D` 往右，左右視角不能反。
- `W` 往上、`S` 往下，八方向動畫能依移動方向切換。
- `docs/player_direction_diagnostic.png` 中 `right D` 與 `left A` 應為左右鏡像，不可互換。
- 主角應使用 `docs/art_direction_reference_r17_full_body.png` 來源建立的全身 R-17 回收機器人，不可出現人類頭髮、背包角色、半身裁切或人類與機器人重疊。
- `assets/sprites/player/recycler_player_multiaction_8dir.png` 應為 `4032x1024`，單格 `112x128`，每個待機方向都要看得到頭、身體、手臂與腿部。
- 受擊與死亡會有可見閃光、震動或回村維修提示。

## 戰鬥與裝備

- 目前裝備近戰武器時，滑鼠左鍵會先拔刀再揮砍。
- 目前裝備遠程武器時，滑鼠左鍵會依滑鼠方向射擊，消耗彈藥並顯示槍口回饋。
- 揮砍與射擊必須從 R-17 身體附近發出，不可像畫面突然多出一隻獨立手臂或獨立武器。
- `docs/player_combat_pose_diagnostic.png` 應能看出拔刀、揮砍、射擊都跟主角身體連動。
- `1-4` 或 `Q` 可切換快捷裝備。
- 怪物受擊會顯示血條、傷害數字、擊退與污染液 / 火花效果。
- Boss 受擊、死亡與掉落都可見。

## UI 與人物面板

- `Tab / I` 開啟人物裝備面板。
- 面板顯示 R-17 預覽、近戰武器、遠程武器、護甲、工具、屬性加成、目前左鍵動作與背包格。
- 人物面板開啟時，快捷列、小提示、小地圖不應和面板重疊。
- `H` 開啟教學，`Esc` 關閉目前面板。
- 底部提示列固定在安全區，文字不遮住角色中心。

## 小地圖與全屏地圖

- 右上角小地圖顯示玩家、NPC、建築、出口、敵人、Boss、掉落物、事件與重要障礙物。
- 按 `M` 或點擊小地圖可開啟全屏地圖。
- 全屏地圖顯示目前路線名稱、玩家位置、視野框、圖例與任務目標。
- `Esc` 可關閉全屏地圖。

## NPC 與對話

- 只有靠近 NPC 時才顯示 `E` 互動提示。
- 按 `E` 會開啟正式對話框，包含 NPC 頭像、名稱、職業與對話內容。
- 離開 NPC 範圍時，對話框會自動關閉。
- 每個 NPC 的一次性獎勵只能領一次，重新讀檔後也不能重複領。

## 地圖與路線

- 村莊是十字樞紐，四個方向都有清楚出口。
- 南門廢鐵公路有破柏油、車骸、路障與彈藥箱。
- 西門毒沼排水區有毒池、管線、飛行敵人與毒液資源。
- 北門紫晶裂隙有紫晶礦脈、裂谷、遠程敵人與 Boss 前哨。
- 東門舊工廠外圍有鐵板、警戒線、工業建物、機械敵人與精英事件。
- 地板不應呈現明顯棋盤格或網格線。
- 建築、NPC、障礙物與玩家不可互相重疊到無法辨識，Y-sort 遮擋應合理。

## 美術 Review

- 命名 NPC、建築、裝備、掉落物、敵人與 Boss 不能共用同一張正式 PNG。
- 大量程序 props 可使用變體，但同畫面不能出現肉眼明顯相同的排列。
- 掉落物 icon 要對應實際物品，不能用方塊占位。
- 畫面色彩需有荒野對比：灰石、鏽橘、毒綠、紫晶、冷藍光源與深色廢土陰影。
- UI 不應遮住 NPC 對話、角色、出口或戰鬥重點。

## 已知剩餘風險

- Headless 模式離開 Godot 時可能仍有 ObjectDB leaked warning，目前不影響自動驗證與 playable flow。
- 真正上架前仍需人工美術精修、完整逐格動畫、音效混音與更多關卡事件。
