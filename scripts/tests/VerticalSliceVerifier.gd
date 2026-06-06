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
	await _check_player_animation_contract()
	await _check_projectile_pool_limit()
	_finish()

func _check_data_registry() -> void:
	_expect(DataRegistry.equipment.size() >= 6, "equipment data has at least 6 entries")
	_expect(DataRegistry.resources.size() >= 4, "resource data has at least 4 entries")
	_expect(DataRegistry.enemies.size() >= 6, "enemy data has 6 enemy archetypes")
	_expect(DataRegistry.events.size() >= 4, "event data has random event pool")
	_expect(int(DataRegistry.map_params.get("width_tiles", 0)) >= 100, "wasteland width is at least 100 tiles")
	_expect(int(DataRegistry.map_params.get("height_tiles", 0)) >= 80, "wasteland height is at least 80 tiles")

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

func _finish() -> void:
	if failures.is_empty():
		print("[VERIFY] All vertical slice checks passed")
		get_tree().quit(0)
	else:
		print("[VERIFY] Failed checks: %s" % JSON.stringify(failures))
		get_tree().quit(1)
