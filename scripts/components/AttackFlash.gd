extends Node2D
class_name AttackFlash

var effect_id := "slash_rust"
var direction := Vector2.RIGHT
var color_primary := Color8(255, 178, 58)
var color_secondary := Color8(54, 230, 238)
var lifetime := 0.18
var age := 0.0

func setup(new_effect_id: String, new_direction: Vector2, strength := 1.0) -> void:
	effect_id = new_effect_id
	direction = new_direction.normalized()
	if direction.length() < 0.1:
		direction = Vector2.RIGHT
	lifetime = 0.22 if effect_id.begins_with("slash") or effect_id.begins_with("slam") else 0.16
	if effect_id.contains("acid"):
		color_primary = Color8(110, 240, 82)
		color_secondary = Color8(208, 255, 125)
	elif effect_id.contains("coil") or effect_id.contains("spark"):
		color_primary = Color8(54, 229, 244)
		color_secondary = Color8(255, 187, 60)
	elif effect_id.contains("pipe"):
		color_primary = Color8(255, 188, 72)
		color_secondary = Color8(91, 226, 238)
	scale = Vector2.ONE * clampf(strength, 0.7, 1.55)
	set_process(true)
	queue_redraw()

func _process(delta: float) -> void:
	age += delta
	if age >= lifetime:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	var t := clampf(age / max(lifetime, 0.01), 0.0, 1.0)
	var alpha := 1.0 - t
	if effect_id.begins_with("muzzle"):
		_draw_muzzle(alpha)
	elif effect_id.begins_with("scan") or effect_id.begins_with("magnet"):
		_draw_tool_pulse(t, alpha)
	elif effect_id.begins_with("acid"):
		_draw_muzzle(alpha)
		_draw_tool_pulse(t, alpha * 0.55)
	else:
		_draw_slash(t, alpha)

func _draw_slash(t: float, alpha: float) -> void:
	var center := direction * 26.0 + Vector2(0, -8)
	var normal := direction.rotated(PI * 0.5)
	var radius := lerpf(34.0, 58.0, t)
	var points: PackedVector2Array = []
	for i in range(-9, 10):
		var curve := float(i) / 9.0
		points.append(center + normal * curve * radius + direction * (20.0 - abs(curve) * 16.0))
	if points.size() >= 2:
		draw_polyline(points, Color(color_primary.r, color_primary.g, color_primary.b, alpha), 7.0, true)
		draw_polyline(points, Color(color_secondary.r, color_secondary.g, color_secondary.b, alpha * 0.74), 3.0, true)
	for i in range(4):
		var spark := center + normal * randf_range(-radius * 0.7, radius * 0.7) + direction * randf_range(8, 38)
		draw_circle(spark, randf_range(1.4, 3.0), Color(1.0, 0.76, 0.24, alpha * 0.55))

func _draw_muzzle(alpha: float) -> void:
	var start := direction * 22.0 + Vector2(0, -8)
	var end := direction * 58.0 + Vector2(0, -8)
	draw_line(start, end, Color(color_secondary.r, color_secondary.g, color_secondary.b, alpha * 0.85), 4.0)
	draw_circle(end, 9.0, Color(color_primary.r, color_primary.g, color_primary.b, alpha))
	draw_circle(end + direction * 13.0, 4.0, Color(1.0, 0.95, 0.62, alpha * 0.9))

func _draw_tool_pulse(t: float, alpha: float) -> void:
	var radius := lerpf(18.0, 54.0, t)
	draw_arc(Vector2(0, -10), radius, 0.0, TAU, 64, Color(color_secondary.r, color_secondary.g, color_secondary.b, alpha), 3.0)
	draw_circle(direction * 32.0 + Vector2(0, -8), 5.0, Color(color_primary.r, color_primary.g, color_primary.b, alpha))
