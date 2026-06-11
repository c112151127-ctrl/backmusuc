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
	backdrop.setup("village", Vector2i(60, 40), 137)
	add_child(backdrop)
	_add_station("forge", "鍛造爐：廢鐵換彈藥", Vector2(640, 260), Vector2(180, 110), Color8(102, 68, 45))
	_add_station("craft", "合成台：製作近戰武器", Vector2(340, 390), Vector2(170, 100), Color8(72, 92, 96))
	_add_station("shop", "補給商：購買彈藥", Vector2(940, 390), Vector2(180, 110), Color8(93, 75, 47))
	_add_station("mod", "改裝站：打造線圈發射器", Vector2(390, 685), Vector2(185, 110), Color8(54, 77, 91))
	_add_station("recycle", "拆解機：核心換材料", Vector2(650, 735), Vector2(170, 96), Color8(69, 88, 78))
	_add_station("save", "維修存檔點", Vector2(910, 685), Vector2(160, 96), Color8(42, 92, 108))
	_add_station("to_wasteland", "前往廢土外圍", Vector2(240, 820), Vector2(180, 72), Color8(54, 104, 58))
	_add_station("to_guild", "前往冒險公會", Vector2(1180, 590), Vector2(180, 96), Color8(90, 82, 120))
	_add_sign("公告：WASD 移動，滑鼠左鍵近戰、右鍵連續射擊，E 互動，M 開關小地圖。", Vector2(430, 160))
	_spawn_npcs()
	_add_projectile_pool(200)
	_spawn_player(Vector2(640, 500))
	add_child(HUD_SCENE.instantiate())
	GameState.notify("村莊據點：整備裝備、接任務，再前往廢土回收資源")

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
	var texture := _station_texture(id)
	sprite.texture = texture if texture != null else PIXEL.new().make_texture(Vector2i(int(size.x), int(size.y)), [color.darkened(0.35), color, color.lightened(0.18)], id.length())
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var texture_size := sprite.texture.get_size()
	sprite.centered = false
	sprite.position = Vector2(-texture_size.x * 0.5, -texture_size.y)
	node.add_child(sprite)
	var text := Label.new()
	text.text = label
	text.position = Vector2(-texture_size.x * 0.45, -texture_size.y - 24)
	text.add_theme_font_size_override("font_size", 15)
	node.add_child(text)
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

func _add_sign(text_value: String, pos: Vector2) -> void:
	var label := Label.new()
	label.text = text_value
	label.position = pos
	label.add_theme_font_size_override("font_size", 18)
	add_child(label)

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
