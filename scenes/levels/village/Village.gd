extends Node2D

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const HUD_SCENE := preload("res://scenes/ui/HUD.tscn")
const PIXEL := preload("res://scripts/utils/PixelArtFactory.gd")
const ASSET_LOADER := preload("res://scripts/utils/RuntimeAssetLoader.gd")
const BACKDROP_SCRIPT := preload("res://scripts/systems/WorldBackdrop.gd")
const INTERACTABLE_SCRIPT := preload("res://scripts/components/Interactable.gd")
const DIALOGUE_NPC_SCRIPT := preload("res://scripts/components/DialogueNpc.gd")
const INVENTORY_SCRIPT := preload("res://scripts/systems/InventorySystem.gd")
const PROJECTILE_POOL_SCRIPT := preload("res://scripts/systems/ProjectilePool.gd")
const WORLD_PROP_SCRIPT := preload("res://scripts/components/WorldProp.gd")

const MAP_TILES := Vector2i(68, 48)
const TILE_SIZE := 32
const WORLD_RECT := Rect2(Vector2(48, 48), Vector2(MAP_TILES.x * TILE_SIZE - 96, MAP_TILES.y * TILE_SIZE - 96))

const STATION_TEXTURES := {
	"forge": "res://assets/sprites/structures/forge.png",
	"craft": "res://assets/sprites/structures/craft.png",
	"shop": "res://assets/sprites/structures/shop.png",
	"mod": "res://assets/sprites/structures/mod_station.png",
	"recycle": "res://assets/sprites/structures/recycle_machine.png",
	"save": "res://assets/sprites/structures/save_station.png",
	"to_wasteland": "res://assets/sprites/structures/wasteland_gate.png",
	"to_guild": "res://assets/sprites/structures/guild_gate.png"
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

	_add_station("forge", "鍛造爐：廢鐵換彈藥", Vector2(640, 270), Vector2(180, 110), Color8(102, 68, 45))
	_add_station("craft", "合成台：製作近戰武器", Vector2(340, 430), Vector2(170, 100), Color8(72, 92, 96))
	_add_station("shop", "補給商：購買彈藥", Vector2(1040, 420), Vector2(180, 110), Color8(93, 75, 47))
	_add_station("mod", "改裝站：打造線圈發射器", Vector2(420, 770), Vector2(185, 110), Color8(54, 77, 91))
	_add_station("recycle", "拆解機：核心換材料", Vector2(720, 830), Vector2(170, 96), Color8(69, 88, 78))
	_add_station("save", "維修存檔點", Vector2(1030, 770), Vector2(160, 96), Color8(42, 92, 108))
	_add_station("to_wasteland", "前往廢土外圍", Vector2(260, 960), Vector2(180, 72), Color8(54, 104, 58))
	_add_station("to_guild", "前往冒險公會", Vector2(1350, 640), Vector2(180, 96), Color8(90, 82, 120))

	_spawn_npcs()
	_add_projectile_pool(200)
	_spawn_player(Vector2(760, 560))
	add_child(HUD_SCENE.instantiate())
	GameState.notify("村莊據點：靠近 NPC 或設施按 E 互動；按 I 查看人物裝備。")

func _spawn_player(default_position: Vector2) -> void:
	player = PLAYER_SCENE.instantiate()
	player.global_position = default_position if GameState.active_spawn_point != "saved" else GameState.player_position
	add_child(player)
	if player.has_method("set_world_bounds"):
		player.set_world_bounds(WORLD_RECT)

func _add_projectile_pool(limit: int) -> void:
	var pool: Node = PROJECTILE_POOL_SCRIPT.new()
	pool.max_projectiles = limit
	add_child(pool)

func _add_station(id: String, label: String, pos: Vector2, size: Vector2, color: Color) -> void:
	var node := Node2D.new()
	node.position = pos
	node.y_sort_enabled = true
	add_child(node)

	var sprite := Sprite2D.new()
	var texture := _station_texture(id)
	sprite.texture = texture if texture != null else PIXEL.new().make_texture(Vector2i(int(size.x), int(size.y)), [color.darkened(0.35), color, color.lightened(0.18)], id.length())
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var texture_size := sprite.texture.get_size()
	sprite.centered = false
	sprite.position = Vector2(-texture_size.x * 0.5, -texture_size.y)
	node.add_child(sprite)

	var interactable: Area2D = INTERACTABLE_SCRIPT.new()
	interactable.interaction_id = id
	interactable.prompt = label
	interactable.radius = max(texture_size.x, texture_size.y) * 0.42
	interactable.interacted.connect(_on_station_interacted)
	node.add_child(interactable)

func _station_texture(id: String) -> Texture2D:
	var path := String(STATION_TEXTURES.get(id, ""))
	if not path.is_empty():
		return ASSET_LOADER.load_png(path)
	return null

func _add_decor() -> void:
	var props := [
		["scrap_wall", Vector2(210, 250), true, Vector2i(96, 66)],
		["scrap_wall", Vector2(1510, 260), true, Vector2i(96, 66)],
		["rust_rock", Vector2(1180, 250), true, Vector2i(72, 62)],
		["dead_tree", Vector2(1540, 820), true, Vector2i(72, 110)],
		["road_marker", Vector2(760, 390), false, Vector2i(42, 58)],
		["road_marker", Vector2(760, 710), false, Vector2i(42, 58)],
		["signal_pylon", Vector2(1540, 510), true, Vector2i(72, 128)]
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
			SaveManager.save_game()
		"to_wasteland":
			SceneRouter.change_to("wasteland", "from_village")
		"to_guild":
			SceneRouter.change_to("guild", "from_village")
