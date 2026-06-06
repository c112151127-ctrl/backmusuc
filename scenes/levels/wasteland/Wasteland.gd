extends Node2D

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const HUD_SCENE := preload("res://scenes/ui/HUD.tscn")
const PIXEL := preload("res://scripts/utils/PixelArtFactory.gd")
const BACKDROP_SCRIPT := preload("res://scripts/systems/WorldBackdrop.gd")
const INTERACTABLE_SCRIPT := preload("res://scripts/components/Interactable.gd")
const PICKUP_SCRIPT := preload("res://scripts/components/Pickup.gd")
const ENEMY_SCRIPT := preload("res://scripts/components/Enemy.gd")
const WORLD_PROP_SCRIPT := preload("res://scripts/components/WorldProp.gd")
const LEVEL_GENERATOR_SCRIPT := preload("res://scripts/systems/LevelGenerator.gd")
const PROJECTILE_POOL_SCRIPT := preload("res://scripts/systems/ProjectilePool.gd")

var player: Node2D
var world_size := Vector2(3200, 2560)

func _ready() -> void:
	y_sort_enabled = true
	GameState.current_scene_id = "wasteland"
	var params := DataRegistry.map_params
	var tile_size := int(params.get("tile_size", 32))
	var size_tiles := Vector2i(int(params.get("width_tiles", 100)), int(params.get("height_tiles", 80)))
	world_size = Vector2(size_tiles.x * tile_size, size_tiles.y * tile_size)
	var backdrop: Node2D = BACKDROP_SCRIPT.new()
	backdrop.setup("wasteland", size_tiles, GameState.seed)
	add_child(backdrop)
	_add_projectile_pool(int(params.get("projectile_limit", 200)))
	_spawn_player(Vector2(world_size.x * 0.5, world_size.y - 180))
	_spawn_exit()
	_spawn_props()
	_spawn_resources()
	_spawn_events()
	_spawn_enemies()
	add_child(HUD_SCENE.instantiate())
	GameState.notify("廢土外圍：回收資源、處理污染體，完成後從南側返回村莊")

func _spawn_player(default_position: Vector2) -> void:
	player = PLAYER_SCENE.instantiate()
	if GameState.active_spawn_point == "saved" and GameState.player_position != Vector2.ZERO:
		player.global_position = GameState.player_position
	else:
		player.global_position = default_position
	add_child(player)

func _add_projectile_pool(limit: int) -> void:
	var pool: Node = PROJECTILE_POOL_SCRIPT.new()
	pool.max_projectiles = limit
	add_child(pool)

func _spawn_exit() -> void:
	var exit: Area2D = INTERACTABLE_SCRIPT.new()
	exit.interaction_id = "to_village"
	exit.prompt = "返回村莊"
	exit.position = Vector2(world_size.x * 0.5, world_size.y - 90)
	exit.interacted.connect(func(_id: String) -> void: SceneRouter.change_to("village", "from_wasteland"))
	add_child(exit)
	var label := Label.new()
	label.text = "返回村莊"
	label.position = exit.position + Vector2(-44, -70)
	label.add_theme_font_size_override("font_size", 20)
	add_child(label)

func _spawn_resources() -> void:
	var count := int(DataRegistry.map_params.get("resource_nodes", 42))
	var positions := LEVEL_GENERATOR_SCRIPT.seeded_positions(count, Rect2(180, 180, world_size.x - 360, world_size.y - 520), GameState.seed + 11, 90)
	var ids: Array[String] = ["scrap", "ammo", "bio_crystal", "mutant_core"]
	for i in positions.size():
		var id: String = ids[i % ids.size()]
		var amount := 1 + (i % 4)
		if id == "mutant_core":
			amount = 1
		var pickup: Area2D = PICKUP_SCRIPT.new()
		pickup.setup(id, amount)
		pickup.global_position = positions[i]
		add_child(pickup)

func _spawn_props() -> void:
	var count := int(DataRegistry.map_params.get("prop_nodes", 72))
	var positions := LEVEL_GENERATOR_SCRIPT.seeded_positions(count, Rect2(160, 180, world_size.x - 320, world_size.y - 860), GameState.seed + 301, 78)
	var prop_ids: Array[String] = ["rust_rock", "dead_tree", "scrap_wall", "toxic_pool", "wreck", "signal_pylon", "road_marker"]
	for i in positions.size():
		var id := prop_ids[i % prop_ids.size()]
		var blocking := id != "toxic_pool" and id != "road_marker"
		var size := _prop_size(id, i)
		var prop: StaticBody2D = WORLD_PROP_SCRIPT.new()
		prop.setup(id, blocking, size)
		prop.global_position = positions[i]
		add_child(prop)

func _prop_size(id: String, index: int) -> Vector2i:
	match id:
		"dead_tree":
			return Vector2i(46 + (index % 3) * 8, 88 + (index % 4) * 10)
		"scrap_wall":
			return Vector2i(82, 58)
		"toxic_pool":
			return Vector2i(72, 42)
		"wreck":
			return Vector2i(92, 66)
		"signal_pylon":
			return Vector2i(54, 112)
		"road_marker":
			return Vector2i(34, 48)
		_:
			return Vector2i(56 + (index % 2) * 14, 48 + (index % 3) * 8)

func _spawn_events() -> void:
	var positions := LEVEL_GENERATOR_SCRIPT.seeded_positions(10, Rect2(240, 260, world_size.x - 480, world_size.y - 700), GameState.seed + 25, 220)
	for i in min(positions.size(), DataRegistry.events.size()):
		var event_data: Dictionary = DataRegistry.events[i % DataRegistry.events.size()]
		var event_id := String(event_data.get("id", "event_%d" % i))
		var event_name := String(event_data.get("name", "廢土事件"))
		var node: Area2D = INTERACTABLE_SCRIPT.new()
		node.interaction_id = "event:" + event_id
		node.prompt = event_name
		node.position = positions[i]
		node.interacted.connect(_on_event_interacted)
		add_child(node)
		var marker := Sprite2D.new()
		marker.texture = PIXEL.new().make_texture(Vector2i(42, 42), [Color8(84, 54, 102), Color8(182, 84, 205), Color8(82, 207, 126)], i)
		marker.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		marker.position = positions[i]
		add_child(marker)
		var label := Label.new()
		label.text = event_name
		label.position = positions[i] + Vector2(-42, -54)
		label.add_theme_font_size_override("font_size", 14)
		add_child(label)

func _spawn_enemies() -> void:
	var enemy_ids := DataRegistry.enemy_ids()
	if enemy_ids.is_empty():
		return
	var limit := int(DataRegistry.map_params.get("enemy_limit", 30))
	var positions := LEVEL_GENERATOR_SCRIPT.seeded_positions(limit, Rect2(200, 140, world_size.x - 400, world_size.y - 620), GameState.seed + 91, 120)
	for i in min(limit, positions.size()):
		var id := String(enemy_ids[i % enemy_ids.size()])
		var enemy: CharacterBody2D = ENEMY_SCRIPT.new()
		enemy.setup(id, DataRegistry.get_enemy(id), player)
		enemy.global_position = positions[i]
		add_child(enemy)

func _on_event_interacted(interaction_id: String) -> void:
	var event_id := interaction_id.replace("event:", "")
	if GameState.discovered_events.has(event_id):
		GameState.notify("這個事件已經處理過")
		return
	GameState.discovered_events.append(event_id)
	for event_data in DataRegistry.events:
		if String(event_data.get("id", "")) == event_id:
			var reward: Dictionary = event_data.get("reward", {})
			for item_id in reward.keys():
				GameState.add_item(String(item_id), int(reward[item_id]))
			var event_name := String(event_data.get("name", event_id))
			var description := String(event_data.get("description", ""))
			GameState.notify("%s 完成：%s" % [event_name, description])
			return
