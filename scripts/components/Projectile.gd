extends Area2D
class_name RecyclerProjectile

const PIXEL := preload("res://scripts/utils/PixelArtFactory.gd")

var direction := Vector2.RIGHT
var speed := 520.0
var damage := 8
var life := 1.2
var max_life := 1.2
var is_active := true
var pool_owner: Node
var target_group := "enemy"

func setup(start: Vector2, dir: Vector2, projectile_damage: int, new_target_group := "enemy") -> void:
	global_position = start
	direction = dir.normalized()
	damage = projectile_damage
	target_group = new_target_group
	life = max_life
	is_active = true
	visible = true
	monitoring = true
	set_physics_process(true)

func setup_pooled(start: Vector2, dir: Vector2, projectile_damage: int, owner: Node, new_target_group := "enemy") -> void:
	pool_owner = owner
	setup(start, dir, projectile_damage, new_target_group)

func _ready() -> void:
	add_to_group("projectile")
	monitoring = true
	body_entered.connect(_on_body_entered)
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 7
	collision.shape = shape
	add_child(collision)
	var sprite := Sprite2D.new()
	sprite.texture = PIXEL.new().make_texture(Vector2i(14, 8), [Color8(54, 210, 226), Color8(228, 185, 67), Color8(50, 51, 57)], 4)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(sprite)

func _physics_process(delta: float) -> void:
	if not is_active:
		return
	global_position += direction * speed * delta
	rotation = direction.angle()
	life -= delta
	if life <= 0.0:
		_release()

func _on_body_entered(body: Node) -> void:
	if not is_active:
		return
	if body.is_in_group(target_group):
		if body.has_method("take_damage"):
			body.take_damage(damage, false)
		elif target_group == "player":
			GameState.take_damage(damage)
		_release()

func deactivate() -> void:
	is_active = false
	visible = false
	set_deferred("monitoring", false)
	set_physics_process(false)
	global_position = Vector2(-100000, -100000)

func _release() -> void:
	if pool_owner != null and pool_owner.has_method("release"):
		pool_owner.release(self)
	else:
		call_deferred("queue_free")
