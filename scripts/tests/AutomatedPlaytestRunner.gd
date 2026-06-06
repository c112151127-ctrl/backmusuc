extends Node

const VILLAGE_SCENE := preload("res://scenes/levels/village/Village.tscn")
const WASTELAND_SCENE := preload("res://scenes/levels/wasteland/Wasteland.tscn")
const GUILD_SCENE := preload("res://scenes/levels/guild/Guild.tscn")
const REPORT_PATH := "res://docs/automated_playtest_report.json"

var failures: Array[String] = []
var report: Dictionary = {
	"version": 1,
	"runner": "AutomatedPlaytestRunner",
	"checks": [],
	"snapshots": {}
}

func _ready() -> void:
	await get_tree().process_frame
	print("[PLAYTEST] Automated playtest started")
	DataRegistry.load_all()
	await _play_village_input_flow()
	await _play_guild_contract_flow()
	await _play_wasteland_combat_flow()
	_write_report()
	_finish()

func _play_village_input_flow() -> void:
	GameState.reset_new_run(false)
	GameState.current_scene_id = "village"
	var village := VILLAGE_SCENE.instantiate()
	add_child(village)
	await _settle_frames(3)
	var player := _first_group_node("player") as Node2D
	var hud := _first_node_by_name(village, "HudRoot") as Control
	_expect(player != null, "village: player exists")
	_expect(hud != null, "village: HUD root exists")
	if player != null:
		var camera := player.get_node_or_null("Camera2D")
		_expect(camera is Camera2D and camera.enabled, "village: player camera is enabled")
		var start_position := player.global_position
		Input.action_press("move_right")
		await _settle_seconds(0.35)
		Input.action_release("move_right")
		_expect(player.global_position.x > start_position.x + 20.0, "village: WASD input moves player")
	await _tap_action("open_inventory")
	var inventory_panel := _first_node_by_name(village, "InventoryPanel") as PanelContainer
	_expect(inventory_panel != null and inventory_panel.visible, "village: inventory opens through input")
	GameState.add_item("bio_crystal", 1)
	var crafted := InventorySystem.craft_basic_upgrade()
	_expect(crafted and GameState.inventory.has("spark_cutter"), "village: craft station loop can create weapon")
	_record_snapshot("village", {
		"position": _vector_to_data(player.global_position if player != null else Vector2.ZERO),
		"inventory_open": inventory_panel.visible if inventory_panel != null else false,
		"has_spark_cutter": GameState.inventory.has("spark_cutter")
	})
	village.queue_free()
	await _settle_frames(2)

func _play_guild_contract_flow() -> void:
	GameState.reset_new_run(false)
	GameState.current_scene_id = "guild"
	var guild := GUILD_SCENE.instantiate()
	add_child(guild)
	await _settle_frames(3)
	_expect(get_tree().get_nodes_in_group("interactable").size() >= 3, "guild: interactable counters exist")
	var started := GameState.start_quest("clear_scrap_route")
	_expect(started, "guild: contract can be accepted")
	_expect(not GameState.active_quest_id.is_empty(), "guild: active quest is visible in state")
	for i in range(5):
		GameState.record_enemy_defeated()
	GameState.add_item("scrap", 12)
	_expect(GameState.is_active_quest_ready(), "guild: quest objectives can be completed")
	var reward_before := GameState.cores
	var completed := GameState.complete_active_quest()
	_expect(completed, "guild: completed quest can be delivered")
	_expect(GameState.cores == reward_before + 1, "guild: quest delivery grants reward")
	_record_snapshot("guild", {
		"completed_quests": GameState.completed_quests.duplicate(),
		"cores": GameState.cores
	})
	guild.queue_free()
	await _settle_frames(2)

func _play_wasteland_combat_flow() -> void:
	GameState.reset_new_run(false)
	GameState.current_scene_id = "wasteland"
	var wasteland := WASTELAND_SCENE.instantiate()
	add_child(wasteland)
	await _settle_frames(4)
	var player := _first_group_node("player") as Node2D
	var enemies := get_tree().get_nodes_in_group("enemy")
	var pools := get_tree().get_nodes_in_group("projectile_pool")
	_expect(player != null, "wasteland: player exists")
	_expect(enemies.size() >= 30, "wasteland: 30 enemy pressure spawn exists")
	_expect(pools.size() == 1, "wasteland: projectile pool exists")
	if player == null or enemies.is_empty():
		wasteland.queue_free()
		await _settle_frames(2)
		return
	var enemy := enemies[0]
	player.global_position = Vector2(720, 720)
	enemy.global_position = player.global_position + Vector2(34, 0)
	enemy.hp = 1
	player.last_direction = Vector2.RIGHT
	var defeated_before := GameState.defeated_enemies
	await _tap_action("attack_melee")
	await _settle_seconds(0.12)
	_expect(GameState.defeated_enemies == defeated_before + 1, "wasteland: melee input defeats nearby enemy")
	var ammo_before := GameState.ammo
	await _tap_action("attack_ranged")
	await _settle_frames(2)
	_expect(GameState.ammo == ammo_before - 1, "wasteland: ranged input consumes ammo")
	if not pools.is_empty():
		_expect(int(pools[0].active_count) >= 1, "wasteland: ranged input spawns projectile")
	var saved := SaveManager.save_game()
	var loaded := _load_save_without_scene_change()
	_expect(saved and loaded, "wasteland: save/load works after combat input")
	_record_snapshot("wasteland", {
		"enemy_count": enemies.size(),
		"ammo_after_ranged": GameState.ammo,
		"projectiles": int(pools[0].active_count) if not pools.is_empty() else 0,
		"position": _vector_to_data(player.global_position)
	})
	wasteland.queue_free()
	await _settle_frames(2)

func _load_save_without_scene_change() -> bool:
	if not FileAccess.file_exists("user://save_game.json"):
		return false
	var file := FileAccess.open("user://save_game.json", FileAccess.READ)
	var wrapped = JSON.parse_string(file.get_as_text())
	if typeof(wrapped) != TYPE_DICTIONARY:
		return false
	var payload_text := Marshalls.base64_to_utf8(String(wrapped.get("payload", "")))
	if payload_text.sha256_text() != String(wrapped.get("checksum", "")):
		return false
	var data = JSON.parse_string(payload_text)
	if typeof(data) != TYPE_DICTIONARY:
		return false
	return GameState.load_save_data(data)

func _record_snapshot(id: String, data: Dictionary) -> void:
	report.snapshots[id] = data

func _write_report() -> void:
	report["passed"] = failures.is_empty()
	report["failure_count"] = failures.size()
	report["failures"] = failures.duplicate()
	var file := FileAccess.open(REPORT_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(report, "\t"))
		print("[PLAYTEST] Report written: " + REPORT_PATH)
	else:
		_expect(false, "playtest report can be written")

func _expect(condition: bool, label: String) -> void:
	report.checks.append({
		"label": label,
		"passed": condition
	})
	if condition:
		print("[PASS] " + label)
	else:
		failures.append(label)
		push_error("[FAIL] " + label)

func _first_group_node(group_name: String) -> Node:
	var nodes := get_tree().get_nodes_in_group(group_name)
	return nodes[0] if not nodes.is_empty() else null

func _first_node_by_name(root: Node, node_name: String) -> Node:
	if root.name == node_name:
		return root
	for child in root.get_children():
		var found := _first_node_by_name(child, node_name)
		if found != null:
			return found
	return null

func _vector_to_data(value: Vector2) -> Dictionary:
	return {
		"x": value.x,
		"y": value.y
	}

func _settle_frames(count: int) -> void:
	for i in range(count):
		await get_tree().process_frame

func _settle_seconds(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout

func _tap_action(action_name: String) -> void:
	Input.action_release(action_name)
	await get_tree().process_frame
	Input.action_press(action_name)
	await get_tree().process_frame
	await get_tree().physics_frame
	Input.action_release(action_name)
	await get_tree().process_frame

func _finish() -> void:
	if failures.is_empty():
		print("[PLAYTEST] Automated playtest passed")
		get_tree().quit(0)
	else:
		print("[PLAYTEST] Automated playtest failed: %s" % JSON.stringify(failures))
		get_tree().quit(1)
