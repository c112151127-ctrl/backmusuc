extends Node2D
class_name WorldBackdrop

var mode := "village"
var map_size := Vector2i(60, 40)
var tile_size := 32
var world_seed := 9527

func setup(new_mode: String, size_tiles: Vector2i, new_seed: int) -> void:
	mode = new_mode
	map_size = size_tiles
	world_seed = new_seed
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
			draw_rect(rect, c)
			if (x + y) % 5 == 0:
				draw_rect(rect, Color(0, 0, 0, 0.08), false, 1.0)
