# SRS 對照表

| SRS / 設計要求 | 目前證據 |
| --- | --- |
| Godot 4.x 單機 2D Roguelike | `project.godot` 使用 Godot 4.6，主場景進入村莊、野外與公會流程。 |
| Windows / Android 匯出規劃 | `export_presets.cfg` 已提供 Windows Desktop 與 Android preset；`docs/EXPORT_READINESS.md` 記錄目前本機缺少的 export templates 與 Android 工具鏈。 |
| PC WASD + 滑鼠操作 | `GameState._ensure_input_actions()` 註冊 WASD、滑鼠、近戰、遠程、互動、背包、存檔、讀檔、`Q` 與 `1`-`4` 快捷欄。 |
| Android 觸控 UI 基礎 | `scenes/ui/HUD.gd` 提供左下方向 D-pad，以及右下近戰、射擊、切換、互動、背包、存檔按鈕。 |
| 撿取與裝備管理 | `scripts/components/Pickup.gd`、`GameState.inventory/equipment/quick_slots`、`HUD.gd` 背包、裝備、快捷欄與委託進度。 |
| 隨時存檔 JSON | `scripts/autoload/SaveManager.gd` 寫入 `user://save_game.json`。 |
| Base64 / hash 驗證 | `SaveManager.gd` 使用 Base64 payload + SHA-256 checksum。 |
| 程序化野外地圖 | `Wasteland.gd` 使用 seed 生成資源、事件與敵人位置；事件資料在 `data/maps/events.json`。 |
| 偽 3D 地圖層次 | `WorldProp.gd` 與 `Wasteland.gd` 依 seed 生成岩石、枯樹、殘骸、毒池、訊號塔等 Y-Sort prop；阻擋型 prop 有 `CollisionShape2D`。 |
| 村莊功能點 | `Village.gd` 實作鍛造、合成、交易、改裝、拆解、存檔、野外入口與公會入口；配方資料在 `data/items/recipes.json`。 |
| 冒險公會 | `Guild.gd` 實作接取委託、前往廢土與交付獎勵；委託資料在 `data/maps/quests.json`。 |
| 任務存檔 | `GameState.gd` 會保存 active quest、completed quests 與 quest progress，`SaveManager.gd` 會一起寫入 Base64/checksum 存檔。 |
| NPC 對話與導引 | `data/maps/npcs.json` 定義村莊與公會 NPC；`DialogueNpc.gd` 生成可交談角色，`GameState.talked_npcs` 保存一次性對話獎勵狀態。 |
| 混合戰鬥系統 | `Player.gd` 實作近戰與遠程；敵人與投射物腳本可互動。 |
| 敵人攻擊模式 | `data/enemies/enemies.json` 定義 6 種 `attack_pattern`；`Enemy.gd` 實作追擊、短衝、遠程污染彈、重型大範圍近戰、飛行繞行與混合型行為。 |
| 敵人上限 30、子彈上限 200 | `Wasteland.gd` 生成 30 敵人；`ProjectilePool.gd` 依 `data/maps/wasteland_params.json` 執行 200 子彈硬上限。 |
| 像素偽 3D / Y-Sort | 主要場景與玩家節點開啟 `y_sort_enabled`，素材採 32px 像素風。 |
| 多角度 / 多動作玩家素材 | `Player.gd` 以 `AnimatedSprite2D` 建立 `idle/walk/shoot/draw_sword/slash/swap_tool/interact` x 8 方向 x 3 frame；優先讀取 `assets/sprites/player/recycler_player_multiaction_8dir.png` baked atlas，並保留執行期 fallback。 |
| 玩家動作狀態 | `Player.gd` 狀態機可進入 `IDLE`、`WALK`、`SHOOT`、`DRAW_SWORD`、`SLASH`、`SWAP_TOOL`、`INTERACT`、`HIT`、`DEAD`；目前自動驗證會檢查七種主要玩家動作動畫皆具備 8 方向與 3 frame。 |
| 像素素材生成 | `scenes/tests/PixelAssetBaker.tscn` 會輸出玩家 atlas、6 種敵人 atlas、物品 icon atlas 與 tileset PNG。 |
| 可玩性驗證 | `scenes/tests/ValidationRunner.tscn` 自動驗證資料、場景、存檔、配方、任務、公會交付、觸控控制、近戰擊殺、遠程射擊、戰鬥後存讀檔與回村狀態；`scenes/tests/AutomatedPlaytestRunner.tscn` 用 Input action 驅動移動、背包、近戰、射擊並輸出 `docs/automated_playtest_report.json`。 |

## 尚待下一階段精修

- 正式美術圖匯入後的 frame 切分、動畫樹精修、受擊與死亡動畫補強。
- Android export template / SDK 實機測試。
- 更完整 NPC 對話、更多任務分支與平衡調整。
