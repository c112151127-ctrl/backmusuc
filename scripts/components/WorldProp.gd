extends StaticBody2D
class_name WorldProp

const PIXEL := preload("res://scripts/utils/PixelArtFactory.gd")

var prop_id := "rust_rock"
var blocks_movement := true
var visual_size := Vector2i(56, 56)
var collision_size := Vector2(42, 24)

func setup(id: String, blocking := true, size := Vector2i(56, 56)) -> void:
	prop_id = id
	blocks_movement = blocking
	visual_size = size
	collision_size = Vector2(max(24, size.x * 0.72), max(16, size.y * 0.28))

func _ready() -> void:
	add_to_group("world_prop")
	y_sort_enabled = true
	if blocks_movement:
		add_to_group("obstacle")
		_add_collision()
	_add_sprite()

func _add_collision() -> void:
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = collision_size
	collision.shape = shape
	collision.position = Vector2(0, -collision_size.y * 0.5)
	add_child(collision)

func _add_sprite() -> void:
	var sprite := Sprite2D.new()
	sprite.texture = _make_prop_texture()
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.centered = false
	sprite.position = Vector2(-visual_size.x * 0.5, -visual_size.y)
	add_child(sprite)

func _make_prop_texture() -> Texture2D:
	var palette: Array[Color] = [Color8(62, 55, 48), Color8(101, 83, 63), Color8(158, 103, 57)]
	match prop_id:
		"dead_tree":
			palette = [Color8(48, 39, 32), Color8(96, 70, 48), Color8(135, 95, 55)]
		"scrap_wall":
			palette = [Color8(39, 44, 49), Color8(92, 102, 103), Color8(190, 122, 55)]
		"toxic_pool":
			palette = [Color8(31, 47, 38), Color8(63, 149, 76), Color8(162, 221, 82)]
		"wreck":
			palette = [Color8(43, 42, 46), Color8(87, 93, 99), Color8(179, 75, 54)]
		"signal_pylon":
			palette = [Color8(35, 34, 42), Color8(84, 102, 122), Color8(68, 210, 226)]
		"road_marker":
			palette = [Color8(60, 52, 42), Color8(180, 139, 66), Color8(229, 207, 88)]
	var image := PIXEL.new().make_image(visual_size, palette, prop_id.length())
	_carve_shape(image)
	return ImageTexture.create_from_image(image)

func _carve_shape(image: Image) -> void:
	match prop_id:
		"dead_tree":
			_clear_outside_trunk(image)
		"toxic_pool":
			_clear_corners(image, 0.34)
		"signal_pylon":
			_clear_outside_pylon(image)
		"road_marker":
			_clear_corners(image, 0.2)
		_:
			_clear_corners(image, 0.18)

func _clear_corners(image: Image, edge_ratio: float) -> void:
	var size: Vector2i = image.get_size()
	var center := Vector2(size.x * 0.5, size.y * 0.55)
	var radius: float = min(size.x, size.y) * (0.5 + edge_ratio)
	for y in size.y:
		for x in size.x:
			var point := Vector2(x, y)
			if point.distance_to(center) > radius and y < size.y * 0.82:
				image.set_pixel(x, y, Color(0, 0, 0, 0))

func _clear_outside_trunk(image: Image) -> void:
	var size: Vector2i = image.get_size()
	for y in size.y:
		for x in size.x:
			var trunk_width: int = 7 + int((float(y) / max(1.0, size.y)) * 12.0)
			var trunk_center: int = size.x / 2 + int(sin(float(y) * 0.14) * 4.0)
			var crown: bool = y < size.y * 0.32 and abs(x - trunk_center) < 20
			var trunk: bool = abs(x - trunk_center) < trunk_width
			if not crown and not trunk:
				image.set_pixel(x, y, Color(0, 0, 0, 0))

func _clear_outside_pylon(image: Image) -> void:
	var size: Vector2i = image.get_size()
	for y in size.y:
		for x in size.x:
			var center_x: int = size.x / 2
			var arm: bool = y > size.y * 0.18 and y < size.y * 0.28 and abs(x - center_x) < 22
			var mast: bool = abs(x - center_x) < 5
			var legs: bool = y > size.y * 0.56 and (abs(x - (center_x - 10)) < 4 or abs(x - (center_x + 10)) < 4)
			if not arm and not mast and not legs:
				image.set_pixel(x, y, Color(0, 0, 0, 0))
