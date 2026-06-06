extends CharacterBody2D
class_name WastelandEnemy

const PIXEL := preload("res://scripts/utils/PixelArtFactory.gd")
const PICKUP_SCRIPT := preload("res://scripts/components/Pickup.gd")
const ENEMY_ATLAS_PATH := "res://assets/sprites/enemies/polluted_enemy_six_types.png"

var enemy_id := "scrap_biter"
var enemy_type := "melee"
var hp := 24
var speed := 70.0
var damage := 8
var drop_table: Dictionary = {}
var target: Node2D
var attack_cooldown := 0.0

func setup(id: String, data: Dictionary, player_ref: Node2D) -> void:
	enemy_id = id
	enemy_type = String(data.get("type", "melee"))
	hp = int(data.get("hp", 24))
	speed = float(data.get("speed", 70.0))
	damage = int(data.get("damage", 8))
	drop_table = data.get("drop_table", {})
	target = player_ref

func _ready() -> void:
	add_to_group("enemy")
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 18
	collision.shape = shape
	add_child(collision)
	var sprite := Sprite2D.new()
	sprite.texture = _enemy_texture(enemy_type)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(sprite)

func _enemy_texture(type_id: String) -> Texture2D:
	var atlas: Texture2D = _load_atlas_texture(ENEMY_ATLAS_PATH)
	if atlas == null:
		return PIXEL.new().enemy_texture(type_id)
	var index := PixelArtFactory.ENEMY_TYPES.find(type_id)
	if index < 0:
		index = 0
	var frame_size := PixelArtFactory.ENEMY_FRAME_SIZE
	var texture := AtlasTexture.new()
	texture.atlas = atlas
	texture.region = Rect2(index * frame_size.x, 0, frame_size.x, frame_size.y)
	return texture

func _load_atlas_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var loaded: Texture2D = load(path) as Texture2D
		if loaded != null:
			return loaded
	if FileAccess.file_exists(path):
		var image: Image = Image.load_from_file(path)
		if image != null:
			return ImageTexture.create_from_image(image)
	return null

func _physics_process(delta: float) -> void:
	if target == null or not is_instance_valid(target):
		return
	var offset := target.global_position - global_position
	var distance := offset.length()
	var desired := offset.normalized() if distance > 1.0 else Vector2.ZERO
	if enemy_type == "ranged" and distance < 220:
		desired = -desired * 0.5
	velocity = desired * speed
	move_and_slide()
	attack_cooldown = max(0.0, attack_cooldown - delta)
	if distance < 42 and attack_cooldown <= 0.0:
		attack_cooldown = 0.75
		GameState.take_damage(damage)

func take_damage(amount: int, melee := false) -> void:
	hp -= amount
	modulate = Color(1.0, 0.55, 0.45)
	await get_tree().create_timer(0.06).timeout
	modulate = Color.WHITE
	if hp <= 0:
		_die(melee)

func _die(melee: bool) -> void:
	if melee:
		GameState.record_enemy_defeated()
	for item_id in drop_table.keys():
		if randi() % 100 < 55:
			var pickup: Area2D = PICKUP_SCRIPT.new()
			pickup.setup(String(item_id), int(drop_table[item_id]))
			pickup.global_position = global_position + Vector2(randf_range(-18, 18), randf_range(-18, 18))
			get_tree().current_scene.add_child(pickup)
	queue_free()
