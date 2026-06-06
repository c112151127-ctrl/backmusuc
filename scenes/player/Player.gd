extends CharacterBody2D

const PIXEL := preload("res://scripts/utils/PixelArtFactory.gd")
const PROJECTILE_SCRIPT := preload("res://scripts/components/Projectile.gd")
const PLAYER_ATLAS_PATH := "res://assets/sprites/player/recycler_player_multiaction_8dir.png"

@export var move_speed: float = 180.0

enum PlayerState { IDLE, MOVE, MELEE, SHOOT, SWAP_TOOL, INTERACT, HIT, DEAD }

var state := PlayerState.IDLE
var last_direction := Vector2.DOWN
var attack_timer := 0.0
var ranged_timer := 0.0
var current_animation := ""

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	add_to_group("player")
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_build_sprite_frames()
	_update_animation()

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
		GameState.use_next_quick_slot()
	for slot_index in range(4):
		if Input.is_action_just_pressed("quick_slot_%d" % [slot_index + 1]):
			state = PlayerState.SWAP_TOOL
			GameState.use_quick_slot(slot_index)
	if Input.is_action_just_pressed("save_game"):
		SaveManager.save_game()
	if Input.is_action_just_pressed("load_game"):
		SaveManager.load_game()

	_update_animation()

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
	var projectile_damage := 10 + GameState.get_stat_bonus("attack")
	var projectile_start := global_position + last_direction * 28.0
	var pools := get_tree().get_nodes_in_group("projectile_pool")
	if not pools.is_empty() and pools[0].has_method("fire_projectile"):
		if not pools[0].fire_projectile(projectile_start, last_direction, projectile_damage):
			GameState.add_item("ammo", 1)
	else:
		var projectile: Area2D = PROJECTILE_SCRIPT.new()
		projectile.setup(projectile_start, last_direction, projectile_damage)
		get_tree().current_scene.add_child(projectile)

func _direction_index() -> int:
	var angle := last_direction.angle()
	return int(round(angle / (PI / 4.0))) & 7

func _build_sprite_frames() -> void:
	var frames := SpriteFrames.new()
	var actions: Dictionary = {
		"idle": 0,
		"move": 0,
		"melee": 1,
		"shoot": 2,
		"swap_tool": 3
	}
	var atlas: Texture2D = _load_atlas_texture(PLAYER_ATLAS_PATH)
	for action_name in actions.keys():
		for direction_index in range(8):
			var animation_name := "%s_%d" % [action_name, direction_index]
			frames.add_animation(animation_name)
			frames.set_animation_speed(animation_name, 6.0 if action_name in ["idle", "move"] else 10.0)
			frames.set_animation_loop(animation_name, action_name in ["idle", "move"])
			for frame_index in range(3):
				if atlas != null:
					frames.add_frame(animation_name, _atlas_frame(atlas, int(actions[action_name]), direction_index, frame_index))
				else:
					frames.add_frame(animation_name, PIXEL.new().player_texture(direction_index, int(actions[action_name]), frame_index))
	sprite.sprite_frames = frames

func _atlas_frame(atlas: Texture2D, action_index: int, direction_index: int, frame_index: int) -> AtlasTexture:
	var frame_size := PixelArtFactory.PLAYER_FRAME_SIZE
	var texture := AtlasTexture.new()
	texture.atlas = atlas
	texture.region = Rect2(
		(action_index * 3 + frame_index) * frame_size.x,
		direction_index * frame_size.y,
		frame_size.x,
		frame_size.y
	)
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

func _update_animation() -> void:
	var direction_index := _direction_index()
	var action_name := "idle"
	if state == PlayerState.MELEE:
		action_name = "melee"
	elif state == PlayerState.SHOOT:
		action_name = "shoot"
	elif state == PlayerState.SWAP_TOOL:
		action_name = "swap_tool"
	elif state == PlayerState.MOVE:
		action_name = "move"
	var next_animation := "%s_%d" % [action_name, direction_index]
	if current_animation != next_animation:
		current_animation = next_animation
		sprite.play(current_animation)
