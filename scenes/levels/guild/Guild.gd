extends Node2D

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const HUD_SCENE := preload("res://scenes/ui/HUD.tscn")
const PIXEL := preload("res://scripts/utils/PixelArtFactory.gd")
const BACKDROP_SCRIPT := preload("res://scripts/systems/WorldBackdrop.gd")
const INTERACTABLE_SCRIPT := preload("res://scripts/components/Interactable.gd")
const PROJECTILE_POOL_SCRIPT := preload("res://scripts/systems/ProjectilePool.gd")

func _ready() -> void:
	y_sort_enabled = true
	GameState.current_scene_id = "guild"
	var backdrop: Node2D = BACKDROP_SCRIPT.new()
	backdrop.setup("village", Vector2i(46, 28), 4096)
	add_child(backdrop)
	_add_counter("contract", "接取遠征任務", Vector2(420, 270), Color8(102, 74, 118))
	_add_counter("reward", "公會獎勵兌換", Vector2(720, 270), Color8(75, 96, 122))
	_add_counter("to_village", "返回村莊", Vector2(600, 560), Color8(64, 110, 70))
	_add_projectile_pool(200)
	var player := PLAYER_SCENE.instantiate()
	player.global_position = Vector2(600, 430)
	add_child(player)
	add_child(HUD_SCENE.instantiate())
	GameState.notify("冒險公會：可接任務、兌換獎勵")

func _add_projectile_pool(limit: int) -> void:
	var pool: Node = PROJECTILE_POOL_SCRIPT.new()
	pool.max_projectiles = limit
	add_child(pool)

func _add_counter(id: String, label: String, pos: Vector2, color: Color) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = PIXEL.new().make_texture(Vector2i(200, 104), [color.darkened(0.3), color, color.lightened(0.22)], id.length())
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.position = pos
	add_child(sprite)
	var text := Label.new()
	text.text = label
	text.position = pos + Vector2(-78, -82)
	text.add_theme_font_size_override("font_size", 18)
	add_child(text)
	var interactable: Area2D = INTERACTABLE_SCRIPT.new()
	interactable.interaction_id = id
	interactable.prompt = label
	interactable.position = pos
	interactable.radius = 70
	interactable.interacted.connect(_on_interacted)
	add_child(interactable)

func _on_interacted(id: String) -> void:
	match id:
		"contract":
			GameState.seed = randi_range(1000, 999999)
			GameState.level += 1
			GameState.notify("已接取任務，野外 seed: %d" % GameState.seed)
			SceneRouter.change_to("wasteland", "from_guild")
		"reward":
			if GameState.consume_item("mutant_core", 1):
				GameState.add_item("coil_launcher", 1)
				GameState.notify("獲得線圈發射器")
			else:
				GameState.notify("需要異變核心 x1")
		"to_village":
			SceneRouter.change_to("village", "from_guild")
