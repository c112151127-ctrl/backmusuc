# 廢土回收商

Godot 4.6.3 製作的 PC 優先像素風偽 3D vertical slice。遊戲目標是讓玩家操作 R-17 回收機器人，在村莊整備、接取委託、前往四個廢土區探索戰鬥、撿取資源、切換裝備、升級維修並存讀檔。

目前狀態是可驗證的 release-candidate 試玩切片，不是完整商店版所有內容。後續協作者要以「保留可玩流程、逐步提高美術與音效精度」為準，不要重建專案或改 Godot 版本。

## 目前完成內容

- 主角改為全身 R-17 回收機器人，正式來源為 `docs/art_direction_reference_r17_full_body.png`。
- 玩家 atlas：`assets/sprites/player/recycler_player_multiaction_8dir.png`，尺寸 `4032x1024`，單格 `112x128`，9 動作、8 方向、每動作 4 幀。
- 玩家動作包含待機、走路、射擊、拔刀、揮砍、切換工具、互動、受擊與死亡。
- 左鍵會依目前裝備決定近戰或射擊，並搭配武器 overlay、揮砍弧光、槍口火光與音效。
- 村莊、公會與四方向廢土路線可切換；廢土路線包含不同地形、地標、敵人、Boss、掉落與回村出口。
- NPC 有靠近提示、對話框、頭像、一次性互動與離開範圍自動關閉。
- UI 包含 HUD、快捷列、人物裝備面板、教學、暫停選單、小地圖與全屏地圖。
- 戰鬥包含敵人血條、傷害數字、受擊震動、污染液 / 火花效果、死亡淡出與掉落物提示。
- 存檔使用 `user://save_game.json`，含 Base64 payload 與 checksum。
- 自動驗證入口包含 JSON 驗證、素材驗證、Godot headless、PixelAssetBaker、ValidationRunner、AutomatedPlaytestRunner 與 VisualReviewRunner。

## 如何遊玩

使用 Godot console 啟動：

```powershell
& 'C:\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe' --path 'C:\Code\Game\first-game'
```

建議用 Godot 編輯器開啟 `C:\Code\Game\first-game`，主場景已由 `project.godot` 指定。

## 操作

- `WASD`：移動。
- 滑鼠：瞄準。
- 滑鼠左鍵：依目前左手裝備執行近戰或射擊。
- `E`：互動 / 推進對話。
- `Tab` 或 `I`：人物裝備面板。
- `M`：小地圖 / 全屏地圖。
- `H`：教學。
- `1-4`：快捷裝備。
- `Esc`：暫停選單、關閉面板或退出對話。

## 主要資料夾

- `scenes/main`：主入口與流程。
- `scenes/player`：玩家場景。
- `scenes/levels/village`：村莊樞紐。
- `scenes/levels/guild`：冒險公會。
- `scenes/levels/wasteland`：四方向廢土路線。
- `scenes/tests`：Godot 驗證場景。
- `scripts/autoload`：GameState、SaveManager、SceneRouter、AudioManager。
- `scripts/components`：NPC、敵人、掉落物、世界物件、特效。
- `scripts/tools`：素材生成與驗證工具。
- `scripts/ui`：地圖 UI。
- `data/art`：正式素材 manifest 與玩家動畫 manifest。
- `data/maps`：NPC、任務、事件、廢土路線資料。
- `data/items`：裝備與合成資料。
- `data/enemies`：敵人資料。
- `assets/sprites`：正式遊戲 sprite。
- `assets/audio`：音效。
- `docs`：設計、驗證截圖、SRS 對照與交接文件。

## 正式美術管線

正式主角來源：

- `docs/art_direction_reference_r17_full_body.png`

正式 atlas：

- `assets/sprites/player/recycler_player_multiaction_8dir.png`

快速檢查圖：

- `docs/player_full_body_idle_preview.png`
- `docs/player_full_body_first_frame_x4.png`

產生與驗證：

```powershell
python scripts\tools\build_release_candidate_assets.py
python scripts\tools\verify_visual_assets.py
```

舊的 `generate_formal_visual_assets.py` 是早期 48x56 占位生成法，不應作為正式輸出。`build_robot_player_atlas.py` 已改成相容入口，會呼叫新的 release-candidate R-17 atlas 管線。

## 驗證

建議提交前至少跑：

```powershell
node -e "for (const f of ['data/maps/npcs.json','data/maps/events.json','data/maps/quests.json','data/maps/wasteland_routes.json','data/items/equipment.json','data/items/recipes.json','data/enemies/enemies.json','data/maps/wasteland_params.json','data/art/visual_assets.json','data/art/player_animation_manifest.json']) { JSON.parse(require('fs').readFileSync(f,'utf8')); } console.log('JSON OK')"
python scripts\tools\build_release_candidate_assets.py
python scripts\tools\verify_visual_assets.py
& 'C:\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe' --headless --path 'C:\Code\Game\first-game' --quit
& 'C:\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe' --headless --path 'C:\Code\Game\first-game' --scene 'res://scenes/tests/PixelAssetBaker.tscn'
& 'C:\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe' --headless --path 'C:\Code\Game\first-game' --scene 'res://scenes/tests/ValidationRunner.tscn'
& 'C:\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe' --headless --path 'C:\Code\Game\first-game' --scene 'res://scenes/tests/AutomatedPlaytestRunner.tscn'
```

視覺變更後再跑：

```powershell
& 'C:\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe' --path 'C:\Code\Game\first-game' --scene 'res://scenes/tests/VisualReviewRunner.tscn'
```

輸出截圖會放在 `docs/visual_review_*.png`。

## 協作注意事項

- 玩家可見文字、NPC 對話、任務、測試清單與交付文件使用繁體中文。
- 技術規劃、commit message 與內部實作註記可使用英文。
- 不要批量刪除檔案或資料夾。若需清理素材，只能一次刪除一個明確檔案路徑。
- 不要改 Godot 執行檔路徑、Godot 版本、autoload 結構或三個驗證 runner 的用途。
- 不要把舊版簡化幾何素材重新烘回正式圖。
- 新增正式美術時要同步更新 `data/art/visual_assets.json`。
- 新增裝備時要同步更新 `data/items/equipment.json` 與對應 icon / world drop / sfx 欄位。

## 已知風險

- 目前是可驗證試玩切片，不是完整商業 3A 成品。
- 部分角色、敵人與 NPC 動態仍靠 atlas、Tween、shader 或 overlay 補強，之後可再由人工逐格動畫精修。
- Godot 結束時曾出現 ObjectDB leaked warning，目前未阻塞 playable flow，但後續正式版應繼續追蹤。
