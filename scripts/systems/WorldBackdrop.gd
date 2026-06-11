extends Node2D
class_name WorldBackdrop

const ASSET_LOADER := preload("res://scripts/utils/RuntimeAssetLoader.gd")

var mode := "village"
var map_size := Vector2i(60, 40)
var tile_size := 32
var world_seed := 9527
var tile_texture: Texture2D

func setup(new_mode: String, size_tiles: Vector2i, new_seed: int) -> void:
	mode = new_mode
	map_size = size_tiles
	world_seed = new_seed
	tile_texture = _load_tile_texture()
	queue_redraw()

func _draw() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = world_seed
	var base := Color8(43, 39, 32) if mode == "village" else Color8(34, 31, 28)
	var alt := Color8(61, 54, 43) if mode == "village" else Color8(50, 44, 38)
	var stain := Color8(42, 97, 67) if mode == "wasteland" else Color8(84, 74, 56)
	for y in map_size.y:
		for x in map_size.x:
			var rect := Rect2(x * tile_size, y * tile_size, tile_size, tile_size)
			var c := base.lerp(alt, rng.randf_range(0.0, 0.35))
			var road_strength := _road_strength(x, y)
			if road_strength > 0.0:
				c = c.lerp(Color8(94, 82, 62), road_strength)
			if mode == "wasteland" and rng.randf() < 0.08:
				c = c.lerp(stain, 0.55)
			if tile_texture != null:
				draw_texture_rect(tile_texture, rect, false)
				draw_rect(rect, Color(c.r, c.g, c.b, 0.24 + road_strength * 0.2))
			else:
				draw_rect(rect, c)
			if (x + y) % 5 == 0:
				draw_rect(rect, Color(0, 0, 0, 0.08), false, 1.0)
			if mode == "wasteland" and rng.randf() < 0.025:
				draw_circle(rect.position + Vector2(rng.randf_range(8, 24), rng.randf_range(8, 24)), rng.randf_range(2.0, 5.0), Color(0.22, 0.45, 0.25, 0.45))
			if road_strength > 0.0 and (x + y) % 4 == 0:
				draw_rect(rect.grow(-7), Color(0.72, 0.62, 0.42, 0.08), false, 1.0)

func _road_strength(x: int, y: int) -> float:
	if mode == "village":
		var plaza: bool = x >= 14 and x <= 45 and y >= 9 and y <= 31
		var vertical: bool = x >= 22 and x <= 26 and y >= 5 and y <= 40
		var horizontal: bool = y >= 17 and y <= 21 and x >= 6 and x <= 58
		return 0.75 if plaza or vertical or horizontal else 0.0
	if mode == "guild":
		var hall: bool = x >= 8 and x <= 42 and y >= 6 and y <= 23
		var cross: bool = (x >= 23 and x <= 27) or (y >= 14 and y <= 17)
		return 0.65 if hall and cross else 0.0
	if mode == "wasteland":
		var trail: bool = abs(y - int(map_size.y * 0.72) - int(sin(float(x) * 0.14) * 5.0)) <= 2
		var branch: bool = abs(x - int(map_size.x * 0.5) - int(sin(float(y) * 0.11) * 4.0)) <= 1 and y > map_size.y * 0.35
		return 0.42 if trail or branch else 0.0
	return 0.0

func _load_tile_texture() -> Texture2D:
	var path := "res://assets/sprites/tiles/village_ground_2p5d.png"
	if mode == "guild":
		path = "res://assets/sprites/tiles/guild_ground_2p5d.png"
	elif mode == "wasteland":
		path = "res://assets/sprites/tiles/wasteland_ground_2p5d.png"
	return ASSET_LOADER.load_png(path)
