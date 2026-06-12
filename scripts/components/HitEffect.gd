extends Node2D
class_name HitEffect

var effect_color := Color(0.35, 0.95, 0.25, 0.85)
var particle_count := 10
var spread := 22.0

func setup(kind := "pollution") -> void:
	match kind:
		"spark":
			effect_color = Color(1.0, 0.72, 0.22, 0.9)
		"core":
			effect_color = Color(0.95, 0.12, 0.16, 0.9)
		_:
			effect_color = Color(0.35, 0.95, 0.25, 0.85)
	queue_redraw()

func _ready() -> void:
	z_index = 75
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.65, 1.65), 0.24)
	tween.tween_property(self, "modulate:a", 0.0, 0.24)
	tween.finished.connect(queue_free)

func _draw() -> void:
	for i in range(particle_count):
		var angle := float(i) / float(particle_count) * TAU
		var length := spread * (0.45 + float((i * 37) % 100) / 180.0)
		var end := Vector2(cos(angle), sin(angle)) * length
		draw_line(Vector2.ZERO, end, effect_color, 2.0)
		draw_circle(end, 2.0, effect_color.lightened(0.2))
