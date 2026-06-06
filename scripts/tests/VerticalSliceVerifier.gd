extends Node

const VILLAGE_SCENE := preload("res://scenes/levels/village/Village.tscn")
const WASTELAND_SCENE := preload("res://scenes/levels/wasteland/Wasteland.tscn")
const GUILD_SCENE := preload("res://scenes/levels/guild/Guild.tscn")

var failures: Array[String] = []

func _ready() -> void:
	await get_tree().process_frame
	print("[VERIFY] Waste Recycler vertical slice verification started")
	DataRegistry.load_all()
	_check_data_registry()
	_check_baked_assets()
	_check_export_presets()
	await _check_scene("village", VILLAGE_SCENE, {
		"interactable": 7,
		"player": 1
	})
	await _check_scene("wasteland", WASTELAND_SCENE, {
		"interactable": 5,
		"enemy": 30,
		"pickup": 42,
		"projectile_pool": 1,
		"player": 1
	})
	await _check_scene("guild", GUILD_SCENE, {
		"interactable": 3,
		"player": 1
	})
	_check_save_roundtrip()
	_check_equipment_loop()
	_check_recipe_and_quest_loop()
	await _check_playable_core_loop()
	await _check_touch_controls()
	await _check_player_animation_contract()
	await _check_projectile_pool_limit()
	_finish()

func _check_data_registry() -> void:
	_expect(DataRegistry.equipment.size() >= 6, "equipment data has at least 6 entries")
	_expect(DataRegistry.resources.size() >= 4, "resource data has at least 4 entries")
	_expect(DataRegistry.enemies.size() >= 6, "enemy data has 6 enemy archetypes")
	_expect(DataRegistry.events.size() >= 4, "event data has random event pool")
	_expect(DataRegistry.recipes.size() >= 5, "recipe data has forge craft shop and mod loops")
	_expect(DataRegistry.quests.size() >= 2, "quest data has guild contracts")
	_expect(int(DataRegistry.map_params.get("width_tiles", 0)) >= 100, "wasteland width is at least 100 tiles")
	_expect(int(DataRegistry.map_params.get("height_tiles", 0)) >= 80, "wasteland height is at least 80 tiles")

func _check_baked_assets() -> void:
	_expect_png_size("res://assets/sprites/player/recycler_player_multiaction_8dir.png", Vector2i(480, 320), "baked player atlas exists at 5 actions x 8 directions x 3 frames")
	_expect_png_size("res://assets/sprites/enemies/polluted_enemy_six_types.png", Vector2i(216, 34), "baked enemy atlas has 6 enemy types")
	_expect_png_size("res://assets/sprites/items/recycler_item_icons.png", Vector2i(96, 24), "baked item icon atlas has 4 resource icons")
	_expect_png_size("res://assets/sprites/tiles/recycler_tileset.png", Vector2i(192, 32), "baked terrain tileset has village and wasteland tiles")

func _check_export_presets() -> void:
	var config := ConfigFile.new()
	var loaded := config.load("res://export_presets.cfg")
	_expect(loaded == OK, "export_presets.cfg loads")
	if loaded != OK:
		return
	_expect(String(config.get_value("preset.0", "name", "")) == "Windows Desktop", "Windows export preset exists")
	_expect(String(config.get_value("preset.0", "platform", "")) == "Windows Desktop", "Windows export preset platform is valid")
	_expect(String(config.get_value("preset.1", "name", "")) == "Android", "Android export preset exists")
	_expect(String(config.get_value("preset.1", "platform", "")) == "Android", "Android export preset platform is valid")

func _check_scene(scene_id: String, packed: PackedScene, group_minimums: Dictionary) -> void:
	GameState.reset_new_run(false)
	GameState.current_scene_id = scene_id
	var instance := packed.instantiate()
	add_child(instance)
	await get_tree().process_frame
	await get_tree().process_frame
	for group_name in group_minimums.keys():
		var count := get_tree().get_nodes_in_group(String(group_name)).size()
		_expect(count >= int(group_minimums[group_name]), "%s has %s >= %d" % [scene_id, group_name, int(group_minimums[group_name])])
	instance.queue_free()
	await get_tree().process_frame

func _check_save_roundtrip() -> void:
	GameState.reset_new_run(false)
	GameState.current_scene_id = "wasteland"
	GameState.start_quest("clear_scrap_route")
	GameState.advance_quest_counter("defeat_enemy", 2)
	GameState.player_position = Vector2(321, 654)
	GameState.add_item("scrap", 12)
	GameState.add_item("spark_cutter", 1)
	GameState.equip_item("spark_cutter")
	var before := GameState.get_save_data()
	var saved := SaveManager.save_game()
	GameState.reset_new_run(false)
	var loaded := _load_save_without_scene_change()
	var after := GameState.get_save_data()
	_expect(saved, "save manager writes save_game.json")
	_expect(loaded, "save manager loads save_game.json")
	_expect(String(after.get("scene", "")) == String(before.get("scene", "")), "save roundtrip restores scene")
	_expect(Vector2(float(after.player.position_x), float(after.player.position_y)) == Vector2(321, 654), "save roundtrip restores player position")
	_expect(String(after.equipment.weapon) == "spark_cutter", "save roundtrip restores equipped weapon")
	_expect(String(after.get("active_quest_id", "")) == "clear_scrap_route", "save roundtrip restores active quest")
	_expect(int(after.get("quest_progress", {}).get("defeat_enemy", 0)) == 2, "save roundtrip restores quest progress")

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

func _check_equipment_loop() -> void:
	GameState.reset_new_run(false)
	_expect(GameState.consume_item("scrap", 8), "scrap can be consumed for forging")
	GameState.add_item("ammo", 12)
	_expect(GameState.spend_ammo(1), "ranged attack consumes ammo")
	GameState.add_item("spark_cutter", 1)
	_expect(GameState.equip_item("spark_cutter"), "crafted melee weapon can be equipped")
	_expect(GameState.get_stat_bonus("attack") >= 15, "equipment stat bonus updates attack")

func _check_recipe_and_quest_loop() -> void:
	GameState.reset_new_run(false)
	_expect(DataRegistry.get_recipe("ammo_pack").size() > 0, "ammo recipe can be read")
	var ammo_before := GameState.ammo
	_expect(InventorySystem.forge_ammo_pack(), "forge station recipe crafts ammo pack")
	_expect(GameState.ammo == ammo_before + 12, "forge recipe increases ammo")
	GameState.add_item("bio_crystal", 1)
	_expect(InventorySystem.craft_basic_upgrade(), "craft station recipe creates spark cutter")
	_expect(GameState.inventory.has("spark_cutter"), "crafted weapon enters inventory")
	_expect(GameState.start_quest("clear_scrap_route"), "guild can start a quest")
	for i in range(5):
		GameState.record_enemy_defeated()
	GameState.add_item("scrap", 12)
	_expect(GameState.is_active_quest_ready(), "quest becomes ready after defeat and collect objectives")
	var cores_before := GameState.cores
	_expect(GameState.complete_active_quest(), "guild reward completes active quest")
	_expect(GameState.active_quest_id.is_empty(), "completed quest clears active quest")
	_expect(GameState.completed_quests.has("clear_scrap_route"), "completed quest is recorded")
	_expect(GameState.cores == cores_before + 1, "quest reward grants mutant core")

func _check_playable_core_loop() -> void:
	GameState.reset_new_run(false)
	GameState.current_scene_id = "wasteland"
	var instance := WASTELAND_SCENE.instantiate()
	add_child(instance)
	await get_tree().process_frame
	await get_tree().process_frame
	var players := get_tree().get_nodes_in_group("player")
	var enemies := get_tree().get_nodes_in_group("enemy")
	var pickups_before := get_tree().get_nodes_in_group("pickup").size()
	_expect(not players.is_empty(), "playable loop has player")
	_expect(not enemies.is_empty(), "playable loop has enemy")
	if players.is_empty() or enemies.is_empty():
		instance.queue_free()
		await get_tree().process_frame
		return
	var player := players[0]
	var enemy := enemies[0]
	player.global_position = Vector2(640, 640)
	enemy.global_position = player.global_position + Vector2(32, 0)
	enemy.hp = 1
	player.last_direction = Vector2.RIGHT
	var defeated_before := GameState.defeated_enemies
	player._melee_attack()
	await get_tree().create_timer(0.12).timeout
	_expect(GameState.defeated_enemies == defeated_before + 1, "playable loop melee defeats enemy")
	_expect(get_tree().get_nodes_in_group("pickup").size() >= pickups_before, "playable loop keeps or creates pickup resources")
	var ammo_before := GameState.ammo
	player.ranged_timer = 0.0
	player._ranged_attack()
	await get_tree().process_frame
	_expect(GameState.ammo == ammo_before - 1, "playable loop ranged attack consumes ammo")
	var pools := get_tree().get_nodes_in_group("projectile_pool")
	if not pools.is_empty():
		_expect(int(pools[0].active_count) >= 1, "playable loop ranged attack spawns projectile")
	GameState.player_position = player.global_position
	var saved := SaveManager.save_game()
	GameState.current_scene_id = "village"
	var loaded := _load_save_without_scene_change()
	_expect(saved and loaded, "playable loop can save and reload after combat")
	_expect(GameState.current_scene_id == "wasteland", "playable loop restores wasteland scene after reload")
	GameState.set_scene("village", "from_wasteland")
	_expect(GameState.current_scene_id == "village", "playable loop can return to village state")
	instance.queue_free()
	await get_tree().process_frame

func _check_touch_controls() -> void:
	GameState.reset_new_run(false)
	var instance := VILLAGE_SCENE.instantiate()
	add_child(instance)
	await get_tree().process_frame
	var required_actions: Array[String] = [
		"move_up",
		"move_down",
		"move_left",
		"move_right",
		"attack_melee",
		"attack_ranged",
		"interact",
		"open_inventory",
		"save_game"
	]
	for action_name in required_actions:
		_expect(InputMap.has_action(action_name), "input action exists: " + action_name)
	var move_buttons := get_tree().get_nodes_in_group("touch_move_control")
	var action_buttons := get_tree().get_nodes_in_group("touch_action_control")
	_expect(move_buttons.size() >= 4, "touch controls include 4 movement buttons")
	_expect(action_buttons.size() >= 5, "touch controls include 5 action buttons")
	var seen_actions: Dictionary = {}
	for button in move_buttons + action_buttons:
		if button.has_meta("input_action"):
			seen_actions[String(button.get_meta("input_action"))] = true
	for action_name in required_actions:
		_expect(seen_actions.has(action_name), "touch control maps action: " + action_name)
	instance.queue_free()
	await get_tree().process_frame

func _check_player_animation_contract() -> void:
	GameState.reset_new_run(false)
	var instance := VILLAGE_SCENE.instantiate()
	add_child(instance)
	await get_tree().process_frame
	var players := get_tree().get_nodes_in_group("player")
	_expect(not players.is_empty(), "player exists for animation contract")
	if not players.is_empty():
		var player := players[0]
		var animated_sprite := player.get_node_or_null("AnimatedSprite2D")
		_expect(animated_sprite is AnimatedSprite2D, "player uses AnimatedSprite2D")
		if animated_sprite is AnimatedSprite2D:
			var frame_set: SpriteFrames = animated_sprite.sprite_frames
			var actions: Array[String] = ["idle", "move", "melee", "shoot", "swap_tool"]
			for action_name in actions:
				for direction_index in range(8):
					var animation_name := "%s_%d" % [action_name, direction_index]
					_expect(frame_set.has_animation(animation_name), "player animation exists: " + animation_name)
					if frame_set.has_animation(animation_name):
						_expect(frame_set.get_frame_count(animation_name) >= 3, "player animation has frames: " + animation_name)
			var first_frame := frame_set.get_frame_texture("idle_0", 0)
			_expect(first_frame is AtlasTexture, "player animation frames use baked PNG atlas when available")
	instance.queue_free()
	await get_tree().process_frame

func _check_projectile_pool_limit() -> void:
	GameState.reset_new_run(false)
	var instance := WASTELAND_SCENE.instantiate()
	add_child(instance)
	await get_tree().process_frame
	var pools := get_tree().get_nodes_in_group("projectile_pool")
	_expect(not pools.is_empty(), "projectile pool exists in wasteland")
	if not pools.is_empty():
		var pool := pools[0]
		_expect(int(pool.max_projectiles) == int(DataRegistry.map_params.get("projectile_limit", 200)), "projectile pool uses map projectile limit")
		var fired := 0
		for i in range(int(pool.max_projectiles) + 5):
			if pool.fire_projectile(Vector2(100, 100), Vector2.RIGHT, 1):
				fired += 1
		_expect(fired == int(pool.max_projectiles), "projectile pool blocks projectiles above limit")
		_expect(int(pool.active_count) == int(pool.max_projectiles), "projectile pool active count stays at limit")
	instance.queue_free()
	await get_tree().process_frame

func _expect(condition: bool, label: String) -> void:
	if condition:
		print("[PASS] " + label)
	else:
		failures.append(label)
		push_error("[FAIL] " + label)

func _expect_png_size(path: String, expected_size: Vector2i, label: String) -> void:
	_expect(FileAccess.file_exists(path), label + " file exists")
	if not FileAccess.file_exists(path):
		return
	var image := Image.load_from_file(path)
	_expect(image != null, label + " loads as Image")
	if image != null:
		_expect(image.get_size() == expected_size, "%s size is %s" % [label, expected_size])

func _finish() -> void:
	if failures.is_empty():
		print("[VERIFY] All vertical slice checks passed")
		get_tree().quit(0)
	else:
		print("[VERIFY] Failed checks: %s" % JSON.stringify(failures))
		get_tree().quit(1)
