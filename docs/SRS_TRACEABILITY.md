# SRS 對照表

| SRS / 設計需求 | 目前實作或驗證方式 |
| --- | --- |
| Godot 4.x 2D Roguelike vertical slice | `project.godot` 使用 Godot 4.6，主流程包含村莊、公會、廢土、戰鬥、資源、裝備、存讀檔。 |
| 像素風偽 3D / 2.5D | 村莊、公會、廢土使用 `WorldBackdrop.gd`、Y-Sort、建築與 props PNG，角色與物件以底部基準點排序，形成前後遮擋感。 |
| 地圖概念：村莊整備、公會接任務、廢土探索、回村強化 | `Village.gd`、`Guild.gd`、`Wasteland.gd` 已建立三場景切換與核心循環。 |
| PC 操作優先 | `GameState._ensure_input_actions()` 設定 WASD、滑鼠左鍵按住射擊、空白近戰、E 互動、I 背包、Q/1-4 快捷欄、M 小地圖、H 教學、F5/F9 存讀檔。 |
| 暫停手機 UI | `HUD.gd` 已移除手機方向鍵與手機動作按鈕；`ValidationRunner` 檢查 touch controls 不出現。 |
| 教學與玩家引導 | `HUD.gd` 初始顯示小型 PC 操作提示，H 可開啟完整教學；各場景 `GameState.notify` 顯示繁體中文流程提示。 |
| NPC 指引與一次性獎勵 | `data/maps/npcs.json` 提供 NPC 對話、首次獎勵與重複對話；`GameState.talked_npcs` 防止重複領獎。 |
| 每位 NPC 有美術圖 | `assets/sprites/npcs/*.png` 為鐵匠、商人、維修機器人、倖存者、公會櫃台、路線偵查員提供不同 PNG。 |
| 玩家多角度像素圖 | `assets/sprites/player/recycler_player_multiaction_8dir.png` 是 7 動作 x 8 方向 x 3 frame，單格 48x56，atlas 1008x448。 |
| 玩家動作狀態 | `Player.gd` 支援 `IDLE`、`WALK`、`SHOOT`、`DRAW_SWORD`、`SLASH`、`SWAP_TOOL`、`INTERACT`、`HIT`、`DEAD`。 |
| 射擊與近戰循環 | 滑鼠左鍵按住射擊消耗彈藥；空白鍵近戰可清場並觸發拔刀/砍擊動畫；敵人死亡掉落資源。 |
| 敵人種類與行為 | `data/enemies/enemies.json` 與 `Enemy.gd` 支援 6 種敵人與近戰、快速、遠程、重型、飛行、混合型行為。 |
| 敵人與子彈上限 | `Wasteland.gd` 生成 30 名敵人；`ProjectilePool.gd` 使用資料設定限制 200 顆子彈。 |
| 資源、裝備、合成、鍛造 | `data/items/equipment.json`、`data/items/recipes.json`、`GameState.gd`、`InventorySystem.gd` 支援撿取、堆疊、裝備、鍛造、合成與交易循環。 |
| 存檔與 checksum | `SaveManager.gd` 使用 `user://save_game.json`，包含 Base64 payload 與 SHA-256 checksum。 |
| 程序廢土地圖與 seed | `LevelGenerator.gd`、`Wasteland.gd` 使用 seed 產生資源點、事件點、敵人與 props。 |
| 音樂與音效 | `AudioManager.gd` 載入 `assets/audio/*.wav`，村莊、公會、廢土各有音樂，近戰、射擊、受擊、撿取、互動、死亡有音效。 |
| 美術 PNG runtime 載入 | `RuntimeAssetLoader.gd` 直接載入新生成 PNG/WAV，避免 Godot 尚未匯入 `.import` 時退回臨時 checker 素材。 |
| 可玩性驗證 | `ValidationRunner.tscn`、`AutomatedPlaytestRunner.tscn` 驗證資料、場景、NPC、任務、戰鬥、存讀檔、PC HUD 與玩家動畫。 |
| 視覺重疊檢查 | `VisualReviewRunner.tscn` 輸出 `docs/visual_review_village.png`、`docs/visual_review_guild.png`、`docs/visual_review_wasteland.png` 做畫面自我 review。 |

## 剩餘落差

- 目前美術為可用 vertical slice PNG，風格已比色塊更完整，但距離正式商業像素遊戲仍需要人工精修。
- 目前音效與音樂為本地生成 WAV，後續可替換成正式授權素材。
- Android 匯出與觸控 UI 已暫緩，需等 PC 端視覺與手感穩定後再補。
