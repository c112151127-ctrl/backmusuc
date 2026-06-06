extends Area2D
class_name RecyclerProjectile

const PIXEL := preload("res://scripts/utils/PixelArtFactory.gd")

var direction := Vector2.RIGHT
var speed := 520.0
var damage := 8
var life := 1.2

func setup(start: Vector2, dir: Vector2, projectile_damage: int) -> void:
	global_position = start
	direction = dir.normalized()
	damage = projectile_damage

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
	global_position += direction * speed * delta
	rotation = direction.angle()
	life -= delta
	if life <= 0.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("enemy") and body.has_method("take_damage"):
		body.take_damage(damage, false)
		queue_free()
