# Player Template Replacement v3

這包會把舊的 player 圖片替換成 `assets/sprites/player/source/r17_reference.png` 這張模板產生的版本。

## 覆蓋方式

1. 關閉 Godot。
2. 把本 ZIP 解壓縮到 Godot 專案根目錄，覆蓋同名檔案。
3. 建議先刪除舊資料夾後再覆蓋：

```powershell
Remove-Item .\assets\sprites\player\frames -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item .\assets\sprites\player\actions -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item .\assets\sprites\player\weapons -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item .\assets\sprites\player\recycler_player_multiaction_8dir.png -Force -ErrorAction SilentlyContinue
```

4. 覆蓋後重新開 Godot，或對 `assets/sprites/player` 做 Reimport。

## 重新產生

```powershell
python -m pip install pillow scipy numpy
python scripts\tools\rebuild_player_from_template.py
```

## 檢查檔案

請先看：

`docs/player_split_frame_diagnostic.png`

再看：

`assets/sprites/player/recycler_player_multiaction_8dir.png`
