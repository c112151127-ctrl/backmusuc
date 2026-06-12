# 美術資產清理與保留紀錄

## 本輪正式來源

- `docs/art_direction_reference_r17_v4.png`：R-17 高細節回收機器人正式參考來源。
- `data/art/player_animation_manifest.json`：玩家 atlas 的格尺寸、動作、方向與幀數契約。
- `data/art/visual_assets.json`：正式場景、NPC、敵人、Boss、道具、掉落物、UI 圖示與地圖標記來源。
- `assets/sprites/player/recycler_player_multiaction_8dir.png`：Godot 目前實際讀取的 R-17 多動作八方向 atlas。
- `assets/sprites/items/recycler_item_icons.png` 與 `assets/sprites/items/*.png`：裝備列、背包、掉落物使用的正式圖示。
- `assets/audio/*.wav`：目前 HUD、攻擊、受傷、轉場、升級與選單使用的音效。

## 清理政策

本專案明確禁止批量刪除檔案或目錄，因此本輪沒有使用 `Remove-Item -Recurse`、`rm -rf`、`rmdir /s` 或任何批量刪除指令。  
若後續要移除未使用素材，必須先跑 audit，再一次只刪除一個明確路徑。

## 已建立的驗證方式

使用下列指令檢查正式美術來源、空白圖片、重複命名資產、玩家動畫 manifest、JSON 與亂碼：

```powershell
python scripts\tools\verify_visual_assets.py
```

通過條件：

- `visual_assets.json` 中所有正式圖片都存在。
- 命名 NPC、建築、敵人、Boss、裝備與掉落物不可共用同一正式 PNG path。
- 正式 PNG 不可是全透明空圖。
- 玩家 atlas 與 `player_animation_manifest.json` 的 frame size、動作數、方向數、幀數一致。
- `data/`、`scenes/`、`scripts/`、`docs/` 的玩家可見文字不可出現 mojibake 亂碼。

## 後續可人工清理的範圍

若 `verify_visual_assets.py` 或後續擴充 audit 報告列出未引用素材，請人工確認下列條件後再逐一刪除：

- 不在 `data/art/visual_assets.json`。
- 不在 `data/art/player_animation_manifest.json`。
- 不被 Godot `.tscn`、`.gd`、JSON 或 import metadata 引用。
- 不是正在產生或驗證截圖的來源圖。
- 不是文件要求保留的美術方向參考。

目前不建議直接刪除 `docs/visual_review_*.png`，因為它們是本輪可玩性與美術 review 的驗收證據。
