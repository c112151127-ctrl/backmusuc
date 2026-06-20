# Player Clean Body Replacement v4

本包移除 shoot / draw_sword / slash 動作幀裡烘進角色身上的大型武器物件。

## 使用方式

1. 關閉 Godot。
2. 刪除舊玩家素材：

```powershell
Remove-Item .\assets\sprites\player\frames -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item .\assets\sprites\player\actions -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item .\assets\sprites\player\recycler_player_multiaction_8dir.png -Force -ErrorAction SilentlyContinue
```

3. 將本包內容覆蓋到 Godot 專案根目錄。
4. 重新開 Godot，或對 `assets/sprites/player` 執行 Reimport。

## 修改內容

- `shoot`、`draw_sword`、`slash` 改用乾淨 idle body frames。
- 保留實際攻擊功能：射擊仍會產生 projectile，近戰仍會產生 AttackFlash。
- 更新 `recycler_player_multiaction_8dir.png`、`frames/`、`actions/`、diagnostic。
- 更新 `scripts/tools/rebuild_player_from_template.py`，之後重建也不會再把武器烘進角色身體。
