extends Area2D
class_name DialogueNpc

const PIXEL := preload("res://scripts/utils/PixelArtFactory.gd")
const ASSET_LOADER := preload("res://scripts/utils/RuntimeAssetLoader.gd")

var npc_id := ""
var npc_name := "NPC"
var role := ""
var color := Color8(110, 126, 116)
var _player_near := false
var _prompt: Label

func setup(data: Dictionary) -> void:
	npc_id = String(data.get("id", ""))
	npc_name = String(data.get("name", npc_id))
	role = String(data.get("role", "嚮導"))
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

func _process(_delta: float) -> void:
	if _player_near and Input.is_action_just_pressed("interact"):
		GameState.talk_to_npc(npc_id)

func _add_collision() -> void:
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 44
	collision.shape = shape
	add_child(collision)

func _add_sprite() -> void:
	var sprite := Sprite2D.new()
	var npc_texture := _npc_texture()
	sprite.texture = npc_texture if npc_texture != null else PIXEL.new().make_texture(Vector2i(56, 72), [color.darkened(0.35), color, color.lightened(0.25)], npc_id.length())
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.centered = false
	sprite.position = Vector2(-28, -72)
	add_child(sprite)

func _add_labels() -> void:
	var name_label := Label.new()
	name_label.text = "%s｜%s" % [npc_name, role]
	name_label.position = Vector2(-58, -104)
	name_label.add_theme_font_size_override("font_size", 14)
	add_child(name_label)
	_prompt = Label.new()
	_prompt.text = "E：交談"
	_prompt.position = Vector2(-32, -124)
	_prompt.visible = false
	_prompt.add_theme_font_size_override("font_size", 14)
	add_child(_prompt)

func _npc_texture() -> Texture2D:
	var path := "res://assets/sprites/npcs/%s.png" % npc_id
	return ASSET_LOADER.load_png(path)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_player_near = true
		_prompt.visible = true

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		_player_near = false
		_prompt.visible = false
