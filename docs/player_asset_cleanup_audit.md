# Player Asset Cleanup Audit

本輪依專案規則沒有批量刪除任何檔案。正式玩家資產已改成分離式 PNG：身體逐格、動作 sheet、武器 overlay 各自管理。

## 目前正式使用
- `assets/sprites/player/frames`
- `assets/sprites/player/actions`
- `assets/sprites/player/weapons`
- `assets/sprites/player/recycler_player_multiaction_8dir.png`
- `data/art/player_animation_manifest.json`

## 建議人工確認後單檔刪除的舊候選

下列檔案若未被 Godot import 或 README 文件引用，可由使用者人工逐一刪除；AI 不會使用批量刪除命令。
- `assets/sprites/player/recycler_player_sprite_sheet.svg`：存在
- `assets/sprites/player/recycler_player_sprite_sheet.svg.import`：存在
- `assets/sprites/player/recycler_player_sprite_sheet.png`：不存在
- `assets/sprites/player/recycler_player_sprite_sheet.png.import`：不存在
- `assets/sprites/player/recycler_player_multiaction_8dir.svg`：不存在

## 驗證規則

- 玩家身體幀不應包含刀、槍、槍口火光或大型揮砍弧光。
- 走路與待機幀必須保留左右手，不可因裁切消失。
- 武器圖只從 `assets/sprites/player/weapons/` 讀取，避免重複手臂與重複武器。
