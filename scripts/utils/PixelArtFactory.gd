extends RefCounted
class_name PixelArtFactory

const PLAYER_FRAME_SIZE := Vector2i(32, 40)
const ENEMY_FRAME_SIZE := Vector2i(36, 34)
const ITEM_FRAME_SIZE := Vector2i(24, 24)
const PLAYER_ACTIONS := ["idle", "move", "melee", "shoot", "swap_tool"]
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
		Color8(42, 48, 55),
		Color8(96, 112, 118),
		Color8(23, 185, 200),
		Color8(169, 103, 54),
		Color8(210, 212, 190)
	]
	var image := Image.create(PLAYER_FRAME_SIZE.x, PLAYER_FRAME_SIZE.y, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var sway: int = 0
	if action_index == 0:
		sway = 1 if frame_index == 1 else 0
	elif action_index == 1:
		var walk_offsets: Array[int] = [-1, 0, 1]
		sway = walk_offsets[frame_index]
	var dir_offset := Vector2i(int(round(cos(direction_index * PI / 4.0))), int(round(sin(direction_index * PI / 4.0))))
	for y in range(6, 38):
		for x in range(8 + sway, 24 + sway):
			var edge: bool = x < 10 + sway or x > 21 + sway or y < 8 or y > 35
			var c: Color = palette[1] if not edge else palette[0]
			if y < 16:
				c = palette[0]
			if (x + y + direction_index + action_index + frame_index) % 9 == 0:
				c = palette[2]
			if x >= 0 and x < PLAYER_FRAME_SIZE.x:
				image.set_pixel(x, y, c)
	_draw_player_head(image, direction_index, dir_offset)
	_draw_player_arms(image, direction_index, action_index, frame_index, sway, palette)
	return image

func enemy_texture(enemy_type: String) -> ImageTexture:
	return ImageTexture.create_from_image(enemy_image(enemy_type))

func enemy_image(enemy_type: String) -> Image:
	var palettes := {
		"melee": [Color8(78, 50, 42), Color8(140, 77, 48), Color8(92, 168, 64)],
		"fast": [Color8(38, 48, 36), Color8(94, 151, 54), Color8(196, 220, 73)],
		"ranged": [Color8(68, 44, 58), Color8(163, 68, 64), Color8(210, 200, 73)],
		"heavy": [Color8(48, 43, 39), Color8(126, 102, 82), Color8(198, 137, 74)],
		"flying": [Color8(44, 45, 54), Color8(90, 143, 146), Color8(191, 228, 219)],
		"hybrid": [Color8(35, 33, 39), Color8(122, 69, 145), Color8(65, 198, 108)]
	}
	var palette: Array[Color] = []
	for c in palettes.get(enemy_type, palettes["melee"]):
		palette.append(c)
	var image := make_image(ENEMY_FRAME_SIZE, palette, enemy_type.length())
	if enemy_type == "ranged":
		for x in range(24, 34):
			image.set_pixel(x, 15, Color8(230, 198, 82))
			image.set_pixel(x, 16, Color8(230, 198, 82))
	elif enemy_type == "flying":
		for x in range(2, 12):
			image.set_pixel(x, 8 + x % 4, Color8(191, 228, 219, 190))
		for x in range(24, 34):
			image.set_pixel(x, 8 + x % 4, Color8(191, 228, 219, 190))
	elif enemy_type == "heavy":
		for y in range(8, 28):
			image.set_pixel(5, y, Color8(42, 36, 33))
			image.set_pixel(30, y, Color8(42, 36, 33))
	return image

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

func _draw_player_head(image: Image, direction_index: int, dir_offset: Vector2i) -> void:
	var visor_color := Color8(36, 216, 230)
	var shadow_color := Color8(18, 25, 31)
	for y in range(8, 15):
		for x in range(11, 21):
			if (x - 16) * (x - 16) + (y - 11) * (y - 11) < 38:
				image.set_pixel(x, y, shadow_color)
	var visor_y: int = clamp(11 + dir_offset.y, 8, 15)
	var visor_x: int = clamp(16 + dir_offset.x * 2, 11, 21)
	for x in range(visor_x - 3, visor_x + 4):
		if x >= 0 and x < PLAYER_FRAME_SIZE.x:
			image.set_pixel(x, visor_y, visor_color)
	if direction_index in [6, 7, 0]:
		var glint_x: int = clamp(visor_x + 3, 0, PLAYER_FRAME_SIZE.x - 1)
		image.set_pixel(glint_x, visor_y + 1, visor_color.lightened(0.2))

func _draw_player_arms(image: Image, direction_index: int, action_index: int, frame_index: int, sway: int, palette: Array[Color]) -> void:
	var dir_side: int = 1 if direction_index in [7, 0, 1] else -1
	var left_arm_x: int = clamp(7 + sway - dir_side, 0, PLAYER_FRAME_SIZE.x - 1)
	var right_arm_x: int = clamp(24 + sway + dir_side, 0, PLAYER_FRAME_SIZE.x - 1)
	for y in range(15, 28):
		image.set_pixel(left_arm_x, y, palette[3])
		image.set_pixel(right_arm_x, y, palette[3])
	if action_index == 1:
		var raw_blade_x: int = 5 + frame_index * 5 if dir_side < 0 else 26 - frame_index * 5
		var blade_x: int = clamp(raw_blade_x, 0, PLAYER_FRAME_SIZE.x - 1)
		for y in range(10, 31):
			image.set_pixel(blade_x, y, palette[4])
			if blade_x + dir_side >= 0 and blade_x + dir_side < PLAYER_FRAME_SIZE.x:
				image.set_pixel(blade_x + dir_side, y, Color8(238, 241, 215))
	elif action_index == 2:
		var muzzle_y: int = clamp(18 + frame_index, 0, PLAYER_FRAME_SIZE.y - 1)
		var start_x: int = 22 if dir_side > 0 else 2
		for x in range(start_x, start_x + 9):
			var raw_px: int = x if dir_side > 0 else PLAYER_FRAME_SIZE.x - x
			var px: int = clamp(raw_px, 0, PLAYER_FRAME_SIZE.x - 1)
			image.set_pixel(px, muzzle_y, Color8(58, 210, 226))
	elif action_index == 3:
		for y in range(18, 30):
			var tool_x: int = clamp(15 + frame_index - 1, 0, PLAYER_FRAME_SIZE.x - 1)
			image.set_pixel(tool_x, y, Color8(237, 145, 68))
