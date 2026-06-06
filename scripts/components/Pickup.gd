extends Area2D
class_name RecyclerPickup

const PIXEL := preload("res://scripts/utils/PixelArtFactory.gd")
const ITEM_ATLAS_PATH := "res://assets/sprites/items/recycler_item_icons.png"

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
	sprite.texture = _item_texture(item_id)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(sprite)

func _item_texture(id: String) -> Texture2D:
	var atlas: Texture2D = _load_atlas_texture(ITEM_ATLAS_PATH)
	if atlas == null:
		return PIXEL.new().item_texture(id)
	var index := PixelArtFactory.ITEM_TYPES.find(id)
	if index < 0:
		index = 0
	var frame_size := PixelArtFactory.ITEM_FRAME_SIZE
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

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	GameState.add_item(item_id, amount)
	var label: String = String(DataRegistry.get_resource(item_id).get("name", item_id))
	GameState.notify("拾取 %s x%d" % [label, amount])
	queue_free()
