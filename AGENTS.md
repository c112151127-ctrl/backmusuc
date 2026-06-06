# AI 協作規則

## 專案目標

本專案是 Godot 4.6.3 製作的像素風偽 3D 單機 Roguelike vertical slice。核心目標是讓玩家能在村莊整備、前往冒險公會接委託、進入野外探索與戰鬥、撿取資源、切換裝備、回村強化並存讀檔。

## 語言政策

- 技術規劃、命令推理、commit message 與內部實作註記使用英文。
- 所有玩家可見內容與交付給使用者閱讀的文件使用繁體中文：NPC 對話、UI 文字、任務文字、測試清單、SRS 對照、素材與動作設計說明。

## 必讀檔案

- `project.godot`
- `docs/IMPLEMENTATION_PLAN.md`
- `docs/PLAYTEST_CHECKLIST.md`
- `docs/SRS_TRACEABILITY.md`
- `docs/EXPORT_READINESS.md`
- `data/maps/npcs.json`
- `data/maps/quests.json`
- `data/items/equipment.json`
- `data/items/recipes.json`
- `data/enemies/enemies.json`
- `scenes/player/Player.gd`
- `scenes/levels/village/Village.gd`
- `scenes/levels/guild/Guild.gd`
- `scenes/levels/wasteland/Wasteland.gd`
- `scripts/tests/VerticalSliceVerifier.gd`
- `scripts/tests/AutomatedPlaytestRunner.gd`

## 開發流程

Planning alone is not completion. For implementation tasks, the AI must inspect, plan, execute, validate, fix obvious issues, commit, and report results.

每次實作前先執行或檢查：

```powershell
git status
git branch --show-current
git log --oneline --decorate -10
git show --stat HEAD
```

修改時遵守既有 Godot 場景樹、autoload、Signal、JSON 資料驅動架構。不要為了小改動重建專案、搬移主場景、改掉 Godot 版本或改掉既有驗證入口。

## 驗證流程

Godot console 固定使用：

```powershell
& 'C:\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe' --headless --path 'C:\Code\Game\first-game' --quit
& 'C:\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe' --headless --path 'C:\Code\Game\first-game' --scene 'res://scenes/tests/ValidationRunner.tscn'
& 'C:\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe' --headless --path 'C:\Code\Game\first-game' --scene 'res://scenes/tests/AutomatedPlaytestRunner.tscn'
```

若修改 JSON，至少執行：

```powershell
node -e "JSON.parse(require('fs').readFileSync('data/maps/npcs.json','utf8')); console.log('JSON OK')"
```

若修改像素素材生成或玩家動作 atlas，先執行：

```powershell
& 'C:\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe' --headless --path 'C:\Code\Game\first-game' --scene 'res://scenes/tests/PixelAssetBaker.tscn'
```

## Git 流程

- 每次完成可驗證更新後都要 commit。
- commit message 使用英文，例如 `Document handoff and expand player actions`。
- 不提交 `.env`、token、credentials、cache、匯出成品或 build artifacts。
- 不 force push。
- 安全設定 remote：

```powershell
if (git remote get-url origin 2>$null) { git remote set-url origin https://github.com/yuchan27/Game.git } else { git remote add origin https://github.com/yuchan27/Game.git }
git push -u origin HEAD
```

## 禁止事項

禁止批量刪除文件或目錄。不要使用：

- `del /s`
- `rd /s`
- `rmdir /s`
- `Remove-Item -Recurse`
- `rm -rf`

需要刪除文件時，只能一次刪除一個明確路徑的文件。若需要批量刪除，停止操作並請使用者手動處理。

未經明確要求，不要改掉：

- Godot 執行檔路徑。
- `project.godot` 的 autoload 結構。
- `ValidationRunner.tscn` 與 `AutomatedPlaytestRunner.tscn` 的驗證用途。
- 存檔格式的 Base64/checksum 安全設計。
- 村莊、公會、野外三場景的核心流程。
- 繁體中文玩家可見文字政策。

## 從最新 Codex 工作繼續

先讀 `AI_HANDOFF.md` 與 `docs/IMPLEMENTATION_PLAN.md`，再跑驗證命令確認目前狀態。若驗證失敗，優先修復會破壞 playable vertical slice 的問題，再擴充內容。
