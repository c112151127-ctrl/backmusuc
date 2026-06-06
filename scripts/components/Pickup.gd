extends Area2D
class_name RecyclerPickup

const PIXEL := preload("res://scripts/utils/PixelArtFactory.gd")

@export var item_id := "scrap"
@export var amount := 1

func setup(id: String, count: int) -> void:
	item_id = id
	amount = count

func _ready() -> void:
	add_to_group("pickup")
	monitoring = true
	body_entered.connect(_on_body_entered)
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 18
	collision.shape = shape
	add_child(collision)
	var sprite := Sprite2D.new()
	sprite.texture = PIXEL.new().item_texture(item_id)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(sprite)

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	GameState.add_item(item_id, amount)
	var label: String = String(DataRegistry.get_resource(item_id).get("name", item_id))
	GameState.notify("拾取 %s x%d" % [label, amount])
	queue_free()
