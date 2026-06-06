extends Node2D

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const HUD_SCENE := preload("res://scenes/ui/HUD.tscn")
const PIXEL := preload("res://scripts/utils/PixelArtFactory.gd")
const BACKDROP_SCRIPT := preload("res://scripts/systems/WorldBackdrop.gd")
const INTERACTABLE_SCRIPT := preload("res://scripts/components/Interactable.gd")
const INVENTORY_SCRIPT := preload("res://scripts/systems/InventorySystem.gd")
const PROJECTILE_POOL_SCRIPT := preload("res://scripts/systems/ProjectilePool.gd")

var player: Node2D

func _ready() -> void:
	y_sort_enabled = true
	GameState.current_scene_id = "village"
	var backdrop: Node2D = BACKDROP_SCRIPT.new()
	backdrop.setup("village", Vector2i(60, 40), 137)
	add_child(backdrop)
	_add_station("forge", "鍛造：廢鐵換彈藥", Vector2(430, 260), Vector2(180, 110), Color8(102, 68, 45))
	_add_station("craft", "合成：火花切割器", Vector2(300, 520), Vector2(170, 100), Color8(72, 92, 96))
	_add_station("shop", "交易：補給", Vector2(900, 280), Vector2(180, 110), Color8(93, 75, 47))
	_add_station("mod", "改裝：套用零件", Vector2(540, 600), Vector2(185, 110), Color8(54, 77, 91))
	_add_station("save", "存檔點", Vector2(840, 560), Vector2(160, 96), Color8(42, 92, 108))
	_add_station("to_wasteland", "前往野外", Vector2(950, 760), Vector2(180, 72), Color8(54, 104, 58))
	_add_station("to_guild", "冒險公會", Vector2(1180, 380), Vector2(180, 96), Color8(90, 82, 120))
	_add_projectile_pool(200)
	_spawn_player(Vector2(640, 460))
	add_child(HUD_SCENE.instantiate())
	GameState.notify("村莊：鍛造、合成、交易、改裝、存檔與出口已啟用")

func _spawn_player(default_position: Vector2) -> void:
	player = PLAYER_SCENE.instantiate()
	player.global_position = default_position if GameState.active_spawn_point != "saved" else GameState.player_position
	add_child(player)

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
	sprite.texture = PIXEL.new().make_texture(Vector2i(int(size.x), int(size.y)), [color.darkened(0.35), color, color.lightened(0.18)], id.length())
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	node.add_child(sprite)
	var text := Label.new()
	text.text = label
	text.position = Vector2(-size.x * 0.45, -size.y * 0.72)
	text.add_theme_font_size_override("font_size", 18)
	node.add_child(text)
	var interactable: Area2D = INTERACTABLE_SCRIPT.new()
	interactable.interaction_id = id
	interactable.prompt = label
	interactable.radius = max(size.x, size.y) * 0.45
	interactable.interacted.connect(_on_station_interacted)
	node.add_child(interactable)

func _on_station_interacted(id: String) -> void:
	match id:
		"forge":
			INVENTORY_SCRIPT.forge_ammo_pack()
		"craft":
			INVENTORY_SCRIPT.craft_basic_upgrade()
		"shop":
			GameState.add_item("ammo", 6)
			GameState.notify("交易完成：彈藥 x6")
		"mod":
			if GameState.inventory.has("spark_cutter"):
				GameState.equip_item("spark_cutter")
			elif GameState.inventory.has("coil_launcher"):
				GameState.equip_item("coil_launcher")
			else:
				GameState.notify("尚未取得可改裝零件")
		"save":
			SaveManager.save_game()
		"to_wasteland":
			SceneRouter.change_to("wasteland", "from_village")
		"to_guild":
			SceneRouter.change_to("guild", "from_village")
