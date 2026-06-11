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
			if mode == "wasteland" and rng.randf() < 0.08:
				c = c.lerp(stain, 0.55)
			if tile_texture != null:
				draw_texture_rect(tile_texture, rect, false)
				draw_rect(rect, Color(c.r, c.g, c.b, 0.18))
			else:
				draw_rect(rect, c)
			if (x + y) % 5 == 0:
				draw_rect(rect, Color(0, 0, 0, 0.08), false, 1.0)

func _load_tile_texture() -> Texture2D:
	var path := "res://assets/sprites/tiles/village_ground_2p5d.png"
	if mode == "guild":
		path = "res://assets/sprites/tiles/guild_ground_2p5d.png"
	elif mode == "wasteland":
		path = "res://assets/sprites/tiles/wasteland_ground_2p5d.png"
	return ASSET_LOADER.load_png(path)
