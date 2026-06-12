extends Node

const PIXEL := preload("res://scripts/utils/PixelArtFactory.gd")

func _ready() -> void:
	var factory := PIXEL.new()
	_ensure_asset_dirs()
	_save_player_sheet(factory)
	_save_enemy_sheet(factory)
	_save_item_sheet(factory)
	_save_tile_sheet(factory)
	print("[ASSET] Pixel asset baking complete")
	get_tree().quit(0)

func _ensure_asset_dirs() -> void:
	for path in [
		"res://assets/sprites/player",
		"res://assets/sprites/enemies",
		"res://assets/sprites/items",
		"res://assets/sprites/tiles"
	]:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path))

func _save_player_sheet(factory: PixelArtFactory) -> void:
	var frame_size := PixelArtFactory.PLAYER_FRAME_SIZE
	var output_path := "res://assets/sprites/player/recycler_player_multiaction_8dir.png"
	if _asset_has_size(output_path, Vector2i(frame_size.x * PixelArtFactory.PLAYER_FRAMES_PER_ACTION * PixelArtFactory.PLAYER_ACTIONS.size(), frame_size.y * 8)):
		print("[ASSET] Kept reference-sheet player atlas")
		return
	var sheet := Image.create(frame_size.x * PixelArtFactory.PLAYER_FRAMES_PER_ACTION * PixelArtFactory.PLAYER_ACTIONS.size(), frame_size.y * 8, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0, 0, 0, 0))
	for action_index in PixelArtFactory.PLAYER_ACTIONS.size():
		for direction_index in range(8):
			for frame_index in range(PixelArtFactory.PLAYER_FRAMES_PER_ACTION):
				var frame := factory.player_image(direction_index, action_index, frame_index)
				var dest := Vector2i((action_index * PixelArtFactory.PLAYER_FRAMES_PER_ACTION + frame_index) * frame_size.x, direction_index * frame_size.y)
				sheet.blit_rect(frame, Rect2i(Vector2i.ZERO, frame_size), dest)
	sheet.save_png(output_path)

func _save_enemy_sheet(factory: PixelArtFactory) -> void:
	var frame_size := PixelArtFactory.ENEMY_FRAME_SIZE
	var output_path := "res://assets/sprites/enemies/polluted_enemy_six_types.png"
	if _asset_has_size(output_path, Vector2i(frame_size.x * PixelArtFactory.ENEMY_TYPES.size(), frame_size.y)):
		print("[ASSET] Kept reference-sheet enemy atlas")
		return
	var sheet := Image.create(frame_size.x * PixelArtFactory.ENEMY_TYPES.size(), frame_size.y, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0, 0, 0, 0))
	for i in PixelArtFactory.ENEMY_TYPES.size():
		var frame := factory.enemy_image(PixelArtFactory.ENEMY_TYPES[i])
		sheet.blit_rect(frame, Rect2i(Vector2i.ZERO, frame_size), Vector2i(i * frame_size.x, 0))
	sheet.save_png(output_path)

func _save_item_sheet(factory: PixelArtFactory) -> void:
	var frame_size := PixelArtFactory.ITEM_FRAME_SIZE
	var output_path := "res://assets/sprites/items/recycler_item_icons.png"
	if _asset_has_size(output_path, Vector2i(frame_size.x * PixelArtFactory.ITEM_TYPES.size(), frame_size.y)):
		print("[ASSET] Kept reference-sheet item atlas")
		return
	var sheet := Image.create(frame_size.x * PixelArtFactory.ITEM_TYPES.size(), frame_size.y, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0, 0, 0, 0))
	for i in PixelArtFactory.ITEM_TYPES.size():
		var frame := factory.item_image(PixelArtFactory.ITEM_TYPES[i])
		sheet.blit_rect(frame, Rect2i(Vector2i.ZERO, frame_size), Vector2i(i * frame_size.x, 0))
	sheet.save_png(output_path)

func _save_tile_sheet(factory: PixelArtFactory) -> void:
	var tile_size := Vector2i(32, 32)
	var palettes: Array[Array] = [
		[Color8(43, 39, 32), Color8(61, 54, 43), Color8(84, 74, 56)],
		[Color8(34, 31, 28), Color8(50, 44, 38), Color8(42, 97, 67)],
		[Color8(72, 92, 96), Color8(109, 126, 124), Color8(42, 48, 55)],
		[Color8(102, 68, 45), Color8(164, 107, 62), Color8(223, 141, 74)],
		[Color8(60, 45, 39), Color8(82, 69, 55), Color8(168, 107, 52)],
		[Color8(54, 27, 77), Color8(179, 85, 225), Color8(76, 221, 148)]
	]
	var sheet := Image.create(tile_size.x * palettes.size(), tile_size.y, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0, 0, 0, 0))
	for i in palettes.size():
		var palette: Array[Color] = []
		for c in palettes[i]:
			palette.append(c)
		var tile := factory.make_image(tile_size, palette, i)
		sheet.blit_rect(tile, Rect2i(Vector2i.ZERO, tile_size), Vector2i(i * tile_size.x, 0))
	sheet.save_png("res://assets/sprites/tiles/recycler_tileset.png")

func _asset_has_size(path: String, expected_size: Vector2i) -> bool:
	var absolute_path := ProjectSettings.globalize_path(path)
	if not FileAccess.file_exists(absolute_path):
		return false
	var image := Image.load_from_file(absolute_path)
	return image != null and image.get_size() == expected_size and image.get_used_rect().size != Vector2i.ZERO
