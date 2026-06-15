# 廢土回收商

Godot 4.6.3 製作的像素風偽 3D 單機 Roguelike vertical slice。玩家操作 R-17 回收機器人，在村莊整備、接取委託、進入四個廢土路線探索戰鬥、撿取資源與裝備、回村升級並存讀檔。

## 目前狀態

- 主角 R-17 以 `docs/art_direction_reference_r17_full_body.png` 作為正式美術參考。
- Godot runtime 優先載入拆分後的獨立 PNG 幀：`assets/sprites/player/frames/<action>/dir_<n>/frame_<n>.png`。
- `assets/sprites/player/recycler_player_multiaction_8dir.png` 仍保留為相容用 atlas 與預覽用途，不再是唯一動畫來源。
- 動作包含 idle、walk、shoot、draw_sword、slash、swap_tool、interact、hit、dead。
- 武器 icon / overlay 會優先從 R-17 高細節參考圖裁切，不再使用簡化積木風格作為正式輸出。
- 敵人除資源掉落外，已加入稀有武器與裝備掉落表。
- PC 版優先，手機觸控 UI 暫緩。

## 遊玩方式

```powershell
& 'C:\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe' --path 'C:\Code\Game\first-game'
```

或用 Godot 開啟 `C:\Code\Game\first-game\project.godot` 後執行主場景。

## 操作

- `WASD`：移動。
- 滑鼠左鍵：依目前裝備行動，近戰武器揮砍，遠程武器射擊。
- `1-4`：切換快捷裝備。
- `Tab` / `I`：人物裝備面板。
- `E`：互動 / 對話。
- `M`：小地圖 / 全螢幕地圖。
- `H`：教學。
- `Esc`：暫停選單。

## 重要檔案

- `scenes/player/Player.gd`：玩家控制、攻擊、動畫載入。
- `scripts/tools/build_release_candidate_assets.py`：正式 R-17、美術、音效與 manifest 生成器。
- `data/art/player_animation_manifest.json`：玩家動畫規格。
- `data/art/visual_assets.json`：正式美術 manifest。
- `data/items/equipment.json`：裝備資料、icon、武器 overlay、音效與攻擊特效。
- `data/enemies/enemies.json`：敵人資料、資源掉落與稀有裝備掉落。
- `docs/player_split_frame_diagnostic.png`：玩家拆分幀檢查圖。
- `docs/PLAYTEST_CHECKLIST.md`：人工測試清單。
- `docs/SRS_TRACEABILITY.md`：SRS 對照。

## 重新生成美術與音效

```powershell
python scripts\tools\build_release_candidate_assets.py
python scripts\tools\verify_visual_assets.py
```

生成器會輸出：

- 拆分幀：`assets/sprites/player/frames/`
- 動作檢查 sheet：`assets/sprites/player/actions/`
- 相容 atlas：`assets/sprites/player/recycler_player_multiaction_8dir.png`
- 裝備 icon：`assets/sprites/items/`
- 武器 overlay：`assets/sprites/player/weapons/`
- 診斷圖：`docs/player_split_frame_diagnostic.png`

## 驗證

```powershell
node -e "for (const f of ['data/maps/npcs.json','data/maps/events.json','data/maps/quests.json','data/maps/wasteland_routes.json','data/items/equipment.json','data/items/recipes.json','data/enemies/enemies.json','data/maps/wasteland_params.json','data/art/visual_assets.json','data/art/player_animation_manifest.json']) { JSON.parse(require('fs').readFileSync(f,'utf8')); } console.log('JSON OK')"
python scripts\tools\verify_visual_assets.py
& 'C:\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe' --headless --path 'C:\Code\Game\first-game' --quit
& 'C:\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe' --headless --path 'C:\Code\Game\first-game' --scene 'res://scenes/tests/PixelAssetBaker.tscn'
& 'C:\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe' --headless --path 'C:\Code\Game\first-game' --scene 'res://scenes/tests/ValidationRunner.tscn'
& 'C:\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe' --headless --path 'C:\Code\Game\first-game' --scene 'res://scenes/tests/AutomatedPlaytestRunner.tscn'
```

視覺截圖：

```powershell
& 'C:\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe' --path 'C:\Code\Game\first-game' --scene 'res://scenes/tests/VisualReviewRunner.tscn'
```

截圖會輸出到 `docs/visual_review_*.png`。

## 協作規則

- 不要批量刪除檔案或資料夾。
- 每次可驗證更新後都要 commit。
- 玩家可見文字與文件使用繁體中文。
- 技術實作與 commit message 使用英文。
- 不改 Godot 版本、不重建專案、不移除既有驗證 runner。
