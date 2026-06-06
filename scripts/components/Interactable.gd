extends Area2D
class_name Interactable

signal interacted(interaction_id: String)

@export var interaction_id := ""
@export var prompt := "互動"
@export var radius := 42.0

var _player_near := false
var _label: Label

func _ready() -> void:
	add_to_group("interactable")
	monitoring = true
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius
	shape.shape = circle
	add_child(shape)
	_label = Label.new()
	_label.text = "E: " + prompt
	_label.position = Vector2(-44, -54)
	_label.visible = false
	_label.add_theme_font_size_override("font_size", 14)
	add_child(_label)

func _process(_delta: float) -> void:
	if _player_near and Input.is_action_just_pressed("interact"):
		interacted.emit(interaction_id)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_player_near = true
		_label.visible = true

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		_player_near = false
		_label.visible = false
