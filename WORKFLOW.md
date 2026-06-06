# 開發與驗收流程

## 單次任務流程

1. Inspect：檢查 Git、最新提交、專案檔案、需求文件與相關腳本。
2. Plan：更新 `docs/IMPLEMENTATION_PLAN.md`，把要做的行為、檔案、驗證命令寫清楚。
3. Execute：直接修改 Godot 腳本、資料 JSON、文件或素材生成器。
4. Validate：執行 JSON、Godot headless、vertical slice verifier、automated playtest。
5. Fix：若驗證失敗，先修正明顯問題並重跑驗證。
6. Commit：用英文 commit message 提交。
7. Push：設定 origin 後執行 `git push -u origin HEAD`。
8. Report：用繁體中文回報檔案、驗證、commit hash、branch、push 結果與剩餘 blocker。

Planning alone is not completion. For implementation tasks, the AI must inspect, plan, execute, validate, fix obvious issues, commit, and report results.

## 開始工作前

```powershell
git status
git branch --show-current
git log --oneline --decorate -10
git show --stat HEAD
```

確認是否已有使用者未提交修改。不要 revert 或覆蓋不是自己造成的修改。

## 文件與資料檢查

優先閱讀：

- `AGENTS.md`
- `AI_HANDOFF.md`
- `docs/IMPLEMENTATION_PLAN.md`
- `docs/PLAYTEST_CHECKLIST.md`
- `docs/SRS_TRACEABILITY.md`
- `data/maps/npcs.json`
- SRS Word 文件與設計報告
- 地圖與角色參考圖

## Godot 驗證

```powershell
& 'C:\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe' --headless --path 'C:\Code\Game\first-game' --quit
```

```powershell
& 'C:\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe' --headless --path 'C:\Code\Game\first-game' --scene 'res://scenes/tests/ValidationRunner.tscn'
```

```powershell
& 'C:\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe' --headless --path 'C:\Code\Game\first-game' --scene 'res://scenes/tests/AutomatedPlaytestRunner.tscn'
```

若更新玩家或像素素材：

```powershell
& 'C:\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe' --headless --path 'C:\Code\Game\first-game' --scene 'res://scenes/tests/PixelAssetBaker.tscn'
```

## JSON 驗證

```powershell
node -e "JSON.parse(require('fs').readFileSync('data/maps/npcs.json','utf8')); console.log('JSON OK')"
```

若修改多個 JSON，可改用 Node 腳本逐一解析 `data/**/*.json`。

## 手動試玩

若可開視窗，從 Godot 或執行專案檢查：

- 村莊出現玩家、HUD、功能點與 NPC。
- NPC 第一次交談給獎，第二次不重複給獎。
- 公會可接任務，野外可擊殺敵人與撿資源，回公會可交付。
- `F5` 存檔、`F9` 讀檔後位置、背包、裝備、委託與 NPC 狀態可還原。
- 玩家有 8 方向與 7 動作的動畫資料：待機、行走、射擊、拔刀、斬擊、切換、互動。

## Commit 與 Push

```powershell
git status --short
git add AGENTS.md AI_HANDOFF.md WORKFLOW.md docs/IMPLEMENTATION_PLAN.md docs/PLAYTEST_CHECKLIST.md docs/SRS_TRACEABILITY.md assets/sprites/README.md scripts scenes data assets
git commit -m "Document handoff and expand player actions"
if (git remote get-url origin 2>$null) { git remote set-url origin https://github.com/yuchan27/Game.git } else { git remote add origin https://github.com/yuchan27/Game.git }
git push -u origin HEAD
```

不要 force push。若驗證或 authentication 失敗，保留 commit 並回報錯誤。
