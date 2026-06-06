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
		"player": 1
	})
	await _check_scene("guild", GUILD_SCENE, {
		"interactable": 3,
		"player": 1
	})
	_check_save_roundtrip()
	_check_equipment_loop()
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
