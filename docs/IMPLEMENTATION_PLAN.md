# 廢土回收商美術與地圖系統重製實作計畫

## 目前狀態

本專案是 Godot 4.6.3 PC 版像素風偽 3D vertical slice。核心流程已保留並可驗證：標題畫面、村莊整備、冒險公會、四方向廢土探索、戰鬥、掉落、任務、人物裝備面板、小地圖 / 全屏地圖、存讀檔與自動 playtest runner。

本輪重點不是微調舊占位素材，而是建立正式素材管線與可驗收的地圖系統：

1. 主角改為原創 R-17 回收機器人，避免人類角色和機器人外殼重疊。
2. 命名 NPC、建築、裝備、掉落物、敵人與 Boss 都由 `data/art/visual_assets.json` 宣告正式素材。
3. 地板移除明顯網格感，改成不規則石板、荒土、破柏油、毒泥與晶體地形混鋪。
4. 小地圖與全屏地圖改為從場景中的 map groups 讀取玩家、NPC、建築、敵人、Boss、掉落物、事件與出口位置。

## Vertical Slice 目標

玩家啟動遊戲後可選擇繼續或新遊戲。新遊戲會看到 R-17 在廢土村莊甦醒的背景導入，之後在村莊向 NPC 取得指引與一次性獎勵，前往公會接委託，再由村莊四方向出口進入不同廢土區。玩家可使用滑鼠左鍵依目前裝備進行近戰或射擊、撿取掉落物、查看人物裝備、開啟地圖、完成任務並存檔。

## 已修改的主要檔案

- `data/art/visual_assets.json`
- `data/items/equipment.json`
- `data/items/recipes.json`
- `data/maps/npcs.json`
- `data/maps/quests.json`
- `data/maps/events.json`
- `data/maps/wasteland_routes.json`
- `data/enemies/enemies.json`
- `scripts/tools/build_release_candidate_assets.py`
- `scripts/tools/build_robot_player_atlas.py`（相容入口，會呼叫正式 release-candidate atlas 管線）
- `scripts/tools/verify_visual_assets.py`
- `scripts/ui/WorldMapView.gd`
- `scripts/ui/MiniMapView.gd`
- `scenes/ui/HUD.gd`
- `scenes/player/Player.gd`
- `scenes/levels/village/Village.gd`
- `scenes/levels/guild/Guild.gd`
- `scenes/levels/wasteland/Wasteland.gd`
- `scripts/components/DialogueNpc.gd`
- `scripts/components/Pickup.gd`
- `scripts/components/Enemy.gd`
- `scripts/components/WorldProp.gd`
- `scripts/systems/WorldBackdrop.gd`

## 玩家流程

1. 進入標題畫面，若有存檔可選「繼續遊戲」，否則開始新遊戲。
2. 新遊戲播放短篇背景導入：R-17 在廢土村莊維修艙甦醒，接受清理污染與回收資源任務。
3. 在村莊使用 WASD 移動，靠近 NPC 才顯示互動提示。
4. 使用 `E` 對話、取得一次性獎勵與玩法指引。
5. 前往公會接委託，或從村莊上下左右四個出口進入不同廢土路線。
6. 在廢土中打怪、撿資源、觀察小地圖、切換裝備。
7. 回村交付任務、合成裝備、存檔，形成「探索、戰鬥、回收、強化、再探索」循環。

## NPC 指引流程

- 鍛造老陳：介紹近戰清空間、補彈與鍛造用途。
- 補給商阿洛：介紹資源、彈藥與購買補給。
- 維修機 R-17：介紹存檔、維修與系統狀態。
- 倖存者小隊長：介紹四方向廢土路線與地圖功能。
- 公會櫃員：介紹委託接取與交付。
- 路線斥候：介紹各區敵人、資源與 Boss 風險。

NPC 離開互動範圍時會自動關閉對話框，避免對話殘留遮住畫面。

## 一次性互動與獎勵驗證

NPC 對話透過 `GameState.talk_to_npc()` 記錄 `talked_npcs`。第一次對話給予獎勵並寫入存檔，之後只顯示 repeat line，不會重複領取。`ValidationRunner.tscn` 與 `AutomatedPlaytestRunner.tscn` 會驗證一次性獎勵行為。

## 像素主角規格

- 正式主角：原創 R-17 回收機器人。
- 造型方向：白灰陶瓷外殼、青色感測眼、圓潤身軀、長臂、荒野刮痕、回收工具掛件。
- 限制：只能參考「圓潤、自然磨損、友善仿生機器人」方向，不直接複製任何電影角色。
- Atlas：`assets/sprites/player/recycler_player_multiaction_8dir.png`
- 單格尺寸：`112x128`
- 排列：9 動作 x 8 方向 x 4 frame，總尺寸 `4032x1024`
- 正式參考圖：`docs/art_direction_reference_r17_full_body.png`
- 方向 row：下、右下、右、右上、上、左上、左、左下。

## 玩家動作狀態

- `idle`：待機呼吸、感測眼微亮。
- `walk`：八方向移動，A / D 視角與動畫方向一致。
- `draw_sword`：近戰前先拔出回收刀。
- `slash`：揮砍弧光與工具殘影。
- `shoot`：舉槍、後座力、槍口光。
- `swap_tool`：手臂工具亮起或切換姿態。
- `interact`：面向互動目標，手臂伸出。
- `hit`：受擊閃光與短暫震動。
- `dead`：機體停擺後回村維修。

## 地圖與小地圖規格

- 村莊：十字樞紐、中央廣場、四方向出口、功能建築分區、NPC 站位互不重疊。
- 南門廢鐵公路：破柏油、車骸、路障、彈藥箱。
- 西門毒沼排水區：毒池、管線、飛行敵人與毒液資源。
- 北門紫晶裂隙：紫晶礦脈、裂谷、遠程敵人與 Boss 前哨。
- 東門舊工廠外圍：鐵板、警戒線、工業建物、機械敵人與精英事件。
- `WorldMapView.gd` 讀取 `map_player`、`map_npc`、`map_station`、`map_gate`、`map_pickup`、`map_enemy`、`map_boss`、`map_prop`、`map_event`。
- 小地圖顯示目前位置與附近物件；按 `M` 或點擊小地圖可切換全屏地圖。

## 驗證清單

- JSON 驗證：NPC、任務、事件、路線、裝備、配方、敵人與 visual assets 都必須可解析。
- 素材驗證：`scripts/tools/verify_visual_assets.py` 檢查缺圖、透明空圖、重複 hash、prop 變體與 mojibake sentinel。
- Godot 驗證：headless 載入、`PixelAssetBaker.tscn`、`ValidationRunner.tscn`、`AutomatedPlaytestRunner.tscn`。
- 視覺驗證：`VisualReviewRunner.tscn` 或 Computer Use 實機 review 村莊、四路線、人物面板、小地圖、全屏地圖、戰鬥與 Boss 區。

## 剩餘 TODO

- 補完整逐格 NPC 工作動畫、怪物攻擊動畫與 Boss 階段動畫。
- 補正式 BGM、命中音效、UI 音效與音量混音。
- 擴充更多任務事件、地牢節點與 Boss 招式。
- 後續由人工美術再精修像素邊緣、光影一致性與角色辨識度。
