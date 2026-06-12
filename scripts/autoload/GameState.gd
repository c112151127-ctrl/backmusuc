extends Node

signal stats_changed
signal inventory_changed
signal equipment_changed
signal scene_changed(scene_id: String)
signal notification_requested(message: String)
signal dialogue_requested(speaker: String, role: String, message: String)
signal dialogue_closed
signal feedback_requested(kind: String, strength: float)

const MAX_HP := 120
const MAX_EP := 60
const SAVE_VERSION := 4

var current_scene_id := "village"
var active_spawn_point := "default"
var current_route_id := "scrap_highway"
var seed := 9527
var level := 1
var xp := 0
var upgrade_points := 0
var hp_upgrade_level := 0
var ep_upgrade_level := 0
var attack_upgrade_level := 0
var defense_upgrade_level := 0
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
var death_pending := false
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
	xp = 0
	upgrade_points = 0
	hp_upgrade_level = 0
	ep_upgrade_level = 0
	attack_upgrade_level = 0
	defense_upgrade_level = 0
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
	death_pending = false
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

func get_max_hp() -> int:
	return MAX_HP + hp_upgrade_level * 20

func get_max_ep() -> int:
	return MAX_EP + ep_upgrade_level * 10

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
	notify("路線已切換：%s" % String(route.get("name", route_id)))
	stats_changed.emit()

func mark_intro_seen() -> void:
	intro_seen = true

func add_item(item_id: String, amount := 1) -> void:
	if amount <= 0:
		return
	inventory[item_id] = int(inventory.get(item_id, 0)) + amount
	_sync_resource_counters()
	inventory_changed.emit()
	stats_changed.emit()

func consume_item(item_id: String, amount := 1) -> bool:
	if amount <= 0:
		return true
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
		notify("背包中沒有可裝備的物品：%s" % item_display_name(item_id))
		return false
	var item := DataRegistry.get_equipment(item_id)
	var slot := String(item.get("slot", "tool"))
	equipment[slot] = item_id
	_sync_quick_slot_for_equipment(slot, item_id)
	equipment_changed.emit()
	stats_changed.emit()
	AudioManager.play_sfx("ui")
	notify("已裝備：%s" % String(item.get("name", item_id)))
	return true

func use_quick_slot(index: int) -> bool:
	if index < 0 or index >= quick_slots.size():
		return false
	active_quick_slot = index
	var item_id := String(quick_slots[index])
	if item_id.is_empty():
		notify("快捷欄 %d 是空的" % [index + 1])
		equipment_changed.emit()
		return false
	if not DataRegistry.get_equipment(item_id).is_empty():
		return equip_item(item_id)
	var resource := DataRegistry.get_resource(item_id)
	if not resource.is_empty():
		notify("快捷欄 %d：%s x%d" % [index + 1, String(resource.get("name", item_id)), int(inventory.get(item_id, 0))])
		equipment_changed.emit()
		return true
	notify("快捷欄 %d 無法使用：%s" % [index + 1, item_id])
	equipment_changed.emit()
	return false

func use_next_quick_slot() -> bool:
	if quick_slots.is_empty():
		return false
	return use_quick_slot((active_quick_slot + 1) % quick_slots.size())

func set_quick_slot(index: int, item_id: String) -> bool:
	if index < 0 or index >= quick_slots.size():
		return false
	if not inventory.has(item_id):
		notify("背包中沒有 %s，無法放入快捷欄" % item_display_name(item_id))
		return false
	quick_slots[index] = item_id
	equipment_changed.emit()
	notify("快捷欄 %d 設為 %s" % [index + 1, item_display_name(item_id)])
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
	if mode == "tool":
		return String(equipment.get("tool", "recycler_glove"))
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
	match stat_name:
		"attack":
			total += attack_upgrade_level * 3
		"defense":
			total += defense_upgrade_level * 2
	return total

func take_damage(amount: int) -> void:
	if death_pending:
		return
	var reduced: int = max(1, amount - get_stat_bonus("defense"))
	hp = max(0, hp - reduced)
	request_feedback("player_hit", 0.28)
	AudioManager.play_sfx("hurt")
	stats_changed.emit()
	if hp <= 0:
		death_pending = true
		request_feedback("player_dead", 0.58)
		AudioManager.play_sfx("death")
		notify("R-17 核心停機，維修艙正在回收機體。")
		call_deferred("_finish_death_sequence")

func _finish_death_sequence() -> void:
	await get_tree().create_timer(1.25).timeout
	hp = get_max_hp()
	ep = get_max_ep()
	death_pending = false
	stats_changed.emit()
	SceneRouter.change_to("village", "clinic")

func heal_full() -> void:
	hp = get_max_hp()
	ep = get_max_ep()
	stats_changed.emit()

func spend_ammo(amount := 1) -> bool:
	return consume_item("ammo", amount)

func xp_to_next_level() -> int:
	return 80 + (level - 1) * 45

func add_xp(amount: int) -> void:
	xp += max(0, amount)
	while xp >= xp_to_next_level():
		xp -= xp_to_next_level()
		level += 1
		upgrade_points += 1
		AudioManager.play_sfx("level_up")
		request_feedback("level_up", 0.22)
		notify("R-17 等級提升，獲得 1 點維修升級點。")
	stats_changed.emit()

func spend_upgrade_point(kind: String) -> bool:
	if upgrade_points <= 0:
		notify("沒有可用升級點。")
		return false
	upgrade_points -= 1
	match kind:
		"hp":
			hp_upgrade_level += 1
			hp = get_max_hp()
			notify("維修艙強化完成：HP 上限提升。")
		"ep":
			ep_upgrade_level += 1
			ep = get_max_ep()
			notify("能量核心調校完成：EP 上限提升。")
		"attack":
			attack_upgrade_level += 1
			notify("武器校準完成：攻擊力提升。")
		"defense":
			defense_upgrade_level += 1
			notify("外殼補強完成：防禦提升。")
		_:
			upgrade_points += 1
			notify("未知的升級項目。")
			return false
	stats_changed.emit()
	SaveManager.save_game(false)
	return true

func record_enemy_defeated() -> void:
	defeated_enemies += 1
	add_xp(18)
	advance_quest_counter("defeat_enemy", 1)
	if defeated_enemies % 3 == 0:
		add_item("ammo", 4)
		notify("污染體掉落可用彈藥 x4。")

func start_quest(quest_id: String) -> bool:
	if completed_quests.has(quest_id):
		notify("這份委託已完成。")
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
		notify("委託目標尚未完成。")
		return false
	var quest := DataRegistry.get_quest(active_quest_id)
	for objective in quest.get("objectives", []):
		if String(objective.get("type", "")) == "collect":
			consume_item(String(objective.get("item", "")), int(objective.get("amount", 0)))
	var reward: Dictionary = quest.get("reward", {})
	for item_id in reward.keys():
		add_item(String(item_id), int(reward[item_id]))
	var completed_id := active_quest_id
	completed_quests.append(completed_id)
	active_quest_id = ""
	add_xp(35)
	notify("委託完成：%s" % String(quest.get("name", completed_id)))
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
	return "%s：%s" % [String(quest.get("name", active_quest_id)), _join_strings(parts, "、")]

func notify(message: String) -> void:
	notification_requested.emit(message)

func request_feedback(kind: String, strength: float) -> void:
	feedback_requested.emit(kind, strength)

func close_dialogue() -> void:
	dialogue_closed.emit()

func talk_to_npc(npc_id: String) -> bool:
	var npc := DataRegistry.get_npc(npc_id)
	if npc.is_empty():
		notify("未知的 NPC：%s" % npc_id)
		return false
	var first_time := not talked_npcs.has(npc_id)
	var message := String(npc.get("line", "")) if first_time else String(npc.get("repeat_line", npc.get("line", "")))
	if first_time:
		talked_npcs.append(npc_id)
		var reward: Dictionary = npc.get("reward", {})
		for item_id in reward.keys():
			add_item(String(item_id), int(reward[item_id]))
	dialogue_requested.emit(String(npc.get("name", npc_id)), String(npc.get("role", "倖存者")), message)
	inventory_changed.emit()
	stats_changed.emit()
	return true

func get_save_data() -> Dictionary:
	return {
		"version": SAVE_VERSION,
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
		"xp": xp,
		"upgrade_points": upgrade_points,
		"hp_upgrade_level": hp_upgrade_level,
		"ep_upgrade_level": ep_upgrade_level,
		"attack_upgrade_level": attack_upgrade_level,
		"defense_upgrade_level": defense_upgrade_level,
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
	var loaded_inventory = data.get("inventory", {})
	if typeof(loaded_inventory) == TYPE_DICTIONARY:
		inventory = loaded_inventory
	var loaded_equipment = data.get("equipment", {})
	if typeof(loaded_equipment) == TYPE_DICTIONARY:
		equipment = loaded_equipment
	current_scene_id = String(data.get("scene", "village"))
	active_spawn_point = String(data.get("spawn_point", "default"))
	current_route_id = String(data.get("route", "scrap_highway"))
	seed = int(data.get("seed", 9527))
	level = int(data.get("level", 1))
	xp = int(data.get("xp", 0))
	upgrade_points = int(data.get("upgrade_points", 0))
	hp_upgrade_level = int(data.get("hp_upgrade_level", 0))
	ep_upgrade_level = int(data.get("ep_upgrade_level", 0))
	attack_upgrade_level = int(data.get("attack_upgrade_level", 0))
	defense_upgrade_level = int(data.get("defense_upgrade_level", 0))
	intro_seen = bool(data.get("intro_seen", false))
	death_pending = false
	defeated_enemies = int(data.get("defeated_enemies", 0))
	discovered_events = _string_array(data.get("discovered_events", []))
	talked_npcs = _string_array(data.get("talked_npcs", []))
	active_quest_id = String(data.get("active_quest_id", ""))
	completed_quests = _string_array(data.get("completed_quests", []))
	var loaded_progress = data.get("quest_progress", {})
	if typeof(loaded_progress) == TYPE_DICTIONARY:
		quest_progress = loaded_progress
	var loaded_route_states = data.get("route_states", {})
	if typeof(loaded_route_states) == TYPE_DICTIONARY:
		route_states = loaded_route_states
	quick_slots = _string_array(data.get("quick_slots", ["rust_blade", "pipe_rifle", "recycler_glove", "ammo"]))
	while quick_slots.size() < 4:
		quick_slots.append("")
	active_quick_slot = clampi(int(data.get("active_quick_slot", 0)), 0, max(0, quick_slots.size() - 1))
	_sync_resource_counters()
	hp = clampi(hp, 0, get_max_hp())
	ep = clampi(ep, 0, get_max_ep())
	_emit_all()
	return true

func _string_array(source) -> Array[String]:
	var result: Array[String] = []
	if typeof(source) != TYPE_ARRAY:
		return result
	for value in source:
		result.append(String(value))
	return result

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

func _join_strings(parts: Array[String], delimiter: String) -> String:
	var result := ""
	for i in range(parts.size()):
		if i > 0:
			result += delimiter
		result += parts[i]
	return result

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
