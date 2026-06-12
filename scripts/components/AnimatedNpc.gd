extends Node2D
class_name AnimatedNpc

var phase := 0.0
var talk_boost := 0.0

func play_talk() -> void:
	talk_boost = 0.5

func _process(delta: float) -> void:
	phase += delta * (5.0 if talk_boost > 0.0 else 2.2)
	talk_boost = max(0.0, talk_boost - delta)
	position.y = sin(phase) * (2.0 if talk_boost > 0.0 else 1.0)
	rotation = sin(phase * 0.5) * (0.04 if talk_boost > 0.0 else 0.018)
