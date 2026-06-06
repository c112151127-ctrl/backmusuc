extends Node

var equipment: Dictionary = {}
var resources: Dictionary = {}
var enemies: Dictionary = {}
var map_params: Dictionary = {}
var events: Array = []

func _ready() -> void:
	load_all()

func load_all() -> void:
	var item_data := _load_json("res://data/items/equipment.json")
	equipment = item_data.get("equipment", {})
	resources = item_data.get("resources", {})
	enemies = _load_json("res://data/enemies/enemies.json").get("enemies", {})
	map_params = _load_json("res://data/maps/wasteland_params.json")
	events = _load_json("res://data/maps/events.json").get("events", [])

func get_equipment(item_id: String) -> Dictionary:
	return equipment.get(item_id, {})

func get_resource(item_id: String) -> Dictionary:
	return resources.get(item_id, {})

func get_enemy(enemy_id: String) -> Dictionary:
	return enemies.get(enemy_id, {})

func enemy_ids() -> Array:
	return enemies.keys()

func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_warning("Missing JSON: %s" % path)
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	var text := file.get_as_text()
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Invalid JSON dictionary: %s" % path)
		return {}
	return parsed
