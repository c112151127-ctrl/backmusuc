extends Control
class_name MiniMapView

func _ready() -> void:
	custom_minimum_size = Vector2(190, 106)

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(rect, Color(0.05, 0.06, 0.055, 0.94), true)
	draw_rect(rect, Color(0.32, 0.36, 0.34, 0.9), false, 1.0)

	var village := Vector2(size.x * 0.22, size.y * 0.55)
	var guild := Vector2(size.x * 0.5, size.y * 0.32)
	var wasteland := Vector2(size.x * 0.78, size.y * 0.64)
	draw_line(village, guild, Color(0.62, 0.57, 0.43, 0.85), 3.0)
	draw_line(guild, wasteland, Color(0.62, 0.57, 0.43, 0.85), 3.0)

	_draw_node(village, "村莊", "village", Color(0.35, 0.74, 0.42))
	_draw_node(guild, "公會", "guild", Color(0.55, 0.43, 0.82))
	_draw_node(wasteland, "廢土", "wasteland", Color(0.77, 0.62, 0.28))

	for i in range(7):
		var x := 18.0 + float((i * 31) % int(max(1.0, size.x - 28.0)))
		var y := 18.0 + float((i * 47) % int(max(1.0, size.y - 28.0)))
		draw_circle(Vector2(x, y), 1.5, Color(0.48, 0.9, 0.55, 0.55))

func _draw_node(pos: Vector2, label: String, scene_id: String, color: Color) -> void:
	var active := GameState.current_scene_id == scene_id
	draw_circle(pos, 8.0 if active else 6.0, color if active else color.darkened(0.45))
	draw_circle(pos, 3.0, Color(0.95, 0.95, 0.78, 0.9))
	draw_string(ThemeDB.fallback_font, pos + Vector2(-6, -12), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
