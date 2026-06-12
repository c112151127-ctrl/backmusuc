# 廢土回收商 PC 版 Playtest Checklist

## 自動驗證

```powershell
node -e "for (const f of ['data/maps/npcs.json','data/maps/events.json','data/maps/quests.json','data/maps/wasteland_routes.json','data/items/equipment.json','data/items/recipes.json','data/enemies/enemies.json','data/maps/wasteland_params.json']) { JSON.parse(require('fs').readFileSync(f,'utf8')); } console.log('JSON OK')"
python scripts\tools\build_robot_player_atlas.py
& 'C:\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe' --headless --path 'C:\Code\Game\first-game' --quit
& 'C:\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe' --headless --path 'C:\Code\Game\first-game' --scene 'res://scenes/tests/PixelAssetBaker.tscn'
& 'C:\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe' --headless --path 'C:\Code\Game\first-game' --scene 'res://scenes/tests/ValidationRunner.tscn'
& 'C:\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe' --headless --path 'C:\Code\Game\first-game' --scene 'res://scenes/tests/AutomatedPlaytestRunner.tscn'
```

## 開場與存檔

- 標題畫面顯示「廢土回收商」與「繼續遊戲 / 新遊戲」。
- 若已有存檔，選擇「繼續遊戲」會讀回血量、資源、裝備、任務、場景與路線。
- 新遊戲顯示 R-17 背景導入。
- 存檔點會修復 HP / EP 並保存。
- 關閉遊戲後重開，不會整個重新計算進度。

## 移動與方向

- `A` 讓角色往左走，角色朝左。
- `D` 讓角色往右走，角色朝右。
- `W` 朝上，`S` 朝下，斜向移動時角色朝向合理。
- 玩家角色是人形仿真回收機 R-17，不是小箱型機器人。

## 左鍵與武器

- 快捷欄選近戰武器時，滑鼠左鍵朝滑鼠方向揮砍。
- 快捷欄選遠程武器時，滑鼠左鍵朝滑鼠方向射擊。
- 連續揮砍時每次都有拔刀與刀光，不會卡在同一張靜態圖。
- 連續射擊時有舉槍、後座與槍口火光。
- 彈藥不足時顯示「彈藥不足，先用近戰清出空間或回村補給。」

## UI 與人物面板

- `Tab / I` 可開關人物裝備面板。
- 面板顯示目前左鍵行動、近戰、遠程、護甲、工具、背包與屬性加成。
- 開啟人物面板時，底部快捷提示不應蓋住面板內容。
- `M` 可開關小地圖，`H` 可開關教學，`Esc` 可關閉所有面板。

## NPC 與對話

- 靠近 NPC 才顯示 `E` 互動提示。
- 按 `E` 會出現下方對話框。
- 離開 NPC 範圍時對話框立即關閉。
- 首次對話獎勵只給一次，重複對話不會重複領取。

## 四方向廢土

- 北門進入「紫晶裂隙」：紫色晶體感明顯，遠程敵人較多，Boss 區存在。
- 南門進入「廢鐵公路」：破柏油、砂黃路肩、鏽橘車骸與道路感明顯。
- 西門進入「毒沼排水區」：深綠毒泥、管線與毒池明顯。
- 東門進入「舊工廠外圍」：灰藍鋼板、橘色警示線、工業障礙物明顯，Boss 區存在。
- 四區看起來不能像同一張地圖換名字。

## 戰鬥與回饋

- 敵人移動時不是完全靜態。
- 敵人受擊會有震動、傷害數字、短暫血條、火花或污染液效果。
- Boss 有更大的血條與更明顯的受擊 / 死亡表現。
- 掉落物是高細節 icon，位置與地面不混淆。
- 場景切換不應再出現 physics callback 直接移除 CollisionObject 的錯誤。

## 視覺 Review

- 畫面不能整片單色；廢土應有砂黃、鏽橘、毒綠、紫晶、灰藍等分區對比。
- 地板不能像明顯棋盤格。
- 建築、NPC、敵人、掉落物、props 風格需接近圖二高細節廢土像素風。
- Y-sort 遮擋合理，玩家靠近建築與障礙物時不應出現嚴重穿插。
- UI 不遮擋玩家中心、NPC 對話或重要戰鬥區域。
