# Workflow

## Task Completion Policy

Planning alone is not completion. For implementation tasks, the AI must inspect, plan, execute, validate, fix obvious issues, commit, and report results.

## Standard Start

Run these before editing:

```powershell
git status --short
git branch --show-current
git log --oneline --decorate -10
git show --stat HEAD
```

Read these before broad changes:

- `AI_HANDOFF.md`
- `docs/IMPLEMENTATION_PLAN.md`
- `docs/PLAYTEST_CHECKLIST.md`
- `docs/SRS_TRACEABILITY.md`
- `project.godot`

## Implementation Rules

- Keep PC-first controls unless the user explicitly requests mobile work.
- Keep all player-facing text in Traditional Chinese.
- Prefer existing Godot scenes, autoloads, and data-driven JSON patterns.
- Use route/data additions instead of duplicating scene files when one scene can be parameterized safely.
- Keep `ValidationRunner`, `AutomatedPlaytestRunner`, and `VisualReviewRunner` working.

## Validation

Minimum validation after code/data changes:

```powershell
node -e "for (const f of ['data/maps/npcs.json','data/maps/events.json','data/maps/quests.json','data/maps/wasteland_routes.json','data/items/equipment.json','data/items/recipes.json','data/enemies/enemies.json','data/maps/wasteland_params.json']) { JSON.parse(require('fs').readFileSync(f,'utf8')); } console.log('JSON OK')"
& 'C:\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe' --headless --path 'C:\Code\Game\first-game' --quit
& 'C:\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe' --headless --path 'C:\Code\Game\first-game' --scene 'res://scenes/tests/ValidationRunner.tscn'
& 'C:\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe' --headless --path 'C:\Code\Game\first-game' --scene 'res://scenes/tests/AutomatedPlaytestRunner.tscn'
```

Run visual review after visual/UI changes:

```powershell
& 'C:\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe' --path 'C:\Code\Game\first-game' --scene 'res://scenes/tests/VisualReviewRunner.tscn'
```

## Git

Commit only after validation or after clearly documenting a blocker.

```powershell
git add <changed files>
git commit -m "Clear English message"
if (git remote get-url origin 2>$null) { git remote set-url origin https://github.com/yuchan27/Game.git } else { git remote add origin https://github.com/yuchan27/Game.git }
git push -u origin HEAD
```

Do not force push.

## Forbidden

Do not bulk delete files or directories. Never use:

- `del /s`
- `rd /s`
- `rmdir /s`
- `Remove-Item -Recurse`
- `rm -rf`

If multiple files need deletion, stop and ask the user to handle the deletion manually.
