extends Node

signal stats_changed
signal inventory_changed
signal equipment_changed
signal scene_changed(scene_id: String)
signal notification_requested(message: String)
signal dialogue_requested(speaker: String, role: String, message: String)
signal dialogue_closed

const MAX_HP := 120
const MAX_EP := 60

var current_scene_id := "village"
var active_spawn_point := "default"
var current_route_id := "scrap_highway"
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
var talked_npcs: Array[String] = []
var active_quest_id := ""
var completed_quests: Array[String] = []
var quest_progress: Dictionary = {}
var route_states: Dictionary = {}
var intro_seen := false
var inventory: Dictionary = {}
var quick_slots: Array[String] = ["rust_blade", "pipe_rifle", "recycler_glove", "ammo"]
var active_quick_slot := 0
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
	current_route_id = "scrap_highway"
	seed = 9527
	level = 1
	hp = MAX_HP
	ep = MAX_EP
	ammo = 18
	scrap = 40
	cores = 2
	crystals = 0
	player_position = Vector2.ZERO
	defeated_enemies = 0
	discovered_events.clear()
	talked_npcs.clear()
	active_quest_id = ""
	completed_quests.clear()
	quest_progress.clear()
	route_states.clear()
	intro_seen = false
	active_quick_slot = 0
	inventory = {
		"scrap": scrap,
		"ammo": ammo,
		"mutant_core": cores,
		"rust_blade": 1,
		"pipe_rifle": 1,
		"patched_armor": 1,
		"recycler_glove": 1
	}
	quick_slots = ["rust_blade", "pipe_rifle", "recycler_glove", "ammo"]
	equipment = {
		"weapon": "rust_blade",
		"ranged": "pipe_rifle",
		"armor": "patched_armor",
		"tool": "recycler_glove"
	}
	if emit_changes:
		_emit_all()

func set_scene(scene_id: String, spawn_point := "default") -> void:
	current_scene_id = scene_id
	active_spawn_point = spawn_point
	scene_changed.emit(scene_id)

func set_current_route(route_id: String) -> void:
	if DataRegistry.get_wasteland_route(route_id).is_empty():
		notify("未知的廢土路線：%s" % route_id)
		return
	current_route_id = route_id
	var route := DataRegistry.get_wasteland_route(route_id)
	notify("已標記路線：%s" % String(route.get("name", route_id)))
	stats_changed.emit()

func mark_intro_seen() -> void:
	intro_seen = true

func add_item(item_id: String, amount := 1) -> void:
	inventory[item_id] = int(inventory.get(item_id, 0)) + amount
	_sync_resource_counters()
	inventory_changed.emit()
	stats_changed.emit()

func consume_item(item_id: String, amount := 1) -> bool:
	if int(inventory.get(item_id, 0)) < amount:
		return false
	inventory[item_id] = int(inventory[item_id]) - amount
	if int(inventory[item_id]) <= 0:
		inventory.erase(item_id)
	_sync_resource_counters()
	inventory_changed.emit()
	stats_changed.emit()
	return true

func can_equip(item_id: String) -> bool:
	return inventory.has(item_id) and not DataRegistry.get_equipment(item_id).is_empty()

func equip_item(item_id: String) -> bool:
	if not can_equip(item_id):
		notify("背包裡沒有可裝備物品：%s" % item_display_name(item_id))
		return false
	var item := DataRegistry.get_equipment(item_id)
	var slot := String(item.get("slot", "tool"))
	equipment[slot] = item_id
	_sync_quick_slot_for_equipment(slot, item_id)
	equipment_changed.emit()
	stats_changed.emit()
	notify("已裝備：%s" % String(item.get("name", item_id)))
	return true

func use_quick_slot(index: int) -> bool:
	if index < 0 or index >= quick_slots.size():
		return false
	active_quick_slot = index
	var item_id := String(quick_slots[index])
	if item_id.is_empty():
		notify("快捷列 %d 是空的。" % [index + 1])
		equipment_changed.emit()
		return false
	if not DataRegistry.get_equipment(item_id).is_empty():
		return equip_item(item_id)
	var resource := DataRegistry.get_resource(item_id)
	if not resource.is_empty():
		notify("快捷列 %d：%s x%d" % [index + 1, String(resource.get("name", item_id)), int(inventory.get(item_id, 0))])
		equipment_changed.emit()
		return true
	notify("快捷列 %d 無法使用：%s" % [index + 1, item_id])
	equipment_changed.emit()
	return false

func use_next_quick_slot() -> bool:
	if quick_slots.is_empty():
		return false
	var next_index := (active_quick_slot + 1) % quick_slots.size()
	return use_quick_slot(next_index)

func set_quick_slot(index: int, item_id: String) -> bool:
	if index < 0 or index >= quick_slots.size():
		return false
	if not inventory.has(item_id):
		notify("背包裡沒有 %s，無法放到快捷列。" % item_display_name(item_id))
		return false
	quick_slots[index] = item_id
	equipment_changed.emit()
	notify("快捷列 %d 設為 %s" % [index + 1, item_display_name(item_id)])
	return true

func active_quick_item_id() -> String:
	if active_quick_slot < 0 or active_quick_slot >= quick_slots.size():
		return String(equipment.get("weapon", "rust_blade"))
	return String(quick_slots[active_quick_slot])

func active_attack_mode() -> String:
	var item_id := active_quick_item_id()
	var item := DataRegistry.get_equipment(item_id)
	if item.is_empty():
		item = DataRegistry.get_equipment(String(equipment.get("weapon", "rust_blade")))
	return String(item.get("attack_mode", "melee"))

func active_attack_item_id() -> String:
	var item_id := active_quick_item_id()
	if not DataRegistry.get_equipment(item_id).is_empty():
		return item_id
	var mode := active_attack_mode()
	if mode == "ranged":
		return String(equipment.get("ranged", "pipe_rifle"))
	return String(equipment.get("weapon", "rust_blade"))

func equipped_slot_name(slot: String) -> String:
	return item_display_name(String(equipment.get(slot, "")))

func item_display_name(item_id: String) -> String:
	var equipment_data := DataRegistry.get_equipment(item_id)
	if not equipment_data.is_empty():
		return String(equipment_data.get("name", item_id))
	var resource := DataRegistry.get_resource(item_id)
	if not resource.is_empty():
		return String(resource.get("name", item_id))
	return item_id

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
		notify("R-17 機體停機，維修機已將你送回村莊維修艙。")
		hp = MAX_HP
		call_deferred("_return_to_clinic")

func _return_to_clinic() -> void:
	SceneRouter.change_to("village", "clinic")

func heal_full() -> void:
	hp = MAX_HP
	ep = MAX_EP
	stats_changed.emit()

func spend_ammo(amount := 1) -> bool:
	return consume_item("ammo", amount)

func record_enemy_defeated() -> void:
	defeated_enemies += 1
	advance_quest_counter("defeat_enemy", 1)
	if defeated_enemies % 3 == 0:
		add_item("ammo", 4)
		notify("近戰清出補給：彈藥 x4")

func start_quest(quest_id: String) -> bool:
	if completed_quests.has(quest_id):
		notify("這個委託已經完成。")
		return false
	var quest := DataRegistry.get_quest(quest_id)
	if quest.is_empty():
		notify("未知的委託：%s" % quest_id)
		return false
	active_quest_id = quest_id
	var route_id := String(quest.get("route", ""))
	if not route_id.is_empty():
		current_route_id = route_id
	for objective in quest.get("objectives", []):
		if String(objective.get("type", "")) == "defeat":
			var counter := String(objective.get("counter", "defeat_enemy"))
			quest_progress[counter] = int(quest_progress.get(counter, 0))
	notify("已接下委託：%s" % String(quest.get("name", quest_id)))
	_emit_all()
	SaveManager.save_game(false)
	return true

func advance_quest_counter(counter_id: String, amount := 1) -> void:
	if active_quest_id.is_empty():
		return
	quest_progress[counter_id] = int(quest_progress.get(counter_id, 0)) + amount
	stats_changed.emit()

func is_active_quest_ready() -> bool:
	if active_quest_id.is_empty():
		return false
	var quest := DataRegistry.get_quest(active_quest_id)
	if quest.is_empty():
		return false
	for objective in quest.get("objectives", []):
		var kind := String(objective.get("type", ""))
		var amount := int(objective.get("amount", 0))
		if kind == "collect":
			var item_id := String(objective.get("item", ""))
			if int(inventory.get(item_id, 0)) < amount:
				return false
		elif kind == "defeat":
			var counter := String(objective.get("counter", "defeat_enemy"))
			if int(quest_progress.get(counter, 0)) < amount:
				return false
	return true

func complete_active_quest() -> bool:
	if active_quest_id.is_empty():
		notify("目前沒有可交付的委託。")
		return false
	if not is_active_quest_ready():
		notify("委託條件尚未完成。")
		return false
	var quest := DataRegistry.get_quest(active_quest_id)
	for objective in quest.get("objectives", []):
		if String(objective.get("type", "")) == "collect":
			consume_item(String(objective.get("item", "")), int(objective.get("amount", 0)))
	var reward: Dictionary = quest.get("reward", {})
	for item_id in reward.keys():
		add_item(String(item_id), int(reward[item_id]))
	completed_quests.append(active_quest_id)
	notify("委託完成：%s" % String(quest.get("name", active_quest_id)))
	active_quest_id = ""
	_emit_all()
	SaveManager.save_game(false)
	return true

func active_quest_summary() -> String:
	if active_quest_id.is_empty():
		return "無"
	var quest := DataRegistry.get_quest(active_quest_id)
	if quest.is_empty():
		return active_quest_id
	var parts: Array[String] = []
	for objective in quest.get("objectives", []):
		var kind := String(objective.get("type", ""))
		var amount := int(objective.get("amount", 0))
		if kind == "collect":
			var item_id := String(objective.get("item", ""))
			parts.append("%s %d/%d" % [item_display_name(item_id), int(inventory.get(item_id, 0)), amount])
		elif kind == "defeat":
			var counter := String(objective.get("counter", "defeat_enemy"))
			parts.append("擊倒污染體 %d/%d" % [int(quest_progress.get(counter, 0)), amount])
	return "%s：%s" % [String(quest.get("name", active_quest_id)), "、".join(parts)]

func notify(message: String) -> void:
	notification_requested.emit(message)

func close_dialogue() -> void:
	dialogue_closed.emit()

func talk_to_npc(npc_id: String) -> bool:
	var npc := DataRegistry.get_npc(npc_id)
	if npc.is_empty():
		notify("找不到 NPC：%s" % npc_id)
		return false
	var first_time := not talked_npcs.has(npc_id)
	var message := String(npc.get("line", "")) if first_time else String(npc.get("repeat_line", npc.get("line", "")))
	if first_time:
		talked_npcs.append(npc_id)
		var reward: Dictionary = npc.get("reward", {})
		for item_id in reward.keys():
			add_item(String(item_id), int(reward[item_id]))
	dialogue_requested.emit(String(npc.get("name", npc_id)), String(npc.get("role", "居民")), message)
	inventory_changed.emit()
	stats_changed.emit()
	return true

func get_save_data() -> Dictionary:
	return {
		"version": 2,
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
		"route": current_route_id,
		"seed": seed,
		"level": level,
		"intro_seen": intro_seen,
		"defeated_enemies": defeated_enemies,
		"discovered_events": discovered_events,
		"talked_npcs": talked_npcs,
		"active_quest_id": active_quest_id,
		"completed_quests": completed_quests,
		"quest_progress": quest_progress,
		"route_states": route_states,
		"quick_slots": quick_slots,
		"active_quick_slot": active_quick_slot
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
	current_route_id = String(data.get("route", "scrap_highway"))
	seed = int(data.get("seed", 9527))
	level = int(data.get("level", 1))
	intro_seen = bool(data.get("intro_seen", false))
	defeated_enemies = int(data.get("defeated_enemies", 0))
	discovered_events.assign(data.get("discovered_events", []))
	talked_npcs.assign(data.get("talked_npcs", []))
	active_quest_id = String(data.get("active_quest_id", ""))
	completed_quests.assign(data.get("completed_quests", []))
	quest_progress = data.get("quest_progress", {})
	route_states = data.get("route_states", {})
	quick_slots.assign(data.get("quick_slots", ["rust_blade", "pipe_rifle", "recycler_glove", "ammo"]))
	active_quick_slot = int(data.get("active_quick_slot", 0))
	_sync_resource_counters()
	_emit_all()
	return true

func _emit_all() -> void:
	stats_changed.emit()
	inventory_changed.emit()
	equipment_changed.emit()

func _sync_resource_counters() -> void:
	ammo = int(inventory.get("ammo", 0))
	scrap = int(inventory.get("scrap", 0))
	cores = int(inventory.get("mutant_core", 0))
	crystals = int(inventory.get("bio_crystal", 0))

func _sync_quick_slot_for_equipment(slot: String, item_id: String) -> void:
	var index := -1
	match slot:
		"weapon":
			index = 0
		"ranged":
			index = 1
		"tool":
			index = 2
	if index >= 0 and index < quick_slots.size():
		quick_slots[index] = item_id

func _ensure_input_actions() -> void:
	_register_key("move_up", KEY_W)
	_register_key("move_down", KEY_S)
	_register_key("move_left", KEY_A)
	_register_key("move_right", KEY_D)
	_register_key("interact", KEY_E)
	_register_key("open_inventory", KEY_I)
	_register_key("open_inventory", KEY_TAB)
	_register_key("save_game", KEY_F5)
	_register_key("load_game", KEY_F9)
	_register_key("toggle_minimap", KEY_M)
	_register_key("toggle_help", KEY_H)
	_register_key("swap_weapon", KEY_Q)
	_register_key("quick_slot_1", KEY_1)
	_register_key("quick_slot_2", KEY_2)
	_register_key("quick_slot_3", KEY_3)
	_register_key("quick_slot_4", KEY_4)
	_register_key("primary_attack", KEY_J)
	_register_mouse("primary_attack", MOUSE_BUTTON_LEFT)
	_unregister_mouse("attack_melee", MOUSE_BUTTON_LEFT)
	_unregister_mouse("attack_ranged", MOUSE_BUTTON_LEFT)
	_register_key("attack_melee", KEY_SPACE)
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

func _unregister_mouse(action_name: String, button_index: MouseButton) -> void:
	if not InputMap.has_action(action_name):
		return
	for event in InputMap.action_get_events(action_name):
		if event is InputEventMouseButton and event.button_index == button_index:
			InputMap.action_erase_event(action_name, event)
			return
