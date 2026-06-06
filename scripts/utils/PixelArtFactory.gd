extends RefCounted
class_name PixelArtFactory

func make_texture(size: Vector2i, palette: Array[Color], pattern := 0) -> ImageTexture:
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
	return ImageTexture.create_from_image(image)

func player_texture(direction_index := 0, action_index := 0, frame_index := 0) -> ImageTexture:
	var palette: Array[Color] = [
		Color8(42, 48, 55),
		Color8(96, 112, 118),
		Color8(23, 185, 200),
		Color8(169, 103, 54)
	]
	var image := Image.create(32, 40, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	for y in range(6, 38):
		for x in range(8, 24):
			var edge: bool = x < 10 or x > 21 or y < 8 or y > 35
			var c: Color = palette[1] if not edge else palette[0]
			if y < 16:
				c = palette[0]
			if (x + y + direction_index + action_index + frame_index) % 9 == 0:
				c = palette[2]
			image.set_pixel(x, y, c)
	for y in range(14, 28):
		var arm_x: int = 5 if action_index == 1 else 25
		if action_index == 2:
			arm_x = 24 + frame_index
		elif action_index == 3:
			arm_x = 7 + frame_index
		if arm_x >= 0 and arm_x < 32:
			image.set_pixel(arm_x, y, palette[3])
			image.set_pixel(clamp(arm_x + (direction_index % 3) - 1, 0, 31), y, palette[3])
	if action_index == 1:
		var blade_x: int = clamp(4 + frame_index * 3, 0, 31)
		for y in range(10, 30):
			image.set_pixel(blade_x, y, Color8(210, 212, 190))
	if action_index == 2:
		for x in range(22, 31):
			image.set_pixel(x, 18 + frame_index, Color8(58, 210, 226))
	return ImageTexture.create_from_image(image)

func enemy_texture(enemy_type: String) -> ImageTexture:
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
	return make_texture(Vector2i(36, 34), palette, enemy_type.length())

func item_texture(item_id: String) -> ImageTexture:
	var palette: Array[Color] = [Color8(82, 69, 55), Color8(168, 107, 52), Color8(66, 186, 204)]
	if item_id == "ammo":
		palette = [Color8(58, 64, 71), Color8(208, 187, 87), Color8(120, 80, 52)]
	elif item_id == "mutant_core":
		palette = [Color8(82, 24, 28), Color8(214, 50, 61), Color8(245, 112, 95)]
	elif item_id == "bio_crystal":
		palette = [Color8(54, 27, 77), Color8(179, 85, 225), Color8(76, 221, 148)]
	return make_texture(Vector2i(24, 24), palette, item_id.length())
