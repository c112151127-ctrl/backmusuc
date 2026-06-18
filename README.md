# 廢土回收商

這是 Godot 4.6.3 製作的像素風偽 3D 單機 Roguelike vertical slice。玩家操作原創回收機器人 R-17，在村莊整備、接取公會任務、前往四個廢土路線探索戰鬥、撿取資源、切換裝備、升級維修並存讀檔。

目前專案重點是 PC 版可玩試玩片段，不啟用手機觸控 UI。所有玩家可見文字、NPC 對話、任務、教學與測試清單以繁體中文撰寫。

## 目前狀態

- 主角使用 `docs/art_direction_reference_r17_full_body.png` 作為正式 R-17 方向參考。
- 主角素材由 `scripts/tools/build_release_candidate_assets.py` 生成到拆分 PNG、action sheet 與整張 atlas。
- R-17 已支援 8 方向、每動作 8 幀：待機、走路、射擊、拔刀、揮砍、切換工具、互動、受擊、死亡。
- 左鍵會依目前裝備行動：近戰武器揮砍，遠程武器射擊。
- 玩家 body frame 不再烘入刀、槍或大型揮砍弧光；武器統一由 `assets/sprites/player/weapons/` overlay 呈現，降低重複手臂與裁切跑位問題。
- 武器 icon、世界掉落 icon 與玩家手持 overlay 已改為機械廢土風格。
- 公會任務資料已包含清剿、採集、探索、Boss 前哨、救援事件與破壞任務。
- 開場故事語音已加入 `assets/audio/voice_intro_story.wav`，背景音樂包含 intro、village、guild、wasteland；Edge TTS 男聲目前在本機測試會回傳 `NoAudioReceived`，不可覆蓋正式語音檔。
- 小地圖、人物面板、對話框、存檔、死亡重生、升級與四向廢土路線已在 vertical slice 中串接。

## 遊玩方式

```powershell
& 'C:\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe' --path 'C:\Code\Game\first-game'
```

也可以用 Godot 開啟 `C:\Code\Game\first-game\project.godot` 後執行主場景。

## 操作

- `WASD`：移動。
- 滑鼠：瞄準。
- 滑鼠左鍵：依目前裝備執行近戰或射擊。
- `1-4`：切換快捷裝備。
- `Tab` / `I`：人物裝備面板。
- `E`：互動 / 推進對話。
- `M`：小地圖 / 全螢幕地圖。
- `H`：教學。
- `Esc`：暫停選單、存檔、讀檔、返回標題或退出。

## 重要檔案

- `project.godot`：Godot 專案設定。
- `scenes/player/Player.gd`：玩家控制、狀態機、攻擊、瞄準與裝備動作。
- `scripts/tools/build_release_candidate_assets.py`：R-17、武器、物品、音效與音樂生成管線。
- `scripts/tools/verify_visual_assets.py`：素材、拆圖、方向、漂移、重複與亂碼檢查。
- `data/art/player_animation_manifest.json`：主角 atlas 與動作幀數契約。
- `data/art/visual_assets.json`：正式美術資產 manifest。
- `data/items/equipment.json`：裝備、武器 overlay、音效、掉落與屬性資料。
- `data/maps/quests.json`：公會任務與故事路線資料。
- `docs/player_split_frame_diagnostic.png`：主角方向與動作診斷圖。
- `docs/PLAYTEST_CHECKLIST.md`：人工遊玩驗收清單。
- `docs/SRS_TRACEABILITY.md`：SRS 對照表。

## 重建素材

```powershell
python scripts\tools\build_release_candidate_assets.py
python scripts\tools\verify_visual_assets.py
```

輸出重點：

- 拆分幀：`assets/sprites/player/frames/`
- 每動作 sheet：`assets/sprites/player/actions/`
- 主角 atlas：`assets/sprites/player/recycler_player_multiaction_8dir.png`
- 裝備 icon：`assets/sprites/items/`
- 武器 overlay：`assets/sprites/player/weapons/`
- 診斷圖：`docs/player_split_frame_diagnostic.png`
- 玩家動作 review 拼接圖：`docs/visual_review_action_montage.png`

## 驗證

```powershell
node -e "for (const f of ['data/maps/npcs.json','data/maps/events.json','data/maps/quests.json','data/maps/wasteland_routes.json','data/items/equipment.json','data/items/recipes.json','data/enemies/enemies.json','data/maps/wasteland_params.json','data/art/visual_assets.json','data/art/player_animation_manifest.json']) { JSON.parse(require('fs').readFileSync(f,'utf8')); } console.log('JSON OK')"
python scripts\tools\verify_visual_assets.py
& 'C:\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe' --headless --path 'C:\Code\Game\first-game' --quit
& 'C:\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe' --headless --path 'C:\Code\Game\first-game' --scene 'res://scenes/tests/PixelAssetBaker.tscn'
& 'C:\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe' --headless --path 'C:\Code\Game\first-game' --scene 'res://scenes/tests/ValidationRunner.tscn'
& 'C:\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe' --headless --path 'C:\Code\Game\first-game' --scene 'res://scenes/tests/AutomatedPlaytestRunner.tscn'
& 'C:\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe' --headless --path 'C:\Code\Game\first-game' --scene 'res://scenes/tests/PerformanceRunner.tscn'
```

視覺截圖驗證：

```powershell
& 'C:\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe' --headless --path 'C:\Code\Game\first-game' --scene 'res://scenes/tests/VisualReviewRunner.tscn'
```

視覺 runner 會更新 `docs/visual_review_*.png`。

效能 runner 會更新 `docs/performance_report.json`，目前壓測內容是 30 個敵人節點與 200 顆池化子彈的 projectile pool 壓力樣本。

## 協作規則

- 不要批量刪除檔案或資料夾。
- 不要提交 `.env`、token、credentials、cache、匯出成品或 build artifacts。
- 每次完成可驗證更新後都要 commit。
- commit message 使用英文。
- 不要改掉 Godot 版本、autoload 架構、主流程場景與驗證 runner。
- Planning alone is not completion. 實作任務必須檢查、規劃、執行、驗證、修正明顯問題、commit 並回報結果。
