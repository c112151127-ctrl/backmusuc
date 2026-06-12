extends Node2D

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const HUD_SCENE := preload("res://scenes/ui/HUD.tscn")
const PIXEL := preload("res://scripts/utils/PixelArtFactory.gd")
const ASSET_LOADER := preload("res://scripts/utils/RuntimeAssetLoader.gd")
const BACKDROP_SCRIPT := preload("res://scripts/systems/WorldBackdrop.gd")
const INTERACTABLE_SCRIPT := preload("res://scripts/components/Interactable.gd")
const ROUTE_GATE_SCRIPT := preload("res://scripts/components/RouteGate.gd")
const DIALOGUE_NPC_SCRIPT := preload("res://scripts/components/DialogueNpc.gd")
const INVENTORY_SCRIPT := preload("res://scripts/systems/InventorySystem.gd")
const PROJECTILE_POOL_SCRIPT := preload("res://scripts/systems/ProjectilePool.gd")
const WORLD_PROP_SCRIPT := preload("res://scripts/components/WorldProp.gd")

const MAP_TILES := Vector2i(78, 56)
const TILE_SIZE := 32
const WORLD_RECT := Rect2(Vector2(48, 48), Vector2(MAP_TILES.x * TILE_SIZE - 96, MAP_TILES.y * TILE_SIZE - 96))

const STATION_TEXTURES := {
	"forge": "res://assets/sprites/structures/forge.png",
	"craft": "res://assets/sprites/structures/craft.png",
	"shop": "res://assets/sprites/structures/shop.png",
	"mod": "res://assets/sprites/structures/mod_station.png",
	"recycle": "res://assets/sprites/structures/recycle_machine.png",
	"save": "res://assets/sprites/structures/save_station.png",
	"to_guild": "res://assets/sprites/structures/guild_gate.png",
	"route_gate": "res://assets/sprites/structures/wasteland_gate.png"
}

var player: Node2D

func _ready() -> void:
	y_sort_enabled = true
	GameState.current_scene_id = "village"
	AudioManager.play_music("village")

	var backdrop: Node2D = BACKDROP_SCRIPT.new()
	backdrop.setup("village", MAP_TILES, 137)
	add_child(backdrop)
	_add_boundaries(Vector2(MAP_TILES.x * TILE_SIZE, MAP_TILES.y * TILE_SIZE))
	_add_decor()
	_add_stations()
	_add_route_gates()
	_spawn_npcs()
	_add_projectile_pool(200)
	_spawn_player(_spawn_position())
	add_child(HUD_SCENE.instantiate())
	GameState.notify("村莊據點：找 NPC 了解操作，或從四個出口進入不同廢土區。")

func _spawn_position() -> Vector2:
	match GameState.active_spawn_point:
		"from_wasteland":
			return Vector2(1248, 980)
		"from_guild":
			return Vector2(1580, 820)
		"clinic":
			return Vector2(1040, 1030)
		"saved":
			return GameState.player_position
		_:
			return Vector2(1248, 920)

func _spawn_player(default_position: Vector2) -> void:
	player = PLAYER_SCENE.instantiate()
	player.global_position = default_position
	add_child(player)
	if player.has_method("set_world_bounds"):
		player.set_world_bounds(WORLD_RECT)

func _add_projectile_pool(limit: int) -> void:
	var pool: Node = PROJECTILE_POOL_SCRIPT.new()
	pool.max_projectiles = limit
	add_child(pool)

func _add_stations() -> void:
	_add_station("forge", "鍛造：廢鐵換彈藥", Vector2(1248, 370), Color8(102, 68, 45))
	_add_station("craft", "合成：製作近戰武器", Vector2(680, 650), Color8(72, 92, 96))
	_add_station("shop", "商店：購買彈藥", Vector2(1810, 650), Color8(93, 75, 47))
	_add_station("mod", "改裝：升級遠程武器", Vector2(720, 1130), Color8(54, 77, 91))
	_add_station("recycle", "拆解：核心換材料", Vector2(1248, 1180), Color8(69, 88, 78))
	_add_station("save", "存檔：維修與保存", Vector2(1760, 1130), Color8(42, 92, 108))
	_add_station("to_guild", "前往冒險公會", Vector2(2060, 900), Color8(90, 82, 120))

func _add_route_gates() -> void:
	_add_route_gate("crystal_scar", "北門：紫晶裂隙", Vector2(1248, 170))
	_add_route_gate("scrap_highway", "南門：廢鐵公路", Vector2(1248, 1560))
	_add_route_gate("toxic_marsh", "西門：毒沼排水區", Vector2(230, 900))
	_add_route_gate("old_factory", "東門：舊工廠外圍", Vector2(2260, 900))

func _add_station(id: String, label: String, pos: Vector2, color: Color) -> void:
	var node := Node2D.new()
	node.position = pos
	node.y_sort_enabled = true
	add_child(node)
	var sprite := Sprite2D.new()
	var texture := _station_texture(id)
	sprite.texture = texture if texture != null else PIXEL.new().make_texture(Vector2i(180, 110), [color.darkened(0.35), color, color.lightened(0.18)], id.length())
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var texture_size := sprite.texture.get_size()
	sprite.centered = false
	sprite.position = Vector2(-texture_size.x * 0.5, -texture_size.y)
	node.add_child(sprite)
	var interactable: Area2D = INTERACTABLE_SCRIPT.new()
	interactable.interaction_id = id
	interactable.prompt = label
	interactable.radius = max(texture_size.x, texture_size.y) * 0.36
	interactable.interacted.connect(_on_station_interacted)
	node.add_child(interactable)

func _add_route_gate(route_id: String, label: String, pos: Vector2) -> void:
	var node := Node2D.new()
	node.position = pos
	node.y_sort_enabled = true
	add_child(node)
	var sprite := Sprite2D.new()
	sprite.texture = _station_texture("route_gate")
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if sprite.texture != null:
		var texture_size := sprite.texture.get_size()
		sprite.centered = false
		sprite.position = Vector2(-texture_size.x * 0.5, -texture_size.y)
	node.add_child(sprite)
	var gate = ROUTE_GATE_SCRIPT.new()
	gate.setup_route(route_id, label, Vector2.ZERO, 76.0)
	gate.interacted.connect(_on_route_gate_interacted)
	node.add_child(gate)

func _station_texture(id: String) -> Texture2D:
	var path := String(STATION_TEXTURES.get(id, ""))
	return ASSET_LOADER.load_png(path) if not path.is_empty() else null

func _add_decor() -> void:
	var props := [
		["scrap_wall", Vector2(440, 330), true, Vector2i(110, 72)],
		["scrap_wall", Vector2(2050, 330), true, Vector2i(110, 72)],
		["rust_rock", Vector2(920, 360), true, Vector2i(78, 62)],
		["dead_tree", Vector2(1510, 500), true, Vector2i(72, 110)],
		["road_marker", Vector2(1248, 760), false, Vector2i(44, 58)],
		["road_marker", Vector2(1248, 1060), false, Vector2i(44, 58)],
		["signal_pylon", Vector2(2050, 1240), true, Vector2i(72, 128)],
		["toxic_pool", Vector2(430, 1220), false, Vector2i(86, 50)],
		["wreck", Vector2(1980, 1420), true, Vector2i(116, 80)]
	]
	for prop_data in props:
		var prop: StaticBody2D = WORLD_PROP_SCRIPT.new()
		prop.setup(String(prop_data[0]), bool(prop_data[2]), prop_data[3])
		prop.global_position = prop_data[1]
		add_child(prop)

func _add_boundaries(world_size: Vector2) -> void:
	_add_boundary(Vector2(world_size.x * 0.5, 12), Vector2(world_size.x, 24))
	_add_boundary(Vector2(world_size.x * 0.5, world_size.y - 12), Vector2(world_size.x, 24))
	_add_boundary(Vector2(12, world_size.y * 0.5), Vector2(24, world_size.y))
	_add_boundary(Vector2(world_size.x - 12, world_size.y * 0.5), Vector2(24, world_size.y))

func _add_boundary(pos: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.add_to_group("obstacle")
	body.position = pos
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	add_child(body)

func _spawn_npcs() -> void:
	for npc_data in DataRegistry.npcs_for_scene("village"):
		var npc: Area2D = DIALOGUE_NPC_SCRIPT.new()
		npc.setup(npc_data)
		add_child(npc)

func _on_route_gate_interacted(interaction_id: String) -> void:
	var route_id := interaction_id.replace("route:", "")
	GameState.set_current_route(route_id)
	SceneRouter.change_to("wasteland", "from_village")

func _on_station_interacted(id: String) -> void:
	match id:
		"forge":
			INVENTORY_SCRIPT.forge_ammo_pack()
		"craft":
			if INVENTORY_SCRIPT.craft_basic_upgrade():
				GameState.equip_item("spark_cutter")
		"shop":
			INVENTORY_SCRIPT.shop_buy_ammo()
		"mod":
			if GameState.can_equip("coil_launcher"):
				GameState.equip_item("coil_launcher")
			elif INVENTORY_SCRIPT.craft_coil_launcher():
				GameState.equip_item("coil_launcher")
		"recycle":
			INVENTORY_SCRIPT.recycle_core()
		"save":
			GameState.heal_full()
			SaveManager.save_game(true)
		"to_guild":
			SceneRouter.change_to("guild", "from_village")
