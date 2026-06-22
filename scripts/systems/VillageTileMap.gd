extends TileMap
class_name VillageTileMap

const TILE_SIZE := 32

const SOURCE_ID := 0
const TILE_FLOOR := Vector2i(0, 0)
const TILE_FLOOR_DARK := Vector2i(1, 0)
const TILE_PLATE := Vector2i(2, 0)
const TILE_HAZARD := Vector2i(3, 0)
const TILE_CRACKED := Vector2i(4, 0)
const TILE_PANEL := Vector2i(5, 0)

var map_size := Vector2i(78, 56)
var world_seed := 137


func setup(new_map_size: Vector2i, new_seed: int) -> void:
	map_size = new_map_size
	world_seed = new_seed
	_build_tileset()
	_generate_village_floor()


func _build_tileset() -> void:
	var image := Image.create(TILE_SIZE * 6, TILE_SIZE, false, Image.FORMAT_RGBA8)

	_fill_industrial_tile(image, TILE_FLOOR, Color8(86, 85, 77), Color8(54, 54, 49), false, false)
	_fill_industrial_tile(image, TILE_FLOOR_DARK, Color8(64, 65, 60), Color8(38, 39, 37), false, false)
	_fill_industrial_tile(image, TILE_PLATE, Color8(43, 47, 52), Color8(24, 27, 31), true, false)
	_fill_industrial_tile(image, TILE_HAZARD, Color8(76, 74, 62), Color8(198, 156, 67), true, true)
	_fill_industrial_tile(image, TILE_CRACKED, Color8(84, 83, 75), Color8(44, 43, 39), false, false, true)
	_fill_industrial_tile(image, TILE_PANEL, Color8(118, 113, 101), Color8(75, 71, 63), true, false)

	var texture := ImageTexture.create_from_image(image)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	var atlas_source := TileSetAtlasSource.new()
	atlas_source.texture = texture
	atlas_source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	for x in range(6):
		atlas_source.create_tile(Vector2i(x, 0))

	var new_tile_set := TileSet.new()
	new_tile_set.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)
	new_tile_set.add_source(atlas_source, SOURCE_ID)
	tile_set = new_tile_set


func _fill_industrial_tile(image: Image, tile_coords: Vector2i, base: Color, line: Color, rivets := false, hazard := false, cracked := false) -> void:
	var start_x := tile_coords.x * TILE_SIZE

	for y in range(TILE_SIZE):
		for x in range(TILE_SIZE):
			var shade := 0.0
			if ((x * 19 + y * 23 + tile_coords.x * 17) % 17) == 0:
				shade = 0.08
			var c := base.lerp(line, 0.08 + shade)
			image.set_pixel(start_x + x, y, c)

	# Main grid and bevel lines.
	for i in range(TILE_SIZE):
		image.set_pixel(start_x + i, 0, line.darkened(0.18))
		image.set_pixel(start_x + i, TILE_SIZE - 1, line.darkened(0.30))
		image.set_pixel(start_x, i, line.darkened(0.18))
		image.set_pixel(start_x + TILE_SIZE - 1, i, line.darkened(0.30))

	# Inner panel line, closer to the reference industrial-tile look.
	for i in range(3, TILE_SIZE - 3):
		image.set_pixel(start_x + i, 4, line.lightened(0.08))
		image.set_pixel(start_x + 4, i, line.lightened(0.06))

	if rivets:
		for p in [Vector2i(5, 5), Vector2i(26, 5), Vector2i(5, 26), Vector2i(26, 26)]:
			image.set_pixel(start_x + p.x, p.y, line.lightened(0.30))
			image.set_pixel(start_x + p.x + 1, p.y, line.lightened(0.16))
			image.set_pixel(start_x + p.x, p.y + 1, line.darkened(0.05))

	if hazard:
		for i in range(4, TILE_SIZE - 4):
			if (i / 4) % 2 == 0:
				image.set_pixel(start_x + i, 4, line)
				image.set_pixel(start_x + i, TILE_SIZE - 5, line)
				image.set_pixel(start_x + 4, i, line)
				image.set_pixel(start_x + TILE_SIZE - 5, i, line)

	if cracked:
		_draw_crack(image, start_x + 9, 8, [Vector2i(5, 5), Vector2i(8, -1), Vector2i(3, 7)], line.darkened(0.25))
		_draw_crack(image, start_x + 21, 17, [Vector2i(-5, 3), Vector2i(7, 5), Vector2i(2, 6)], line.darkened(0.20))


func _draw_crack(image: Image, start_x: int, start_y: int, offsets: Array[Vector2i], color: Color) -> void:
	var current := Vector2i(start_x, start_y)
	for offset in offsets:
		var target := current + offset
		_draw_pixel_line(image, current, target, color)
		current = target


func _draw_pixel_line(image: Image, from_pos: Vector2i, to_pos: Vector2i, color: Color) -> void:
	var delta := to_pos - from_pos
	var steps: int = max(abs(delta.x), abs(delta.y))
	if steps <= 0:
		return
	for i in range(steps + 1):
		var t := float(i) / float(steps)
		var p := Vector2i(roundi(lerp(float(from_pos.x), float(to_pos.x), t)), roundi(lerp(float(from_pos.y), float(to_pos.y), t)))
		if p.x >= 0 and p.y >= 0 and p.x < image.get_width() and p.y < image.get_height():
			image.set_pixel(p.x, p.y, color)


func _generate_village_floor() -> void:
	clear()
	for y in range(map_size.y):
		for x in range(map_size.x):
			var atlas_coords := _tile_for_position(x, y)
			set_cell(0, Vector2i(x, y), SOURCE_ID, atlas_coords)


func _tile_for_position(x: int, y: int) -> Vector2i:
	var rng_value := _hash2i(x, y)
	var cx := float(map_size.x) * 0.5
	var cy := float(map_size.y) * 0.5
	var plaza_shape: float = pow((float(x) - cx) / 10.5, 2.0) + pow((float(y) - cy) / 6.5, 2.0)
	var vertical_center: float = cx + sin(float(y) * 0.22) * 1.4
	var horizontal_center: float = cy + sin(float(x) * 0.18) * 1.2
	var vertical: bool = abs(float(x) - vertical_center) <= 2.2 and y >= 4 and y <= map_size.y - 2
	var horizontal: bool = abs(float(y) - horizontal_center) <= 2.2 and x >= 3 and x <= map_size.x - 2
	var shoulder: bool = plaza_shape <= 1.42 or abs(float(x) - vertical_center) <= 3.4 or abs(float(y) - horizontal_center) <= 3.4

	if plaza_shape <= 1.0 or vertical or horizontal:
		return TILE_FLOOR if rng_value % 9 != 0 else TILE_PANEL
	if shoulder:
		return TILE_FLOOR_DARK if rng_value % 5 != 0 else TILE_CRACKED
	if rng_value % 19 == 0:
		return TILE_HAZARD
	if rng_value % 11 == 0:
		return TILE_CRACKED
	if rng_value % 7 == 0:
		return TILE_PLATE
	return TILE_FLOOR_DARK


func _hash2i(x: int, y: int) -> int:
	var n := int(world_seed) + x * 374761393 + y * 668265263
	n = (n ^ (n >> 13)) * 1274126177
	return abs(n ^ (n >> 16))
