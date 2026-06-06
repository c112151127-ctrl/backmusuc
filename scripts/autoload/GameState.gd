extends Node

signal stats_changed
signal inventory_changed
signal equipment_changed
signal scene_changed(scene_id: String)
signal notification_requested(message: String)

const MAX_HP := 120
const MAX_EP := 60

var current_scene_id := "village"
var active_spawn_point := "default"
var seed := 9527
var level := 1
var hp := MAX_HP
var ep := MAX_EP
var ammo := 18
var scrap := 40
var cores := 2
var crystals := 0
var player_position := Vector2.ZERO
var defeated_enemies := 0
var discovered_events: Array[String] = []
var inventory: Dictionary = {}
var equipment: Dictionary = {
	"weapon": "rust_blade",
	"ranged": "pipe_rifle",
	"armor": "patched_armor",
	"tool": "recycler_glove"
}

func _ready() -> void:
	_ensure_input_actions()
	reset_new_run(false)

func reset_new_run(emit_changes := true) -> void:
	current_scene_id = "village"
	active_spawn_point = "default"
	seed = 9527
	level = 1
	hp = MAX_HP
	ep = MAX_EP
	ammo = 18
	scrap = 40
	cores = 2
	crystals = 0
	defeated_enemies = 0
	discovered_events.clear()
	inventory = {
		"scrap": scrap,
		"ammo": ammo,
		"rust_blade": 1,
		"pipe_rifle": 1,
		"patched_armor": 1,
		"recycler_glove": 1
	}
	if emit_changes:
		_emit_all()

func set_scene(scene_id: String, spawn_point := "default") -> void:
	current_scene_id = scene_id
	active_spawn_point = spawn_point
	scene_changed.emit(scene_id)

func add_item(item_id: String, amount := 1) -> void:
	inventory[item_id] = int(inventory.get(item_id, 0)) + amount
	if item_id == "scrap":
		scrap = int(inventory[item_id])
	if item_id == "ammo":
		ammo = int(inventory[item_id])
	if item_id == "mutant_core":
		cores += amount
	if item_id == "bio_crystal":
		crystals += amount
	inventory_changed.emit()
	stats_changed.emit()

func consume_item(item_id: String, amount := 1) -> bool:
	if int(inventory.get(item_id, 0)) < amount:
		return false
	inventory[item_id] = int(inventory[item_id]) - amount
	if int(inventory[item_id]) <= 0:
		inventory.erase(item_id)
	if item_id == "ammo":
		ammo = int(inventory.get("ammo", 0))
	if item_id == "scrap":
		scrap = int(inventory.get("scrap", 0))
	inventory_changed.emit()
	stats_changed.emit()
	return true

func can_equip(item_id: String) -> bool:
	return inventory.has(item_id) and DataRegistry.get_equipment(item_id).size() > 0

func equip_item(item_id: String) -> bool:
	if not can_equip(item_id):
		notify("沒有可裝備的零件: %s" % item_id)
		return false
	var item := DataRegistry.get_equipment(item_id)
	var slot := String(item.get("slot", "tool"))
	equipment[slot] = item_id
	equipment_changed.emit()
	stats_changed.emit()
	notify("已裝備 %s" % String(item.get("name", item_id)))
	return true

func get_stat_bonus(stat_name: String) -> int:
	var total := 0
	for item_id in equipment.values():
		var item := DataRegistry.get_equipment(String(item_id))
		var stats: Dictionary = item.get("stats", {})
		total += int(stats.get(stat_name, 0))
	return total

func take_damage(amount: int) -> void:
	var reduced: int = max(1, amount - get_stat_bonus("defense"))
	hp = max(0, hp - reduced)
	stats_changed.emit()
	if hp <= 0:
		notify("機體損毀，返回村莊維修")
		hp = MAX_HP
		set_scene("village", "clinic")
		SceneRouter.change_to("village", "clinic")

func heal_full() -> void:
	hp = MAX_HP
	ep = MAX_EP
	stats_changed.emit()

func spend_ammo(amount := 1) -> bool:
	return consume_item("ammo", amount)

func record_enemy_defeated() -> void:
	defeated_enemies += 1
	if defeated_enemies % 3 == 0:
		add_item("ammo", 4)
		notify("近戰回收成功，獲得彈藥 x4")

func notify(message: String) -> void:
	notification_requested.emit(message)

func get_save_data() -> Dictionary:
	return {
		"version": 1,
		"player": {
			"health": hp,
			"energy": ep,
			"position_x": player_position.x,
			"position_y": player_position.y
		},
		"inventory": inventory,
		"equipment": equipment,
		"scene": current_scene_id,
		"spawn_point": active_spawn_point,
		"seed": seed,
		"level": level,
		"defeated_enemies": defeated_enemies,
		"discovered_events": discovered_events
	}

func load_save_data(data: Dictionary) -> bool:
	if not data.has("player") or not data.has("inventory") or not data.has("equipment"):
		return false
	var player: Dictionary = data.get("player", {})
	hp = int(player.get("health", MAX_HP))
	ep = int(player.get("energy", MAX_EP))
	player_position = Vector2(float(player.get("position_x", 0.0)), float(player.get("position_y", 0.0)))
	inventory = data.get("inventory", {})
	equipment = data.get("equipment", equipment)
	current_scene_id = String(data.get("scene", "village"))
	active_spawn_point = String(data.get("spawn_point", "default"))
	seed = int(data.get("seed", 9527))
	level = int(data.get("level", 1))
	defeated_enemies = int(data.get("defeated_enemies", 0))
	discovered_events.assign(data.get("discovered_events", []))
	ammo = int(inventory.get("ammo", 0))
	scrap = int(inventory.get("scrap", 0))
	_emit_all()
	return true

func _emit_all() -> void:
	stats_changed.emit()
	inventory_changed.emit()
	equipment_changed.emit()

func _ensure_input_actions() -> void:
	_register_key("move_up", KEY_W)
	_register_key("move_down", KEY_S)
	_register_key("move_left", KEY_A)
	_register_key("move_right", KEY_D)
	_register_key("interact", KEY_E)
	_register_key("open_inventory", KEY_I)
	_register_key("save_game", KEY_F5)
	_register_key("load_game", KEY_F9)
	_register_key("swap_weapon", KEY_Q)
	_register_key("attack_melee", KEY_SPACE)
	_register_mouse("attack_melee", MOUSE_BUTTON_LEFT)
	_register_mouse("attack_ranged", MOUSE_BUTTON_RIGHT)
	_register_key("attack_ranged", KEY_K)
	_register_key("dash", KEY_SHIFT)

func _register_key(action_name: String, physical_key: Key) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	for event in InputMap.action_get_events(action_name):
		if event is InputEventKey and event.physical_keycode == physical_key:
			return
	var event := InputEventKey.new()
	event.physical_keycode = physical_key
	event.keycode = physical_key
	InputMap.action_add_event(action_name, event)

func _register_mouse(action_name: String, button_index: MouseButton) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	for event in InputMap.action_get_events(action_name):
		if event is InputEventMouseButton and event.button_index == button_index:
			return
	var event := InputEventMouseButton.new()
	event.button_index = button_index
	InputMap.action_add_event(action_name, event)
