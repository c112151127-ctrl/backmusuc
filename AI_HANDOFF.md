# AI Handoff

## Project Goal

`C:\Code\Game\first-game` is a Godot 4.6.3 PC-first pixel-art pseudo-3D game. The vertical slice goal is: village preparation, guild contracts, four-route wasteland exploration, combat, resource pickup, equipment switching, save/load, and return-to-village progression.

## Current Status

Latest Codex work upgrades the project to Vertical Slice v2:

- Player is now the full-body R-17 recycler robot built from `docs/art_direction_reference_r17_full_body.png`.
- NPCs animate through procedural idle/talk motion and close dialogue when the player leaves.
- Enemies show movement animation, damage numbers, health bars, hit effects, and death fade.
- Village is a crossroad hub with four wasteland route exits.
- Wasteland uses `data/maps/wasteland_routes.json` for route-specific enemy mixes, props, resources, road style, and Boss enablement.
- HUD has redesigned dialogue, bottom controls, quickbar, minimap, tutorial, and character equipment panel.
- Save system has `has_save()`, `load_or_new()`, checksum-protected payload, route state, intro state, NPC state, quest state, inventory, equipment, and quick slots.

## Language Policy

- Technical planning, command reasoning, commit messages, and implementation notes: English.
- Player-facing UI, NPC dialogue, quest text, playtest checklist, SRS traceability, and user-facing documentation: Traditional Chinese.

## Important Files

- `project.godot`
- `scenes/main/Main.gd`
- `scenes/player/Player.gd`
- `scenes/ui/HUD.gd`
- `scenes/levels/village/Village.gd`
- `scenes/levels/guild/Guild.gd`
- `scenes/levels/wasteland/Wasteland.gd`
- `scripts/autoload/GameState.gd`
- `scripts/autoload/SaveManager.gd`
- `scripts/autoload/SceneRouter.gd`
- `scripts/components/DialogueNpc.gd`
- `scripts/components/Enemy.gd`
- `data/maps/wasteland_routes.json`
- `data/maps/npcs.json`
- `data/maps/quests.json`
- `data/items/equipment.json`
- `docs/IMPLEMENTATION_PLAN.md`
- `docs/PLAYTEST_CHECKLIST.md`
- `docs/SRS_TRACEABILITY.md`

## Development Workflow

Planning alone is not completion. For implementation tasks, the AI must inspect, plan, execute, validate, fix obvious issues, commit, and report results.

Before edits:

```powershell
git status --short
git branch --show-current
git log --oneline --decorate -10
git show --stat HEAD
```

Prefer small, testable Godot changes. Do not rebuild the project or replace the autoload architecture unless explicitly asked.

## Validation Workflow

```powershell
node -e "for (const f of ['data/maps/npcs.json','data/maps/events.json','data/maps/quests.json','data/maps/wasteland_routes.json','data/items/equipment.json','data/items/recipes.json','data/enemies/enemies.json','data/maps/wasteland_params.json']) { JSON.parse(require('fs').readFileSync(f,'utf8')); } console.log('JSON OK')"
python scripts\tools\build_release_candidate_assets.py
python scripts\tools\verify_visual_assets.py
& 'C:\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe' --headless --path 'C:\Code\Game\first-game' --quit
& 'C:\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe' --headless --path 'C:\Code\Game\first-game' --scene 'res://scenes/tests/PixelAssetBaker.tscn'
& 'C:\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe' --headless --path 'C:\Code\Game\first-game' --scene 'res://scenes/tests/ValidationRunner.tscn'
& 'C:\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe' --headless --path 'C:\Code\Game\first-game' --scene 'res://scenes/tests/AutomatedPlaytestRunner.tscn'
```

Use `VisualReviewRunner.tscn` or Computer Use for visual review when possible.

## Git Workflow

- Commit every verified implementation stage.
- Commit messages must be English.
- Do not commit `.env`, secrets, tokens, caches, or build artifacts.
- Do not force push.

Safe remote setup:

```powershell
if (git remote get-url origin 2>$null) { git remote set-url origin https://github.com/yuchan27/Game.git } else { git remote add origin https://github.com/yuchan27/Game.git }
git push -u origin HEAD
```

## Do Not Change Without Explicit Approval

- Godot executable path.
- Godot version.
- `project.godot` autoload structure.
- `ValidationRunner.tscn`, `AutomatedPlaytestRunner.tscn`, and `VisualReviewRunner.tscn` purposes.
- Save checksum/Base64 design.
- Village / guild / wasteland core loop.
- Traditional Chinese player-facing language policy.

## Safety Rule

Do not bulk delete files or directories. Never use `del /s`, `rd /s`, `rmdir /s`, `Remove-Item -Recurse`, or `rm -rf`. If deletion is needed, delete one explicit file path at a time.
