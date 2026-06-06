# AI 交接文件

## 專案狀態

目前專案位於 `C:\Code\Game\first-game`，使用 Godot 4.6.3。主分支工作目前在 `wip/codex-3d-game-progress`，Godot console 路徑固定為：

```powershell
C:\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe
```

本次交接前的基準提交為 `81676c9 Add dialogue NPC guidance`。後續接手者應以 `git log --oneline --decorate -10` 重新確認最新提交。

## 目前 playable vertical slice

- 村莊：鍛造、合成、商店、改裝、拆解、存檔、前往野外、前往公會。
- 公會：接取委託、交付獎勵、前往野外、返回村莊。
- 野外：100x80 tile 程序場景、Y-Sort 地標、障礙、資源、事件、30 名敵人、200 投射物上限。
- 玩家：WASD、滑鼠近戰/射擊、`Q` 與 `1`-`4` 快捷欄、背包、存讀檔。
- Android 操作：HUD 內建方向 D-pad 與觸控動作按鈕，仍需 Android 工具鏈補齊後做實機驗證。
- NPC：村莊與公會 NPC 由 `data/maps/npcs.json` 生成，第一次交談給一次性導引獎勵，重複交談不重複給獎。

## 本次工作重點

本次 Codex 工作應完成交接文件、實作計畫、SRS traceability、playtest checklist，並把玩家多角度像素素材規格與可驗證動作狀態補齊。玩家動作合約應至少包含：

- idle / 待機
- walk / 行走
- shoot / 射擊
- draw_sword / 拔刀
- slash / 斬擊
- swap_tool / 切換工具或武器
- interact / 互動

## 驗證命令

```powershell
node -e "JSON.parse(require('fs').readFileSync('data/maps/npcs.json','utf8')); console.log('JSON OK')"
& 'C:\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe' --headless --path 'C:\Code\Game\first-game' --quit
& 'C:\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe' --headless --path 'C:\Code\Game\first-game' --scene 'res://scenes/tests/PixelAssetBaker.tscn'
& 'C:\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe' --headless --path 'C:\Code\Game\first-game' --scene 'res://scenes/tests/ValidationRunner.tscn'
& 'C:\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe' --headless --path 'C:\Code\Game\first-game' --scene 'res://scenes/tests/AutomatedPlaytestRunner.tscn'
```

## 不能任意更動的內容

- 不重建專案，不改 Godot 主版本。
- 不移除 autoload：`GameState`、`DataRegistry`、`SaveManager`、`SceneRouter`。
- 不移除 `ValidationRunner`、`AutomatedPlaytestRunner`、`PixelAssetBaker`。
- 不破壞 `user://save_game.json` 的 Base64 payload + SHA-256 checksum 設計。
- 不把玩家可見文字改成簡體中文或英文。
- 不提交匯出成品、cache、secrets 或 token。

## 完成任務定義

Planning alone is not completion. For implementation tasks, the AI must inspect, plan, execute, validate, fix obvious issues, commit, and report results.

完成一個實作任務至少要包含：讀取現況、更新檔案、跑合理驗證、修復明顯錯誤、commit、嘗試 push。若 push 因 GitHub 驗證失敗，保留本地 commit 並回報完整錯誤。

## 安全推送

```powershell
if (git remote get-url origin 2>$null) { git remote set-url origin https://github.com/yuchan27/Game.git } else { git remote add origin https://github.com/yuchan27/Game.git }
git push -u origin HEAD
```
