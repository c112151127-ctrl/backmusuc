# 廢土回收商實作計畫

## 目前專案狀態

本專案是 Godot 4.6.3 的像素風偽 3D PC vertical slice。核心流程已包含村莊、公會、四方向廢土、敵人、Boss、資源、裝備、存檔、人物面板、地圖、對話與驗證 runner。

本輪修正重點是主角與武器動畫管線。先前 runtime 主要依賴整張 `recycler_player_multiaction_8dir.png` atlas 切格，容易因邊界或動作 overlay 導致角色被切掉、左右方向錯誤或多出漂浮手臂。新方案改為優先載入獨立 PNG 幀，atlas 僅保留相容與預覽用途。

## Vertical Slice 目標

玩家進入遊戲後應能：

1. 操作 R-17 在村莊移動。
2. 靠近 NPC 取得提示並開啟對話。
3. 用 `Tab` 開人物裝備面板並切換裝備。
4. 從村莊四方向進入不同廢土路線。
5. 依目前裝備使用滑鼠左鍵近戰或射擊。
6. 擊敗敵人後撿取資源，並有低機率取得武器或工具。
7. 回村完成委託、升級、存檔。

## 本輪必要修改檔案

- `scripts/tools/build_release_candidate_assets.py`
- `scenes/player/Player.gd`
- `scripts/components/Enemy.gd`
- `scripts/tests/VerticalSliceVerifier.gd`
- `scripts/tools/verify_visual_assets.py`
- `data/enemies/enemies.json`
- `data/art/player_animation_manifest.json`
- `README.md`
- `docs/PLAYTEST_CHECKLIST.md`

## 玩家動畫規格

正式 runtime 來源：

```text
assets/sprites/player/frames/<action>/dir_<direction>/frame_<frame>.png
```

每格固定：

- 尺寸：`112x128`
- 方向：8 方向
- 每動作幀數：4 幀
- 動作：`idle`、`walk`、`shoot`、`draw_sword`、`slash`、`swap_tool`、`interact`、`hit`、`dead`

輔助輸出：

- `assets/sprites/player/actions/<action>.png`：每個動作一張檢查 sheet。
- `assets/sprites/player/recycler_player_multiaction_8dir.png`：相容 atlas。
- `docs/player_split_frame_diagnostic.png`：人工 review 用診斷圖。

## 武器與攻擊規格

- 近戰武器：鏽蝕回收刀、火花切割斧、重型拆解槌。
- 遠程武器：管線釘槍、線圈步槍、酸蝕噴射器。
- 工具：回收商手套、磁吸拆解器。
- 武器 icon / overlay 優先從 `docs/art_direction_reference_r17_full_body.png` 的高細節武器模組裁切。
- 若參考圖缺少特定武器，才用同風格鏽蝕金屬、青色能量、厚輪廓方式補繪。
- 滑鼠左鍵依目前快捷裝備決定行為：近戰揮砍、遠程射擊、工具互動。

## 敵人掉落規格

敵人保留原本資源掉落，新增 `rare_drop_table`：

- 小怪低機率掉落對應武器或工具。
- Boss 可掉高階裝備。
- 掉落物使用 `equipment.json` / `visual_assets.json` 的正式 icon，不使用簡化方塊。

## NPC 指引流程

- 玩家靠近 NPC 才顯示 `E` 互動提示。
- 按 `E` 開啟對話框，顯示 NPC 頭像、名稱、職業與繁體中文對話。
- 離開 NPC 範圍時自動關閉對話。
- NPC 一次性獎勵透過存檔紀錄，不能重複領取。

## 驗證清單

1. JSON 全部可解析。
2. `build_release_candidate_assets.py` 可重新生成拆分幀、動作 sheet、atlas、icon、overlay、音效。
3. `verify_visual_assets.py` 檢查拆分幀尺寸、非空白、左右方向一致、manifest 完整。
4. Godot headless 可載入專案。
5. `PixelAssetBaker.tscn`、`ValidationRunner.tscn`、`AutomatedPlaytestRunner.tscn` 通過。
6. `VisualReviewRunner.tscn` 輸出截圖後人工確認畫面。
7. `docs/player_split_frame_diagnostic.png` 中不可出現額外手臂、切邊或左右反向。

## 剩餘 TODO

- 補更多真正逐格 NPC / 敵人 / Boss 動畫。
- 增加更多路線事件、精英戰與長線任務。
- 做更完整的音樂混音與音效層次。
- 做長時間 QA、效能 profiling、Steam build/export 測試。
