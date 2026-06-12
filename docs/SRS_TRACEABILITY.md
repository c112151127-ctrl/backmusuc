# SRS Traceability 對照表

| SRS / 設計需求 | 目前實作對應 |
| --- | --- |
| Godot 4.x 2D Roguelike vertical slice | `project.godot` 使用 Godot 4.6.3，主流程包含村莊、公會、廢土探索、戰鬥、掉落、任務、裝備與存檔。 |
| 像素風偽 3D / 2.5D | `WorldBackdrop.gd`、Y-sort、建築 / props PNG、道路與地形色調提供 2.5D 層次。 |
| 主角是回收機器人 | `assets/sprites/player/recycler_player_multiaction_8dir.png` 以 R-17 機器人為玩家 atlas，`HUD.gd` 人物面板顯示 R-17。 |
| 玩家多方向與多動作 | `Player.gd` 使用 `AnimatedSprite2D`，支援 idle、walk、shoot、draw_sword、slash、swap_tool、interact 等動作與 8 方向。 |
| PC 操作 | `GameState._ensure_input_actions()` 註冊 WASD、滑鼠左鍵、右鍵、Space、E、Tab/I、M、H、F5/F9、Q、1-4。 |
| 左鍵依裝備行動 | `GameState.active_attack_mode()` 與 `Player._primary_attack_pressed()` 會依快捷欄目前裝備決定近戰或射擊。 |
| 村莊據點 | `Village.gd` 包含鍛造、合成、商店、改裝、拆解、存檔、公會入口與四方向廢土出口。 |
| 冒險公會 | `Guild.gd` 提供委託板、獎勵交付、前往廢土與返回村莊。 |
| 多張廢土地圖 | `data/maps/wasteland_routes.json` 定義四條路線，`Wasteland.gd` 依 route id 生成不同敵人、資源、地標與 Boss 狀態。 |
| 明顯道路與障礙物 | `WorldBackdrop.gd` 依路線生成不同道路配置；`Wasteland.gd` 生成車骸、毒池、牆、路障、枯樹、訊號塔等。 |
| NPC 指引 | `data/maps/npcs.json` 提供繁中 NPC 對話；`DialogueNpc.gd` 靠近才顯示提示，離開自動關閉對話。 |
| NPC 一次性獎勵 | `GameState.talk_to_npc()` 用 `talked_npcs` 記錄首次交談，避免重複領獎，並寫入存檔。 |
| 對話框 | `HUD.gd` 建立正式對話面板，顯示 NPC 名稱、職業、文字與操作提示。 |
| 人物裝備面板 | `HUD.gd` 的 `InventoryPanel` 顯示 R-17、目前左鍵行動、近戰、遠程、護甲、工具、背包與屬性加成。 |
| 裝備與背包 | `equipment.json`、`recipes.json`、`InventorySystem.gd`、`GameState.gd` 支援撿取、堆疊、穿戴、快捷欄與配方。 |
| 武器多樣性 | 裝備資料包含鏽蝕回收刀、火花切割斧、重型拆解槌、管線釘槍、線圈步槍、酸蝕噴射器、護甲與工具。 |
| 近戰 / 遠程戰鬥循環 | 近戰可清敵並回收彈藥，遠程消耗彈藥處理距離威脅，`ProjectilePool.gd` 控制投射物上限。 |
| 敵人類型 | `enemies.json` 定義近戰、快速、遠程、重型、飛行、混合型與 Boss。 |
| 敵人動態與受擊回饋 | `Enemy.gd` 加入呼吸、翻面、受擊震動、血條、傷害數字、污染液 / 火花效果與死亡淡出。 |
| Boss | `waste_titan` 作為 Boss，Boss 路線會生成，受擊與死亡有明顯回饋。 |
| 掉落物美術 | `Pickup.gd` 使用高細節 item atlas，掉落物有漂浮動畫與繁中撿取提示。 |
| 任務系統 | `quests.json` 包含四份路線委託，涵蓋擊殺、收集、回村交付與裝備獎勵。 |
| 存檔 / 讀檔 | `SaveManager.gd` 使用 `user://save_game.json`，Base64 payload + SHA-256 checksum，支援 `has_save()`、`load_or_new()`。 |
| 關閉後繼續進度 | `Main.gd` 啟動時顯示繼續 / 新遊戲選單，存檔包含場景、路線、位置、背包、裝備、NPC、任務與 intro 狀態。 |
| 場景切換安全 | `SceneRouter.gd` 使用 deferred scene change，避免 physics callback 直接移除 CollisionObject。 |
| 開場故事導入 | `Main.gd` 新遊戲顯示 R-17 背景故事與操作導入。 |
| 自動驗證 | `ValidationRunner.tscn`、`AutomatedPlaytestRunner.tscn`、`VisualReviewRunner.tscn` 驗證資料、場景、戰鬥、UI 與視覺截圖。 |

## 仍待補強

- 目前 NPC / 敵人以高細節單張 PNG 加上程式動態為主，後續應補完整逐格動畫 atlas。
- 地形已分路線色調與道路，但仍可補更多手繪 tileset 變化。
- 音樂與音效已有入口，但正式商業版仍需更多分場景 BGM 與打擊音效。
- 路線事件已保存 discovered events，但一般資源節點與敵人重生仍需更細緻的持久化設計。
