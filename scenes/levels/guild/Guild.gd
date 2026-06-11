extends Node2D

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const HUD_SCENE := preload("res://scenes/ui/HUD.tscn")
const PIXEL := preload("res://scripts/utils/PixelArtFactory.gd")
const ASSET_LOADER := preload("res://scripts/utils/RuntimeAssetLoader.gd")
const BACKDROP_SCRIPT := preload("res://scripts/systems/WorldBackdrop.gd")
const INTERACTABLE_SCRIPT := preload("res://scripts/components/Interactable.gd")
const DIALOGUE_NPC_SCRIPT := preload("res://scripts/components/DialogueNpc.gd")
const PROJECTILE_POOL_SCRIPT := preload("res://scripts/systems/ProjectilePool.gd")

const COUNTER_TEXTURES := {
	"contract": "res://assets/sprites/structures/guild_contract_board.png",
	"reward": "res://assets/sprites/structures/guild_reward_counter.png",
	"to_wasteland": "res://assets/sprites/structures/guild_wasteland_exit.png",
	"to_village": "res://assets/sprites/structures/village_return_gate.png"
}

func _ready() -> void:
	y_sort_enabled = true
	GameState.current_scene_id = "guild"
	AudioManager.play_music("guild")
	var backdrop: Node2D = BACKDROP_SCRIPT.new()
	backdrop.setup("guild", Vector2i(46, 28), 4096)
	add_child(backdrop)
	_add_counter("contract", "委託看板：選擇清理任務", Vector2(330, 275), Color8(102, 74, 118))
	_add_counter("reward", "獎勵櫃台：回報委託", Vector2(670, 275), Color8(75, 96, 122))
	_add_counter("to_wasteland", "公會出口：前往廢土", Vector2(980, 500), Color8(92, 88, 56))
	_add_counter("to_village", "返回村莊據點", Vector2(565, 610), Color8(64, 110, 70))
	_spawn_npcs()
	_add_projectile_pool(200)
	var player := PLAYER_SCENE.instantiate()
	player.global_position = Vector2(625, 440)
	add_child(player)
	add_child(HUD_SCENE.instantiate())
	GameState.notify("冒險公會：接委託、回報獎勵，準備好再前往廢土。")

func _add_projectile_pool(limit: int) -> void:
	var pool: Node = PROJECTILE_POOL_SCRIPT.new()
	pool.max_projectiles = limit
	add_child(pool)

func _add_counter(id: String, label: String, pos: Vector2, color: Color) -> void:
	var sprite := Sprite2D.new()
	var texture := _counter_texture(id)
	sprite.texture = texture if texture != null else PIXEL.new().make_texture(Vector2i(200, 104), [color.darkened(0.3), color, color.lightened(0.22)], id.length())
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var texture_size := sprite.texture.get_size()
	sprite.centered = false
	sprite.position = pos + Vector2(-texture_size.x * 0.5, -texture_size.y)
	add_child(sprite)
	var text := Label.new()
	text.text = label
	text.position = pos + Vector2(-texture_size.x * 0.42, -texture_size.y - 22)
	text.add_theme_font_size_override("font_size", 15)
	add_child(text)
	var interactable: Area2D = INTERACTABLE_SCRIPT.new()
	interactable.interaction_id = id
	interactable.prompt = label
	interactable.position = pos
	interactable.radius = max(texture_size.x, texture_size.y) * 0.38
	interactable.interacted.connect(_on_interacted)
	add_child(interactable)

func _counter_texture(id: String) -> Texture2D:
	var path := String(COUNTER_TEXTURES.get(id, ""))
	if not path.is_empty():
		return ASSET_LOADER.load_png(path)
	return null

func _spawn_npcs() -> void:
	for npc_data in DataRegistry.npcs_for_scene("guild"):
		var npc: Area2D = DIALOGUE_NPC_SCRIPT.new()
		npc.setup(npc_data)
		add_child(npc)

func _on_interacted(id: String) -> void:
	match id:
		"contract":
			_start_next_contract()
		"reward":
			GameState.complete_active_quest()
		"to_wasteland":
			GameState.seed = randi_range(1000, 999999)
			GameState.level += 1
			GameState.notify("公會核發新探索路線，seed：%d" % GameState.seed)
			SceneRouter.change_to("wasteland", "from_guild")
		"to_village":
			SceneRouter.change_to("village", "from_guild")

func _start_next_contract() -> void:
	if not GameState.active_quest_id.is_empty():
		GameState.notify("目前委託：%s" % GameState.active_quest_summary())
		return
	for quest_id in DataRegistry.quest_ids():
		if not GameState.completed_quests.has(quest_id):
			GameState.start_quest(quest_id)
			return
	GameState.notify("目前沒有新的公會委託。")
