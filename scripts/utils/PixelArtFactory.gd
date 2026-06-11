extends RefCounted
class_name PixelArtFactory

const PLAYER_FRAME_SIZE := Vector2i(48, 56)
const ENEMY_FRAME_SIZE := Vector2i(36, 34)
const ITEM_FRAME_SIZE := Vector2i(24, 24)
const PLAYER_ACTIONS := ["idle", "walk", "shoot", "draw_sword", "slash", "swap_tool", "interact"]
const ENEMY_TYPES := ["melee", "fast", "ranged", "heavy", "flying", "hybrid"]
const ITEM_TYPES := ["scrap", "ammo", "mutant_core", "bio_crystal"]

func make_texture(size: Vector2i, palette: Array[Color], pattern := 0) -> ImageTexture:
	return ImageTexture.create_from_image(make_image(size, palette, pattern))

func make_image(size: Vector2i, palette: Array[Color], pattern := 0) -> Image:
	var image := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	for y in size.y:
		for x in size.x:
			var color_index: int = abs((x / 4) + (y / 4) + pattern) % max(1, palette.size())
			var c := palette[color_index]
			if pattern % 3 == 0 and (x + y) % 11 == 0:
				c = c.lightened(0.18)
			if x < 2 or y < 2 or x >= size.x - 2 or y >= size.y - 2:
				c = c.darkened(0.35)
			image.set_pixel(x, y, c)
	return image

func player_texture(direction_index := 0, action_index := 0, frame_index := 0) -> ImageTexture:
	return ImageTexture.create_from_image(player_image(direction_index, action_index, frame_index))

func player_image(direction_index := 0, action_index := 0, frame_index := 0) -> Image:
	var palette: Array[Color] = [
		Color8(16, 20, 24),
		Color8(48, 57, 62),
		Color8(95, 111, 116),
		Color8(32, 219, 236),
		Color8(192, 112, 57),
		Color8(228, 229, 198),
		Color8(72, 221, 147)
	]
	var image := Image.create(PLAYER_FRAME_SIZE.x, PLAYER_FRAME_SIZE.y, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var sway: int = 0
	var bob: int = 0
	if action_index == 0:
		sway = 1 if frame_index == 1 else 0
	elif action_index == 1:
		var walk_offsets: Array[int] = [-1, 0, 1]
		sway = walk_offsets[frame_index]
		bob = abs(sway)
	var direction := _direction_vector(direction_index)
	var origin := Vector2i(24 + sway, 29 + bob)
	_fill_ellipse(image, Vector2i(24, 50), 15, 4, Color(0, 0, 0, 0.26))
	_draw_player_legs(image, origin, direction_index, action_index, frame_index, palette)
	_draw_player_body(image, origin, direction_index, palette)
	_draw_player_head(image, direction_index, direction, origin, palette)
	_draw_player_arms(image, direction_index, action_index, frame_index, origin, direction, palette)
	return image

func enemy_texture(enemy_type: String) -> ImageTexture:
	return ImageTexture.create_from_image(enemy_image(enemy_type))

func enemy_image(enemy_type: String) -> Image:
	var image := Image.create(ENEMY_FRAME_SIZE.x, ENEMY_FRAME_SIZE.y, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	_enemy_ellipse(image, Vector2i(18, 29), 13, 4, Color(0, 0, 0, 0.32))
	match enemy_type:
		"fast":
			_enemy_ellipse(image, Vector2i(18, 18), 11, 8, Color8(42, 76, 38))
			_enemy_ellipse(image, Vector2i(20, 15), 8, 5, Color8(110, 176, 57))
			_enemy_line(image, Vector2(8, 20), Vector2(1, 29), Color8(196, 220, 73), 2)
			_enemy_line(image, Vector2(28, 20), Vector2(35, 29), Color8(196, 220, 73), 2)
			_enemy_rect(image, 16, 9, 20, 12, Color8(218, 255, 91))
		"ranged":
			_enemy_ellipse(image, Vector2i(15, 18), 11, 10, Color8(88, 50, 64))
			_enemy_rect(image, 20, 13, 34, 18, Color8(84, 58, 54))
			_enemy_rect(image, 27, 14, 35, 16, Color8(232, 206, 82))
			_enemy_ellipse(image, Vector2i(12, 15), 4, 3, Color8(224, 90, 72))
			_enemy_line(image, Vector2(6, 24), Vector2(2, 30), Color8(92, 168, 64), 2)
		"heavy":
			_enemy_ellipse(image, Vector2i(18, 18), 15, 12, Color8(82, 66, 52))
			_enemy_ellipse(image, Vector2i(18, 19), 11, 8, Color8(138, 108, 78))
			_enemy_rect(image, 5, 10, 10, 27, Color8(49, 42, 36))
			_enemy_rect(image, 26, 10, 31, 27, Color8(49, 42, 36))
			_enemy_rect(image, 13, 12, 23, 15, Color8(219, 153, 84))
			_enemy_rect(image, 14, 21, 22, 24, Color8(44, 24, 21))
		"flying":
			_enemy_ellipse(image, Vector2i(18, 17), 8, 7, Color8(60, 88, 93))
			_enemy_line(image, Vector2(13, 14), Vector2(1, 8), Color8(143, 210, 210, 180), 3)
			_enemy_line(image, Vector2(23, 14), Vector2(35, 8), Color8(143, 210, 210, 180), 3)
			_enemy_line(image, Vector2(13, 18), Vector2(2, 24), Color8(90, 143, 146, 190), 3)
			_enemy_line(image, Vector2(23, 18), Vector2(34, 24), Color8(90, 143, 146, 190), 3)
			_enemy_rect(image, 16, 13, 20, 16, Color8(212, 245, 226))
		"hybrid":
			_enemy_ellipse(image, Vector2i(17, 18), 12, 10, Color8(65, 54, 76))
			_enemy_rect(image, 21, 11, 28, 24, Color8(70, 84, 88))
			_enemy_line(image, Vector2(8, 22), Vector2(2, 30), Color8(122, 69, 145), 2)
			_enemy_line(image, Vector2(25, 18), Vector2(35, 15), Color8(65, 198, 108), 2)
			_enemy_rect(image, 13, 13, 17, 16, Color8(222, 60, 77))
		_:
			_enemy_ellipse(image, Vector2i(18, 19), 13, 9, Color8(90, 52, 43))
			_enemy_ellipse(image, Vector2i(17, 17), 9, 6, Color8(151, 78, 52))
			_enemy_line(image, Vector2(9, 23), Vector2(3, 30), Color8(92, 168, 64), 2)
			_enemy_line(image, Vector2(27, 23), Vector2(33, 30), Color8(92, 168, 64), 2)
			_enemy_rect(image, 13, 15, 23, 18, Color8(42, 22, 18))
			_enemy_rect(image, 14, 13, 17, 15, Color8(224, 79, 61))
	return image

func _enemy_set(image: Image, x: int, y: int, color: Color) -> void:
	if x >= 0 and y >= 0 and x < image.get_width() and y < image.get_height():
		image.set_pixel(x, y, color)

func _enemy_rect(image: Image, x0: int, y0: int, x1: int, y1: int, color: Color) -> void:
	for y in range(min(y0, y1), max(y0, y1) + 1):
		for x in range(min(x0, x1), max(x0, x1) + 1):
			_enemy_set(image, x, y, color)

func _enemy_ellipse(image: Image, center: Vector2i, radius_x: int, radius_y: int, color: Color) -> void:
	for y in range(center.y - radius_y, center.y + radius_y + 1):
		for x in range(center.x - radius_x, center.x + radius_x + 1):
			var dx: float = float(x - center.x) / max(1.0, float(radius_x))
			var dy: float = float(y - center.y) / max(1.0, float(radius_y))
			if dx * dx + dy * dy <= 1.0:
				_enemy_set(image, x, y, color)

func _enemy_line(image: Image, from_point: Vector2, to_point: Vector2, color: Color, width := 1) -> void:
	var steps := int(max(abs(to_point.x - from_point.x), abs(to_point.y - from_point.y)))
	if steps <= 0:
		_enemy_ellipse(image, Vector2i(int(from_point.x), int(from_point.y)), width, width, color)
		return
	for i in range(steps + 1):
		var t := float(i) / float(steps)
		var p := from_point.lerp(to_point, t)
		_enemy_ellipse(image, Vector2i(int(round(p.x)), int(round(p.y))), width, width, color)

func item_texture(item_id: String) -> ImageTexture:
	return ImageTexture.create_from_image(item_image(item_id))

func item_image(item_id: String) -> Image:
	var palette: Array[Color] = [Color8(82, 69, 55), Color8(168, 107, 52), Color8(66, 186, 204)]
	if item_id == "ammo":
		palette = [Color8(58, 64, 71), Color8(208, 187, 87), Color8(120, 80, 52)]
	elif item_id == "mutant_core":
		palette = [Color8(82, 24, 28), Color8(214, 50, 61), Color8(245, 112, 95)]
	elif item_id == "bio_crystal":
		palette = [Color8(54, 27, 77), Color8(179, 85, 225), Color8(76, 221, 148)]
	return make_image(ITEM_FRAME_SIZE, palette, item_id.length())

func _draw_player_legs(image: Image, origin: Vector2i, direction_index: int, action_index: int, frame_index: int, palette: Array[Color]) -> void:
	var stride := 0
	if action_index == 1:
		stride = [-2, 0, 2][frame_index]
	var left_x := origin.x - 7
	var right_x := origin.x + 5
	var front_y := 37 if direction_index in [1, 2, 3] else 36
	_fill_rect(image, left_x - 2, front_y, left_x + 3, 48 + max(0, stride), palette[0])
	_fill_rect(image, right_x - 2, front_y, right_x + 3, 48 - min(0, stride), palette[0])
	_fill_rect(image, left_x - 1, front_y + 2, left_x + 2, 46 + max(0, stride), palette[2].darkened(0.18))
	_fill_rect(image, right_x - 1, front_y + 2, right_x + 2, 46 - min(0, stride), palette[2].darkened(0.05))
	_fill_rect(image, left_x - 4, 48 + max(0, stride), left_x + 5, 51 + max(0, stride), palette[0])
	_fill_rect(image, right_x - 4, 48 - min(0, stride), right_x + 5, 51 - min(0, stride), palette[0])

func _draw_player_body(image: Image, origin: Vector2i, direction_index: int, palette: Array[Color]) -> void:
	var shoulder_y := origin.y - 9
	var waist_y := origin.y + 11
	_fill_ellipse(image, Vector2i(origin.x, origin.y + 1), 12, 15, palette[0])
	_fill_rect(image, origin.x - 10, shoulder_y, origin.x + 10, waist_y, palette[1])
	_fill_rect(image, origin.x - 7, shoulder_y + 3, origin.x + 7, waist_y - 2, palette[2])
	_fill_rect(image, origin.x - 2, shoulder_y + 1, origin.x + 2, waist_y + 1, palette[3].darkened(0.18))
	if direction_index in [5, 6, 7]:
		_fill_rect(image, origin.x - 8, shoulder_y + 3, origin.x + 8, waist_y, palette[0].lightened(0.1))
		_fill_rect(image, origin.x - 4, shoulder_y + 6, origin.x + 4, waist_y - 3, palette[3].darkened(0.35))
	else:
		_fill_rect(image, origin.x - 5, shoulder_y + 6, origin.x + 5, shoulder_y + 9, palette[3])
		_set_pixel_safe(image, origin.x + 7, shoulder_y + 7, palette[5])

func _draw_player_head(image: Image, direction_index: int, direction: Vector2, origin: Vector2i, palette: Array[Color]) -> void:
	var head_center := Vector2i(origin.x, origin.y - 17)
	_fill_ellipse(image, head_center, 10, 9, palette[0])
	_fill_ellipse(image, Vector2i(head_center.x, head_center.y + 1), 8, 7, palette[1])
	var visor_center := Vector2i(
		head_center.x + int(round(direction.x * 4.0)),
		head_center.y + int(round(direction.y * 3.0))
	)
	if direction_index in [5, 6, 7]:
		_fill_rect(image, head_center.x - 5, head_center.y - 1, head_center.x + 5, head_center.y + 4, palette[0].lightened(0.16))
		_fill_rect(image, head_center.x - 2, head_center.y + 2, head_center.x + 2, head_center.y + 5, palette[3].darkened(0.45))
	else:
		_fill_rect(image, visor_center.x - 5, visor_center.y - 2, visor_center.x + 5, visor_center.y + 2, palette[3])
		_fill_rect(image, visor_center.x + 2, visor_center.y - 1, visor_center.x + 5, visor_center.y + 1, palette[5])

func _draw_player_arms(image: Image, direction_index: int, action_index: int, frame_index: int, origin: Vector2i, direction: Vector2, palette: Array[Color]) -> void:
	var side := 1 if direction.x >= 0.0 else -1
	var shoulder_left := Vector2(origin.x - 11, origin.y - 7)
	var shoulder_right := Vector2(origin.x + 11, origin.y - 7)
	var idle_left := Vector2(origin.x - 14, origin.y + 9)
	var idle_right := Vector2(origin.x + 14, origin.y + 9)
	_draw_line(image, shoulder_left, idle_left, palette[4], 2)
	_draw_line(image, shoulder_right, idle_right, palette[4], 2)
	if action_index == 2:
		var hand := Vector2(origin.x, origin.y - 1) + direction * 8.0
		var muzzle := Vector2(origin.x, origin.y - 1) + direction * (18.0 + frame_index * 2.0)
		_draw_line(image, Vector2(origin.x, origin.y - 3), hand, palette[4].lightened(0.12), 2)
		_draw_line(image, hand, muzzle, palette[0], 3)
		_draw_line(image, hand, muzzle, palette[2].lightened(0.22), 1)
		_fill_ellipse(image, Vector2i(int(muzzle.x), int(muzzle.y)), 2 + frame_index, 2 + frame_index, palette[3].lightened(0.2))
	elif action_index == 3:
		var hip: Vector2 = Vector2(origin.x - side * 8, origin.y + 10)
		var draw_hand: Vector2 = Vector2(origin.x + side * (2 + frame_index * 3), origin.y - 2 - frame_index)
		_draw_line(image, hip, draw_hand, palette[4], 2)
		_draw_line(image, hip + Vector2(0, 5), draw_hand + Vector2(side * 4, -4), palette[5].darkened(0.12), 1)
	elif action_index == 4:
		var slash_center: Vector2 = Vector2(origin.x, origin.y - 4) + direction * 12.0
		for i in range(-7, 8):
			var tangent: Vector2 = direction.rotated(PI * 0.5) * float(i)
			var forward: Vector2 = direction * (abs(i) * -0.45 + frame_index * 2.0)
			var slash_point: Vector2 = slash_center + tangent + forward
			_fill_ellipse(image, Vector2i(int(slash_point.x), int(slash_point.y)), 2, 2, palette[5])
			_set_pixel_safe(image, int(slash_point.x - direction.x * 2.0), int(slash_point.y - direction.y * 2.0), palette[3].lightened(0.12))
		_draw_line(image, Vector2(origin.x, origin.y - 1), slash_center + direction * 6.0, palette[4], 2)
	elif action_index == 5:
		var tool_center := Vector2i(origin.x + side * (9 + frame_index), origin.y + 1)
		_fill_rect(image, tool_center.x - 4, tool_center.y - 4, tool_center.x + 5, tool_center.y + 5, palette[4].lightened(0.2))
		_fill_rect(image, tool_center.x - 2, tool_center.y - 2, tool_center.x + 3, tool_center.y + 3, palette[3].darkened(0.2))
		_draw_line(image, Vector2(origin.x + side * 10, origin.y - 5), Vector2(tool_center), palette[4], 2)
	elif action_index == 6:
		var interact_hand: Vector2 = Vector2(origin.x, origin.y - 1) + direction * (10.0 + frame_index)
		_draw_line(image, Vector2(origin.x, origin.y - 4), interact_hand, palette[4], 2)
		for i in range(1, 4):
			var scan_point: Vector2 = interact_hand + direction * float(i * 4)
			_fill_ellipse(image, Vector2i(int(scan_point.x), int(scan_point.y)), 2, 2, palette[6].lightened(0.1))

func _direction_vector(direction_index: int) -> Vector2:
	return Vector2(cos(float(direction_index) * PI / 4.0), sin(float(direction_index) * PI / 4.0)).normalized()

func _set_pixel_safe(image: Image, x: int, y: int, color: Color) -> void:
	if x >= 0 and y >= 0 and x < PLAYER_FRAME_SIZE.x and y < PLAYER_FRAME_SIZE.y:
		image.set_pixel(x, y, color)

func _fill_rect(image: Image, x0: int, y0: int, x1: int, y1: int, color: Color) -> void:
	var min_x: int = clamp(min(x0, x1), 0, PLAYER_FRAME_SIZE.x - 1)
	var max_x: int = clamp(max(x0, x1), 0, PLAYER_FRAME_SIZE.x - 1)
	var min_y: int = clamp(min(y0, y1), 0, PLAYER_FRAME_SIZE.y - 1)
	var max_y: int = clamp(max(y0, y1), 0, PLAYER_FRAME_SIZE.y - 1)
	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			image.set_pixel(x, y, color)

func _fill_ellipse(image: Image, center: Vector2i, radius_x: int, radius_y: int, color: Color) -> void:
	for y in range(center.y - radius_y, center.y + radius_y + 1):
		for x in range(center.x - radius_x, center.x + radius_x + 1):
			var dx: float = float(x - center.x) / max(1.0, float(radius_x))
			var dy: float = float(y - center.y) / max(1.0, float(radius_y))
			if dx * dx + dy * dy <= 1.0:
				_set_pixel_safe(image, x, y, color)

func _draw_line(image: Image, from_point: Vector2, to_point: Vector2, color: Color, width := 1) -> void:
	var steps := int(max(abs(to_point.x - from_point.x), abs(to_point.y - from_point.y)))
	if steps <= 0:
		_fill_ellipse(image, Vector2i(int(from_point.x), int(from_point.y)), width, width, color)
		return
	for i in range(steps + 1):
		var t := float(i) / float(steps)
		var p := from_point.lerp(to_point, t)
		_fill_ellipse(image, Vector2i(int(round(p.x)), int(round(p.y))), width, width, color)
