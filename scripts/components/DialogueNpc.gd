extends Area2D
class_name DialogueNpc

const PIXEL := preload("res://scripts/utils/PixelArtFactory.gd")
const ASSET_LOADER := preload("res://scripts/utils/RuntimeAssetLoader.gd")

var npc_id := ""
var npc_name := "NPC"
var role := "居民"
var color := Color8(110, 126, 116)
var _player_near := false
var _name_label: Label
var _prompt: Label
var _sprite: Sprite2D
var _base_sprite_y := 0.0
var _phase := 0.0
var _talk_timer := 0.0

func setup(data: Dictionary) -> void:
	npc_id = String(data.get("id", ""))
	npc_name = String(data.get("name", npc_id))
	role = String(data.get("role", "居民"))
	color = Color.from_string(String(data.get("color", "#6f7e74")), Color8(110, 126, 116))
	var position_data: Dictionary = data.get("position", {})
	position = Vector2(float(position_data.get("x", 0.0)), float(position_data.get("y", 0.0)))

func _ready() -> void:
	add_to_group("npc")
	add_to_group("interactable")
	monitoring = true
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_add_collision()
	_add_sprite()
	_add_labels()

func _process(delta: float) -> void:
	_phase += delta * (5.2 if _player_near else 2.4)
	_talk_timer = max(0.0, _talk_timer - delta)
	if _sprite != null:
		_sprite.position.y = _base_sprite_y + sin(_phase) * (2.0 if _player_near else 1.0)
		_sprite.rotation = sin(_phase * 0.55) * (0.025 if _talk_timer <= 0.0 else 0.055)
		_sprite.modulate = Color(1.08, 1.08, 1.08) if _talk_timer > 0.0 else Color.WHITE
	if _player_near and Input.is_action_just_pressed("interact"):
		AudioManager.play_sfx("interact")
		_talk_timer = 0.45
		GameState.talk_to_npc(npc_id)

func _add_collision() -> void:
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 48
	collision.shape = shape
	add_child(collision)

func _add_sprite() -> void:
	_sprite = Sprite2D.new()
	var npc_texture := _npc_texture()
	_sprite.texture = npc_texture if npc_texture != null else PIXEL.new().make_texture(Vector2i(56, 72), [color.darkened(0.35), color, color.lightened(0.25)], npc_id.length())
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.centered = false
	var texture_size := _sprite.texture.get_size()
	_sprite.position = Vector2(-texture_size.x * 0.5, -texture_size.y)
	_base_sprite_y = _sprite.position.y
	add_child(_sprite)

func _add_labels() -> void:
	_name_label = Label.new()
	_name_label.text = "%s｜%s" % [npc_name, role]
	_name_label.position = Vector2(-72, -104)
	_name_label.visible = false
	_name_label.add_theme_font_size_override("font_size", 14)
	add_child(_name_label)

	_prompt = Label.new()
	_prompt.text = "E：交談"
	_prompt.position = Vector2(-36, -128)
	_prompt.visible = false
	_prompt.add_theme_font_size_override("font_size", 14)
	add_child(_prompt)

func _npc_texture() -> Texture2D:
	var path := "res://assets/sprites/npcs/%s.png" % npc_id
	return ASSET_LOADER.load_png(path)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_player_near = true
		_name_label.visible = true
		_prompt.visible = true

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		_player_near = false
		_name_label.visible = false
		_prompt.visible = false
		GameState.close_dialogue()
