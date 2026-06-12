extends Label
class_name DamagePopup

func setup(amount: int, critical := false) -> void:
	text = "-%d" % amount
	add_theme_font_size_override("font_size", 18 if critical else 15)
	modulate = Color(1.0, 0.28, 0.18, 1.0) if critical else Color(0.95, 0.88, 0.62, 1.0)
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func _ready() -> void:
	z_index = 80
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position", position + Vector2(randf_range(-10, 10), -42), 0.55).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "modulate:a", 0.0, 0.55)
	tween.finished.connect(queue_free)
