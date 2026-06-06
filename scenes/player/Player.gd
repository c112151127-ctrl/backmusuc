extends CharacterBody2D

const PIXEL := preload("res://scripts/utils/PixelArtFactory.gd")
const PROJECTILE_SCRIPT := preload("res://scripts/components/Projectile.gd")

@export var move_speed: float = 180.0

enum PlayerState { IDLE, MOVE, MELEE, SHOOT, SWAP_TOOL, INTERACT, HIT, DEAD }

var state := PlayerState.IDLE
var last_direction := Vector2.DOWN
var attack_timer := 0.0
var ranged_timer := 0.0
var sprite_cache: Dictionary = {}

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	add_to_group("player")
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_update_sprite(0)

func _physics_process(delta: float) -> void:
	attack_timer = max(0.0, attack_timer - delta)
	ranged_timer = max(0.0, ranged_timer - delta)
	var input_direction := Input.get_vector(
		"move_left",
		"move_right",
		"move_up",
		"move_down"
	)

	if input_direction.length() > 0.05:
		last_direction = input_direction.normalized()
		state = PlayerState.MOVE
	else:
		state = PlayerState.IDLE

	var speed_bonus := GameState.get_stat_bonus("speed")
	velocity = input_direction * max(80.0, move_speed + speed_bonus)
	move_and_slide()
	GameState.player_position = global_position

	if Input.is_action_just_pressed("attack_melee"):
		_melee_attack()
	if Input.is_action_just_pressed("attack_ranged"):
		_ranged_attack()
	if Input.is_action_just_pressed("swap_weapon"):
		state = PlayerState.SWAP_TOOL
		GameState.notify("切換工具：近戰/遠程循環")
	if Input.is_action_just_pressed("save_game"):
		SaveManager.save_game()
	if Input.is_action_just_pressed("load_game"):
		SaveManager.load_game()

	_update_sprite(_direction_index())

func _melee_attack() -> void:
	if attack_timer > 0.0:
		return
	state = PlayerState.MELEE
	var weapon := DataRegistry.get_equipment(String(GameState.equipment.get("weapon", "rust_blade")))
	attack_timer = float(weapon.get("cooldown", 0.32))
	var damage := 12 + GameState.get_stat_bonus("attack")
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy is Node2D and global_position.distance_to(enemy.global_position) <= 70:
			var facing: Vector2 = (enemy.global_position - global_position).normalized()
			if last_direction.dot(facing) > -0.2 and enemy.has_method("take_damage"):
				enemy.take_damage(damage, true)

func _ranged_attack() -> void:
	if ranged_timer > 0.0:
		return
	if not GameState.spend_ammo(1):
		GameState.notify("彈藥不足，改用近戰回收")
		return
	state = PlayerState.SHOOT
	var ranged := DataRegistry.get_equipment(String(GameState.equipment.get("ranged", "pipe_rifle")))
	ranged_timer = float(ranged.get("cooldown", 0.25))
	var aim := get_global_mouse_position() - global_position
	if aim.length() < 8:
		aim = last_direction
	last_direction = aim.normalized()
	var projectile: Area2D = PROJECTILE_SCRIPT.new()
	projectile.setup(global_position + last_direction * 28.0, last_direction, 10 + GameState.get_stat_bonus("attack"))
	get_tree().current_scene.add_child(projectile)

func _direction_index() -> int:
	var angle := last_direction.angle()
	return int(round(angle / (PI / 4.0))) & 7

func _update_sprite(direction_index: int) -> void:
	var action_index := 0
	if state == PlayerState.MELEE:
		action_index = 1
	elif state == PlayerState.SHOOT:
		action_index = 2
	elif state == PlayerState.SWAP_TOOL:
		action_index = 3
	var key := "%d_%d" % [direction_index, action_index]
	if not sprite_cache.has(key):
		sprite_cache[key] = PIXEL.new().player_texture(direction_index, action_index)
	sprite.texture = sprite_cache[key]
