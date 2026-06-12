extends CharacterBody2D

const PIXEL := preload("res://scripts/utils/PixelArtFactory.gd")
const PROJECTILE_SCRIPT := preload("res://scripts/components/Projectile.gd")
const ATTACK_FLASH_SCRIPT := preload("res://scripts/components/AttackFlash.gd")
const ASSET_LOADER := preload("res://scripts/utils/RuntimeAssetLoader.gd")
const PLAYER_ATLAS_PATH := "res://assets/sprites/player/recycler_player_multiaction_8dir.png"

@export var move_speed: float = 180.0

enum PlayerState { IDLE, WALK, SHOOT, DRAW_SWORD, SLASH, SWAP_TOOL, INTERACT, HIT, DEAD }

var state := PlayerState.IDLE
var last_direction := Vector2.RIGHT
var attack_timer := 0.0
var ranged_timer := 0.0
var action_state_timer := 0.0
var pending_slash := false
var current_animation := ""
var has_world_bounds := false
var world_bounds := Rect2()
var camera_base_offset := Vector2.ZERO
var shake_timer := 0.0
var shake_strength := 0.0
var weapon_sprite: Sprite2D
var current_weapon_asset_id := ""

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var camera: Camera2D = $Camera2D

func _ready() -> void:
	add_to_group("player")
	add_to_group("map_player")
	set_meta("map_label", "R-17")
	set_meta("map_marker", "player")
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	weapon_sprite = Sprite2D.new()
	weapon_sprite.name = "WeaponOverlay"
	weapon_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	weapon_sprite.z_index = 5
	add_child(weapon_sprite)
	camera_base_offset = camera.offset
	if not GameState.feedback_requested.is_connected(_on_feedback_requested):
		GameState.feedback_requested.connect(_on_feedback_requested)
	if not GameState.equipment_changed.is_connected(_update_weapon_overlay):
		GameState.equipment_changed.connect(_update_weapon_overlay)
	_build_sprite_frames()
	_update_weapon_overlay()
	_update_animation()

func _physics_process(delta: float) -> void:
	attack_timer = max(0.0, attack_timer - delta)
	ranged_timer = max(0.0, ranged_timer - delta)
	action_state_timer = max(0.0, action_state_timer - delta)
	if pending_slash and action_state_timer <= 0.0:
		pending_slash = false
		_set_timed_state(PlayerState.SLASH, 0.24)

	var input_direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if state == PlayerState.DEAD:
		velocity = Vector2.ZERO
		move_and_slide()
		_update_camera_shake(delta)
		_update_animation()
		return

	if not _is_action_state_locked():
		_update_locomotion_state(input_direction)
	elif input_direction.length() > 0.05 and state != PlayerState.SHOOT:
		last_direction = input_direction.normalized()

	var speed_bonus := GameState.get_stat_bonus("speed")
	velocity = input_direction * max(80.0, move_speed + speed_bonus)
	move_and_slide()
	if has_world_bounds:
		global_position = global_position.clamp(world_bounds.position, world_bounds.position + world_bounds.size)
	GameState.player_position = global_position

	if Input.is_action_just_pressed("primary_attack"):
		_primary_attack_pressed()
	if Input.is_action_pressed("primary_attack") and GameState.active_attack_mode() == "ranged":
		_ranged_attack()
	if Input.is_action_just_pressed("attack_melee"):
		_melee_attack()
	if Input.is_action_just_pressed("attack_ranged") or Input.is_action_pressed("attack_ranged"):
		_ranged_attack()
	if Input.is_action_just_pressed("swap_weapon"):
		_set_timed_state(PlayerState.SWAP_TOOL, 0.22)
		AudioManager.play_sfx("ui")
		GameState.use_next_quick_slot()
	for slot_index in range(4):
		if Input.is_action_just_pressed("quick_slot_%d" % [slot_index + 1]):
			_set_timed_state(PlayerState.SWAP_TOOL, 0.22)
			GameState.use_quick_slot(slot_index)
	if Input.is_action_just_pressed("interact"):
		_set_timed_state(PlayerState.INTERACT, 0.18)
	if Input.is_action_just_pressed("save_game"):
		SaveManager.save_game()
	if Input.is_action_just_pressed("load_game"):
		SaveManager.load_game()

	_update_weapon_overlay()
	_update_camera_shake(delta)
	_update_animation()

func set_world_bounds(bounds: Rect2) -> void:
	world_bounds = bounds
	has_world_bounds = true
	if camera != null:
		camera.limit_left = int(bounds.position.x)
		camera.limit_top = int(bounds.position.y)
		camera.limit_right = int(bounds.position.x + bounds.size.x)
		camera.limit_bottom = int(bounds.position.y + bounds.size.y)

func _primary_attack_pressed() -> void:
	match GameState.active_attack_mode():
		"ranged":
			_ranged_attack()
		"tool":
			_use_tool_action()
		_:
			_melee_attack(true)

func _melee_attack(use_mouse_aim := false) -> void:
	if attack_timer > 0.0:
		return
	if use_mouse_aim:
		last_direction = _aim_direction()
	var weapon_id := GameState.active_attack_item_id()
	var weapon := DataRegistry.get_equipment(weapon_id)
	if String(weapon.get("attack_mode", "melee")) != "melee":
		weapon_id = String(GameState.equipment.get("weapon", "rust_blade"))
		weapon = DataRegistry.get_equipment(weapon_id)
	_set_timed_state(PlayerState.DRAW_SWORD, 0.10)
	pending_slash = true
	attack_timer = float(weapon.get("cooldown", 0.32))
	var sfx_id := String(weapon.get("sfx_id", "melee"))
	var vfx_id := String(weapon.get("attack_vfx_id", "slash_rust"))
	var shake := float(weapon.get("shake_strength", 0.08))
	AudioManager.play_sfx(sfx_id)
	_spawn_attack_flash(vfx_id, max(0.7, shake * 9.0))
	GameState.request_feedback("attack", shake)
	var damage := 12 + GameState.get_stat_bonus("attack")
	var reach := 86.0 if weapon_id == "breaker_hammer" else 74.0
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy is Node2D and global_position.distance_to(enemy.global_position) <= reach:
			var facing: Vector2 = (enemy.global_position - global_position).normalized()
			if last_direction.dot(facing) > -0.05 and enemy.has_method("take_damage"):
				enemy.take_damage(damage, true)

func _ranged_attack() -> void:
	if ranged_timer > 0.0:
		return
	var ranged_id := GameState.active_attack_item_id()
	var ranged := DataRegistry.get_equipment(ranged_id)
	if String(ranged.get("attack_mode", "ranged")) != "ranged":
		ranged_id = String(GameState.equipment.get("ranged", "pipe_rifle"))
		ranged = DataRegistry.get_equipment(ranged_id)
	if not GameState.spend_ammo(1):
		GameState.notify("彈藥不足，先回收補給或切換近戰。")
		return
	last_direction = _aim_direction()
	_set_timed_state(PlayerState.SHOOT, 0.22)
	var sfx_id := String(ranged.get("sfx_id", "shoot"))
	var vfx_id := String(ranged.get("attack_vfx_id", "muzzle_pipe"))
	var shake := float(ranged.get("shake_strength", 0.06))
	AudioManager.play_sfx(sfx_id)
	_spawn_attack_flash(vfx_id, max(0.55, shake * 8.0))
	GameState.request_feedback("attack", shake)
	ranged_timer = float(ranged.get("cooldown", 0.25))
	var projectile_damage := 10 + GameState.get_stat_bonus("attack")
	var projectile_start := global_position + last_direction * 34.0 + Vector2(0, -18)
	var pools := get_tree().get_nodes_in_group("projectile_pool")
	if not pools.is_empty() and pools[0].has_method("fire_projectile"):
		if not pools[0].fire_projectile(projectile_start, last_direction, projectile_damage):
			GameState.add_item("ammo", 1)
	else:
		var projectile: Area2D = PROJECTILE_SCRIPT.new()
		projectile.setup(projectile_start, last_direction, projectile_damage)
		get_tree().current_scene.add_child(projectile)

func _use_tool_action() -> void:
	_set_timed_state(PlayerState.INTERACT, 0.20)
	var tool := DataRegistry.get_equipment(GameState.active_attack_item_id())
	AudioManager.play_sfx(String(tool.get("sfx_id", "interact")))
	_spawn_attack_flash(String(tool.get("attack_vfx_id", "scan_pulse")), 0.8)
	GameState.notify("R-17 掃描附近可回收目標。")

func _aim_direction() -> Vector2:
	var aim := get_global_mouse_position() - global_position
	if aim.length() < 8.0:
		aim = last_direction
	if aim.length() < 0.05:
		return Vector2.RIGHT
	return aim.normalized()

func _direction_index() -> int:
	var angle := last_direction.angle()
	return int(round(angle / (PI / 4.0))) & 7

func _build_sprite_frames() -> void:
	var frames := SpriteFrames.new()
	var atlas: Texture2D = ASSET_LOADER.load_png(PLAYER_ATLAS_PATH)
	for action_index in range(PixelArtFactory.PLAYER_ACTIONS.size()):
		var action_name := String(PixelArtFactory.PLAYER_ACTIONS[action_index])
		for direction_index in range(8):
			var animation_name := "%s_%d" % [action_name, direction_index]
			frames.add_animation(animation_name)
			frames.set_animation_speed(animation_name, 8.0 if action_name in ["idle", "walk"] else 14.0)
			frames.set_animation_loop(animation_name, action_name in ["idle", "walk"])
			for frame_index in range(PixelArtFactory.PLAYER_FRAMES_PER_ACTION):
				if atlas != null:
					frames.add_frame(animation_name, _atlas_frame(atlas, action_index, direction_index, frame_index))
				else:
					frames.add_frame(animation_name, PIXEL.new().player_texture(direction_index, action_index, frame_index))
	sprite.sprite_frames = frames

func _atlas_frame(atlas: Texture2D, action_index: int, direction_index: int, frame_index: int) -> AtlasTexture:
	var frame_size := PixelArtFactory.PLAYER_FRAME_SIZE
	var texture := AtlasTexture.new()
	texture.atlas = atlas
	texture.region = Rect2(
		(action_index * PixelArtFactory.PLAYER_FRAMES_PER_ACTION + frame_index) * frame_size.x,
		direction_index * frame_size.y,
		frame_size.x,
		frame_size.y
	)
	return texture

func _update_animation() -> void:
	var direction_index := _direction_index()
	var action_name := "idle"
	match state:
		PlayerState.WALK:
			action_name = "walk"
		PlayerState.SHOOT:
			action_name = "shoot"
		PlayerState.DRAW_SWORD:
			action_name = "draw_sword"
		PlayerState.SLASH:
			action_name = "slash"
		PlayerState.SWAP_TOOL:
			action_name = "swap_tool"
		PlayerState.INTERACT:
			action_name = "interact"
		PlayerState.HIT:
			action_name = "hit"
		PlayerState.DEAD:
			action_name = "dead"
	var next_animation := "%s_%d" % [action_name, direction_index]
	if current_animation != next_animation:
		current_animation = next_animation
		sprite.play(current_animation)

func _update_locomotion_state(input_direction: Vector2) -> void:
	if input_direction.length() > 0.05:
		last_direction = input_direction.normalized()
		state = PlayerState.WALK
	else:
		state = PlayerState.IDLE

func _set_timed_state(next_state: int, duration: float) -> void:
	state = next_state
	action_state_timer = max(action_state_timer, duration)
	current_animation = ""

func _is_action_state_locked() -> bool:
	return action_state_timer > 0.0 and state in [
		PlayerState.SHOOT,
		PlayerState.DRAW_SWORD,
		PlayerState.SLASH,
		PlayerState.SWAP_TOOL,
		PlayerState.INTERACT,
		PlayerState.HIT,
		PlayerState.DEAD
	]

func _spawn_attack_flash(effect_id: String, strength: float) -> void:
	var flash: Node2D = ATTACK_FLASH_SCRIPT.new()
	flash.setup(effect_id, last_direction, strength)
	flash.global_position = global_position + last_direction * 42.0 + Vector2(0, -20)
	get_tree().current_scene.add_child(flash)

func _update_weapon_overlay() -> void:
	if weapon_sprite == null:
		return
	var item_id := GameState.active_attack_item_id()
	var item := DataRegistry.get_equipment(item_id)
	var asset_id := String(item.get("weapon_sprite_asset_id", ""))
	if asset_id != current_weapon_asset_id:
		current_weapon_asset_id = asset_id
		weapon_sprite.texture = ASSET_LOADER.load_png(DataRegistry.asset_path(asset_id)) if not asset_id.is_empty() else null
	var visible_state := state in [PlayerState.SHOOT, PlayerState.DRAW_SWORD, PlayerState.SLASH, PlayerState.SWAP_TOOL, PlayerState.INTERACT]
	weapon_sprite.visible = visible_state and weapon_sprite.texture != null
	if not weapon_sprite.visible:
		return
	var direction := last_direction.normalized()
	if direction.length() < 0.1:
		direction = Vector2.RIGHT
	weapon_sprite.position = direction * (28.0 if state != PlayerState.SHOOT else 36.0) + Vector2(0, -26)
	weapon_sprite.rotation = direction.angle()
	weapon_sprite.flip_v = direction.x < -0.1
	weapon_sprite.scale = Vector2(0.75, 0.75) if state == PlayerState.SWAP_TOOL else Vector2.ONE

func _on_feedback_requested(kind: String, strength: float) -> void:
	match kind:
		"player_hit":
			_set_timed_state(PlayerState.HIT, 0.28)
		"player_dead":
			_set_timed_state(PlayerState.DEAD, 1.20)
	_start_camera_shake(strength)

func _start_camera_shake(strength: float) -> void:
	shake_timer = max(shake_timer, 0.16 + strength * 0.25)
	shake_strength = max(shake_strength, strength * 24.0)

func _update_camera_shake(delta: float) -> void:
	if camera == null:
		return
	if shake_timer <= 0.0:
		camera.offset = camera_base_offset
		shake_strength = 0.0
		return
	shake_timer = max(0.0, shake_timer - delta)
	var falloff: float = shake_timer / max(0.01, 0.20 + shake_strength * 0.01)
	var offset: Vector2 = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * shake_strength * clampf(falloff, 0.0, 1.0)
	camera.offset = camera_base_offset + offset
