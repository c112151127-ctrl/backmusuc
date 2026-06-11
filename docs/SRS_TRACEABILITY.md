# SRS 對照表

| SRS / 設計需求 | 目前實作與驗證 |
| --- | --- |
| Godot 4.x 單機 2D Roguelike vertical slice | `project.godot` 使用 Godot 4.6.3。已具備村莊、公會、野外、戰鬥、掉落、任務、合成、存讀檔與自動測試。 |
| 像素風偽 3D / 2.5D | `WorldBackdrop.gd`、Y ordering、PNG 建築、NPC、障礙物、道路、裂痕、汙染斑與地表層次提供俯視 2.5D 感。 |
| 村莊據點 | `Village.gd` 配置鍛造、合成、補給、改裝、存檔、拆解、出口與 NPC。互動提示改為靠近才顯示，降低畫面混亂。 |
| 冒險公會 | `Guild.gd` 提供任務接取、獎勵交付、出城入口與公會 NPC。 |
| 野外探索 | `Wasteland.gd` 使用大型地圖、seed、資源點、事件點、冒險區域、敵人、Boss、障礙物與邊界，支援可重複探索。 |
| 地圖邊界 | 村莊、公會、野外皆建立 StaticBody2D 邊界，`Player.gd` 也會同步限制玩家位置與相機範圍。 |
| PC 鍵鼠操作 | `GameState._ensure_input_actions()` 設定 WASD、左鍵主要攻擊、右鍵遠程、Space 近戰、E 互動、I 裝備、M 小地圖、H 教學、F5/F9 存讀檔。 |
| 左鍵依裝備決定動作 | `GameState.active_attack_mode()` 會依目前快捷裝備判斷 melee 或 ranged；`Player.gd` 用此結果讓左鍵揮砍或射擊。 |
| 人物裝備介面 | `HUD.gd` 的 `InventoryPanel` / `equipment_panel` 顯示角色頭像、目前左鍵動作、近戰武器、遠程武器、護甲、工具、加成、任務、背包與資源數值。 |
| 教學指引 | HUD 底部顯示基本鍵位，`H` 可開關完整教學提示；NPC 對話也會引導補給、接任務、出村、存檔與探索。 |
| 對話框 | `GameState.dialogue_requested` 與 `HUD.gd` 的 `DialoguePanel` 顯示 NPC 名稱、身分與對話內容。 |
| NPC 一次性互動獎勵 | `data/maps/npcs.json` 設定獎勵；`GameState.talked_npcs` 防止重複領取。自動測試驗證鍛造師首次交談給彈藥。 |
| NPC 靠近才顯示 | `DialogueNpc.gd` 只在玩家進入互動範圍時顯示名稱、身分與交談提示。 |
| 玩家多角度像素圖 | `assets/sprites/player/recycler_player_multiaction_8dir.png` 為 7 動作 × 8 方向 × 3 frame atlas。 |
| 玩家動作狀態 | `Player.gd` 支援 `IDLE`、`WALK`、`SHOOT`、`DRAW_SWORD`、`SLASH`、`SWAP_TOOL`、`INTERACT`、`HIT`、`DEAD`。 |
| 近戰 / 遠程戰鬥 | 近戰依面向判定前方敵人；遠程消耗彈藥並透過 projectile pool 生成投射物。 |
| 敵人類型 | `data/enemies/enemies.json` 定義六種普通敵人與一名 Boss；`PixelArtFactory.gd` 產出更接近廢土污染風格的厚輪廓敵人圖像。 |
| Boss 戰 | `waste_titan` 作為廢土巨像 Boss 生成於晶化裂隙區，具備高血量、近身踩踏範圍、遠程污染彈與保證掉落。 |
| 敵人上限與投射物池 | `Wasteland.gd` 生成 30 名普通敵人與 1 名 Boss；`ProjectilePool.gd` 控制投射物池，維持壓力場景可測。 |
| 資源、裝備、配方 | `equipment.json`、`recipes.json`、`InventorySystem.gd` 與 `GameState.gd` 支援資源堆疊、合成與裝備顯示。掉落物使用 `recycler_item_icons.png`，具有廢鐵束、彈藥箱、異變核心與汙染晶核圖示，不再使用棋盤格。 |
| 安全切場景 | `SceneRouter.gd` 使用 deferred scene change，避免 physics callback 內直接切場景造成 CollisionObject 移除錯誤。 |
| 存讀檔與 checksum | `SaveManager.gd` 使用 `user://save_game.json`，包含 Base64 payload 與 SHA-256 checksum。 |
| 視覺素材 | `RuntimeAssetLoader.gd` 載入 PNG/WAV；`PixelAssetBaker.tscn` 可重新產生像素素材；`docs/art_direction_reference.png` 保存本輪 imagegen 美術方向參考。 |
| 音效與音樂 | `AudioManager.gd` 載入村莊、公會、野外音樂與攻擊、射擊、命中、死亡、互動、撿取音效。 |
| 自動驗證 | `ValidationRunner.tscn` 驗證資料、輸入、NPC、HUD、裝備與左鍵攻擊模式；`AutomatedPlaytestRunner.tscn` 驗證可玩流程。 |
| 視覺 Review | `VisualReviewRunner.tscn` 輸出村莊、公會、野外、野外道路、野外 Boss 區與人物裝備面板截圖，供人工確認畫面是否過亂、缺少道路感或重疊。 |

## 剩餘差距

- 目前已達可玩 vertical slice，但若以正式上市品質為目標，仍需專職美術重畫高品質角色、建築、敵人與 tileset。
- 裝備介面尚未完成正式 RPG 拖曳換裝操作，但已提供角色頭像、裝備卡、背包與主要數值。
- 野外已加入大型地圖、障礙、事件、冒險區域、Boss 與資源，但還需要更多非戰鬥玩法與場景變化。
- 對話框已可用，但尚未加入選項分支、任務接受確認與逐字動畫。
