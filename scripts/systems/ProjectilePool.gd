extends Node
class_name ProjectilePool

const PROJECTILE_SCRIPT := preload("res://scripts/components/Projectile.gd")

@export var max_projectiles := 200

var active_count := 0
var pooled_projectiles: Array[Area2D] = []

func _ready() -> void:
	add_to_group("projectile_pool")

func fire_projectile(start: Vector2, dir: Vector2, damage: int) -> bool:
	if active_count >= max_projectiles:
		GameState.notify("投射物已達上限")
		return false
	var projectile := _get_projectile()
	if projectile == null:
		return false
	active_count += 1
	projectile.setup_pooled(start, dir, damage, self)
	return true

func release(projectile: Area2D) -> void:
	if projectile == null:
		return
	active_count = max(0, active_count - 1)
	projectile.deactivate()

func total_projectiles() -> int:
	return pooled_projectiles.size()

func _get_projectile() -> Area2D:
	for projectile in pooled_projectiles:
		if projectile != null and not projectile.is_active:
			return projectile
	if pooled_projectiles.size() >= max_projectiles:
		return null
	var projectile: Area2D = PROJECTILE_SCRIPT.new()
	pooled_projectiles.append(projectile)
	add_child(projectile)
	return projectile
