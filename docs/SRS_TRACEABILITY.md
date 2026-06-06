# SRS 對照表

| SRS / 設計要求 | 目前證據 |
| --- | --- |
| Godot 4.x 單機 2D Roguelike | `project.godot` 使用 Godot 4.6，主場景進入村莊、野外與公會流程。 |
| PC WASD + 滑鼠操作 | `GameState._ensure_input_actions()` 註冊 WASD、滑鼠、近戰、遠程、互動、背包、存檔與讀檔。 |
| Android 觸控 UI 基礎 | `scenes/ui/HUD.gd` 提供左下方向 D-pad，以及右下近戰、射擊、互動、背包、存檔按鈕。 |
| 撿取與裝備管理 | `scripts/components/Pickup.gd`、`GameState.inventory/equipment`、`HUD.gd` 背包裝備。 |
| 隨時存檔 JSON | `scripts/autoload/SaveManager.gd` 寫入 `user://save_game.json`。 |
| Base64 / hash 驗證 | `SaveManager.gd` 使用 Base64 payload + SHA-256 checksum。 |
| 程序化野外地圖 | `Wasteland.gd` 使用 seed 生成資源、事件與敵人位置。 |
| 村莊功能點 | `Village.gd` 實作鍛造、合成、交易、改裝、存檔、野外入口與公會入口。 |
| 冒險公會 | `Guild.gd` 實作任務 seed 與獎勵兌換。 |
| 混合戰鬥系統 | `Player.gd` 實作近戰與遠程；敵人與投射物腳本可互動。 |
| 敵人上限 30、子彈上限 200 | `Wasteland.gd` 生成 30 敵人；`ProjectilePool.gd` 依 `data/maps/wasteland_params.json` 執行 200 子彈硬上限。 |
| 像素偽 3D / Y-Sort | 主要場景與玩家節點開啟 `y_sort_enabled`，素材採 32px 像素風。 |
| 多角度 / 多動作玩家素材 | `Player.gd` 以 `AnimatedSprite2D` 建立 `idle/move/melee/shoot/swap_tool` x 8 方向 x 3 frame；另有 `assets/sprites/player/recycler_player_sprite_sheet.svg`。 |
| 可玩性驗證 | `scenes/tests/ValidationRunner.tscn` 自動驗證資料、場景、存檔、裝備循環、觸控控制、近戰擊殺、遠程射擊、戰鬥後存讀檔與回村狀態，可用 `--scene` 命令執行。 |

## 尚待下一階段精修

- 正式美術圖匯入後的 frame 切分與動畫樹精修。
- Android export template / SDK 實機測試。
- 更完整 NPC 對話、任務文本與平衡調整。
