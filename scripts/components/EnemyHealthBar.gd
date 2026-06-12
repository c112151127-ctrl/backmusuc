extends Node2D
class_name EnemyHealthBar

var current := 1
var maximum := 1
var visible_timer := 0.0
var bar_width := 54.0
var bar_height := 6.0

func setup(width := 54.0) -> void:
	bar_width = width
	queue_redraw()

func show_value(new_current: int, new_maximum: int) -> void:
	current = max(0, new_current)
	maximum = max(1, new_maximum)
	visible_timer = 1.8
	visible = true
	queue_redraw()

func _process(delta: float) -> void:
	if visible_timer > 0.0:
		visible_timer -= delta
		if visible_timer <= 0.0:
			visible = false

func _draw() -> void:
	var pct: float = clampf(float(current) / float(maximum), 0.0, 1.0)
	var rect: Rect2 = Rect2(Vector2(-bar_width * 0.5, 0), Vector2(bar_width, bar_height))
	draw_rect(rect.grow(1.0), Color(0, 0, 0, 0.72), true)
	draw_rect(rect, Color(0.16, 0.05, 0.04, 0.92), true)
	draw_rect(Rect2(rect.position, Vector2(bar_width * pct, bar_height)), Color(0.78, 0.14, 0.10, 0.95), true)
