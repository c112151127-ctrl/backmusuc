# 廢土回收商 Vertical Slice v2.1 實作計畫

## 目前狀態

專案是 Godot 4.6.3 PC 版像素偽 3D vertical slice。核心流程已可驗證：標題畫面、村莊、冒險公會、四方向廢土、戰鬥、掉落、任務、人物裝備面板、存讀檔與自動驗證 runner。

本輪 v2.1 針對使用者回饋修正三個重點：

1. 主角不能是小箱型機器人，改成圖二風格的人形仿真回收機 R-17。
2. A / D 視角與素材 row 必須和程式方向索引一致。
3. 廢土背景不能單色單調，四區要有荒野對比色與清楚道路感。

## Vertical Slice 目標

玩家進入遊戲後可以選擇繼續或新遊戲。新遊戲會看到 R-17 背景導入，進入村莊後與 NPC 交談、接任務、開人物裝備面板，從四個出口前往不同廢土路線。廢土中能使用左鍵依目前裝備做近戰或射擊，怪物受擊會顯示血條、傷害數字與火花 / 污染液效果，玩家可撿取資源、回村存檔並延續進度。

## 必改檔案

- `scenes/player/Player.gd`
- `scripts/tools/build_robot_player_atlas.py`
- `assets/sprites/player/recycler_player_multiaction_8dir.png`
- `scripts/systems/WorldBackdrop.gd`
- `scenes/levels/wasteland/Wasteland.gd`
- `data/maps/wasteland_routes.json`
- `docs/PLAYTEST_CHECKLIST.md`
- `docs/SRS_TRACEABILITY.md`

## 玩家流程

1. 標題畫面顯示「繼續遊戲 / 新遊戲」。
2. 玩家使用 WASD 移動，A 往左、D 往右，角色朝向與動作一致。
3. 滑鼠左鍵依目前快捷裝備決定行動：近戰武器揮砍，遠程武器射擊。
4. 近戰與射擊都朝滑鼠方向，不再只依最後移動方向。
5. `Tab / I` 開人物裝備面板，面板中可確認目前左鍵行動與裝備。
6. `M` 開地圖，`H` 開教學，`E` 互動，`Esc` 關閉面板。

## NPC 與對話流程

- 玩家靠近 NPC 才顯示互動提示。
- `E` 開啟對話框，對話框位於下方安全區。
- 玩家離開 NPC 範圍時對話框自動關閉。
- NPC 首次對話獎勵只給一次，狀態寫入存檔。

## 互動與獎勵驗證

- 村莊 NPC：首次對話給基本資源或教學提示。
- 公會 NPC：接委託、完成條件、回報領獎。
- 廢土事件：處理一次後不可重複領取。
- 存檔：場景、路線、血量、資源、裝備、任務與 NPC 狀態都保存。

## 主角美術規格

- 主角為 R-17 人形仿真回收機，不使用小箱型 NPC 機器人作為正式玩家。
- atlas 路徑：`assets/sprites/player/recycler_player_multiaction_8dir.png`。
- 尺寸：7 動作 x 8 方向 x 3 frame，單 frame `48x56`，總尺寸 `1008x448`。
- 方向索引：`0=右`、`1=右下`、`2=下`、`3=左下`、`4=左`、`5=左上`、`6=上`、`7=右上`。
- 視覺特徵：廢土回收裝、金屬關節、青藍 visor、胸口能源核心、橘鏽色裝甲與高對比輪廓。

## 玩家動作規格

- `idle`：待機呼吸與機體微光。
- `walk`：三幀步伐，方向列與 WASD 一致。
- `shoot`：舉槍、後座、槍口火光。
- `draw_sword`：拔出回收刀的準備動作。
- `slash`：橘黃刀光與青藍能量弧線。
- `swap_tool`：工具切換能量脈衝。
- `interact`：掃描光點與互動手勢。

## 四區廢土視覺策略

- 南門廢鐵公路：破柏油、砂黃路肩、鏽橘車骸、彈藥箱。
- 西門毒沼排水區：深綠毒泥、黃綠棧道、管線、飛行怪。
- 北門紫晶裂隙：紫晶高光、灰藍裂岩、遠程怪、Boss 前哨。
- 東門舊工廠外圍：灰藍鋼板、橘色警示線、工業管線、機械敵人與 Boss。

## 驗證清單

- JSON 全部可解析。
- `build_robot_player_atlas.py` 可重新產生 player atlas。
- Godot headless 可載入。
- `PixelAssetBaker.tscn` 不覆蓋正式圖二風格素材。
- `ValidationRunner.tscn` 通過。
- `AutomatedPlaytestRunner.tscn` 通過。
- `VisualReviewRunner.tscn` 在 headless 下安全 skip 截圖，在視窗模式可輸出畫面。
- Computer Use 可用時擷取標題、村莊、人物面板、四區廢土與 Boss 畫面。

## 剩餘 TODO

- 補完整 NPC / 怪物逐格動畫 atlas。
- 補更多正式音樂與分敵人命中特效。
- 擴充更多手工事件與支線任務。
- 後續 Android 觸控 UI 仍暫緩，PC 版優先。
