extends Node
class_name HealthComponent

signal died
signal changed(current: int, maximum: int)

@export var maximum := 100
var current := 100

func _ready() -> void:
	current = maximum

func damage(amount: int) -> void:
	current = max(0, current - amount)
	changed.emit(current, maximum)
	if current == 0:
		died.emit()

func heal(amount: int) -> void:
	current = min(maximum, current + amount)
	changed.emit(current, maximum)
