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
var ranged_cooldown := 0.0
var dash_cooldown := 0.0
var dash_time := 0.0
var contact_range := 42.0
var preferred_distance := 0.0
var ranged_range := 0.0
var ranged_attack_cooldown := 1.4
var can_fire_projectiles := false

func setup(id: String, data: Dictionary, player_ref: Node2D) -> void:
	enemy_id = id
	enemy_type = String(data.get("type", "melee"))
	hp = int(data.get("hp", 24))
	speed = float(data.get("speed", 70.0))
	damage = int(data.get("damage", 8))
	drop_table = data.get("drop_table", {})
	target = player_ref
	_configure_behavior()

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
	var desired := _desired_direction(offset, distance)
	velocity = desired * _current_speed()
	move_and_slide()
	attack_cooldown = max(0.0, attack_cooldown - delta)
	ranged_cooldown = max(0.0, ranged_cooldown - delta)
	dash_cooldown = max(0.0, dash_cooldown - delta)
	dash_time = max(0.0, dash_time - delta)
	if can_fire_projectiles and distance <= ranged_range and ranged_cooldown <= 0.0:
		_fire_pollution_shot(offset.normalized())
	if distance < contact_range and attack_cooldown <= 0.0:
		attack_cooldown = _contact_cooldown()
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

func _configure_behavior() -> void:
	contact_range = 42.0
	preferred_distance = 0.0
	ranged_range = 0.0
	ranged_attack_cooldown = 1.4
	can_fire_projectiles = false
	match enemy_type:
		"fast":
			contact_range = 36.0
			dash_cooldown = 0.35
		"ranged":
			contact_range = 34.0
			preferred_distance = 230.0
			ranged_range = 360.0
			ranged_attack_cooldown = 1.35
			can_fire_projectiles = true
		"heavy":
			contact_range = 58.0
		"flying":
			contact_range = 38.0
		"hybrid":
			contact_range = 46.0
			preferred_distance = 155.0
			ranged_range = 285.0
			ranged_attack_cooldown = 1.05
			can_fire_projectiles = true

func _desired_direction(offset: Vector2, distance: float) -> Vector2:
	var desired := offset.normalized() if distance > 1.0 else Vector2.ZERO
	if enemy_type == "ranged":
		if distance < preferred_distance:
			desired = -desired * 0.7
		elif distance < ranged_range:
			desired = desired * 0.25
	elif enemy_type == "hybrid":
		if distance < preferred_distance:
			desired = -desired * 0.35
	elif enemy_type == "fast":
		if distance < 190.0 and dash_cooldown <= 0.0:
			dash_time = 0.18
			dash_cooldown = 1.2
	elif enemy_type == "flying":
		var orbit := desired.rotated(PI * 0.5) * 0.45
		desired = (desired + orbit).normalized()
	elif enemy_type == "heavy" and distance > contact_range:
		desired *= 0.8
	return desired

func _current_speed() -> float:
	if enemy_type == "fast" and dash_time > 0.0:
		return speed * 1.85
	if enemy_type == "flying":
		return speed * 1.08
	return speed

func _contact_cooldown() -> float:
	match enemy_type:
		"fast":
			return 0.48
		"heavy":
			return 1.15
		"hybrid":
			return 0.85
		_:
			return 0.75

func _fire_pollution_shot(direction: Vector2) -> void:
	if direction.length() < 0.1:
		return
	var pools := get_tree().get_nodes_in_group("projectile_pool")
	if pools.is_empty() or not pools[0].has_method("fire_projectile"):
		return
	var projectile_start := global_position + direction * 24.0
	if pools[0].fire_projectile(projectile_start, direction, max(1, int(damage * 0.75)), "player"):
		ranged_cooldown = ranged_attack_cooldown

func behavior_summary() -> Dictionary:
	return {
		"type": enemy_type,
		"contact_range": contact_range,
		"preferred_distance": preferred_distance,
		"ranged_range": ranged_range,
		"can_fire_projectiles": can_fire_projectiles,
		"ranged_cooldown": ranged_attack_cooldown,
		"dash_speed": _current_speed() if enemy_type == "fast" and dash_time > 0.0 else speed
	}
