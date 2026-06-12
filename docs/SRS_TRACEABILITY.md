# SRS Traceability 對照表

| SRS / 設計需求 | 目前實作對照 |
| --- | --- |
| Godot 4.x 2D Roguelike vertical slice | `project.godot` 使用 Godot 4.6.3，流程包含標題、村莊、公會、廢土、戰鬥、資源、任務、裝備與存檔。 |
| 像素風偽 3D / 2.5D | `WorldBackdrop.gd`、Y-sort、建築 / props PNG、道路與地形色彩提供偽 3D 層次。 |
| 主角是回收機器人 | `recycler_player_multiaction_8dir.png` 已改為圖二風格的人形仿真回收機 R-17，而不是小箱型 NPC 機器人。 |
| 玩家 8 方向 | `Player.gd` 方向索引統一為 `0=右`、`1=右下`、`2=下`、`3=左下`、`4=左`、`5=左上`、`6=上`、`7=右上`。 |
| 玩家多動作 | `Player.gd` 使用 `AnimatedSprite2D`，支援 idle、walk、shoot、draw_sword、slash、swap_tool、interact。 |
| PC 操作 | `GameState._ensure_input_actions()` 註冊 WASD、滑鼠左鍵、右鍵、Space、E、Tab/I、M、H、F5/F9、Q、1-4。 |
| 左鍵依裝備行動 | `GameState.active_attack_mode()` 與 `Player._primary_attack_pressed()` 依目前快捷裝備決定近戰或射擊。 |
| 滑鼠瞄準 | `Player._aim_direction()` 讓近戰與射擊都朝滑鼠方向，不只依最後移動方向。 |
| 村莊據點 | `Village.gd` 包含鍛造、合成、商店、改裝、拆解、存檔、公會入口與四方向廢土出口。 |
| 冒險公會 | `Guild.gd` 支援接委託、查看目標、交付獎勵與前往廢土。 |
| 四方向廢土 | `data/maps/wasteland_routes.json` 定義北、南、西、東四條路線，`Wasteland.gd` 依 route id 生成不同地標、資源、敵人與 Boss。 |
| 地圖不單調 | `WorldBackdrop.gd` 為四區加入砂黃、鏽橘、毒綠、紫晶、灰藍等路線色彩，並混合道路、斑塊與污漬。 |
| NPC 對話 | `data/maps/npcs.json` 管理 NPC 文本，`DialogueNpc.gd` 負責靠近提示、對話與離開關閉。 |
| NPC 一次性獎勵 | `GameState.talk_to_npc()` 與 `talked_npcs` 保存首次對話獎勵狀態。 |
| 對話框 | `HUD.gd` 顯示正式對話面板、NPC 名稱、職業、文字與按鍵提示。 |
| 人物裝備面板 | `HUD.gd` 的 `InventoryPanel` 顯示 R-17、目前左鍵行動、近戰、遠程、護甲、工具、背包與屬性加成。 |
| 裝備與背包 | `equipment.json`、`recipes.json`、`InventorySystem.gd`、`GameState.gd` 支援撿取、堆疊、穿戴、快捷欄與配方。 |
| 武器多樣性 | 裝備資料包含鏽蝕回收刀、火花切割斧、重型拆解槌、管線釘槍、線圈步槍、酸蝕噴射器、護甲與工具。 |
| 近戰 / 遠程循環 | 近戰能清空間，遠程消耗彈藥；彈藥不足會提示回村補給或用近戰處理。 |
| 敵人類型 | `enemies.json` 定義近戰、快速、遠程、重型、飛行、混合型與 Boss。 |
| 戰鬥回饋 | `Enemy.gd`、`DamagePopup.gd`、`EnemyHealthBar.gd`、`HitEffect.gd` 顯示傷害數字、血條、受擊震動、火花 / 污染液效果。 |
| Boss | `waste_titan` 為 Boss，Boss 路線會生成 Boss 並顯示較大的血條與掉落。 |
| 掉落物 | `Pickup.gd` 使用高細節 item atlas，掉落資源與裝備可撿取並顯示提示。 |
| 任務 | `quests.json` 包含擊殺、收集、探索與 Boss / 精英相關委託。 |
| 存檔 / 讀檔 | `SaveManager.gd` 使用 `user://save_game.json`，Base64 payload + SHA-256 checksum，支援 `has_save()`、`load_or_new()`。 |
| 開場故事 | `Main.gd` 新遊戲顯示 R-17 重啟背景與基本操作導入。 |
| 場景切換安全 | `SceneRouter.gd` 使用 deferred scene change，避免 physics callback 直接移除 CollisionObject。 |
| 自動驗證 | `ValidationRunner.tscn`、`AutomatedPlaytestRunner.tscn`、`VisualReviewRunner.tscn` 驗證資料、場景、戰鬥、UI 與視覺 review 流程。 |

## 已知剩餘差距

- NPC / 怪物仍以高細節單張 PNG 加程式動態為主，完整逐格動畫 atlas 仍需後續補齊。
- 音效已有入口與基礎素材，但正式商業版仍需要更多分場景 BGM、不同武器命中音與 Boss 音效。
- 廢土已有四區色彩與地標差異，後續可再加入更多手工事件、稀有房間與路線分支。
