extends Node

const PROJECTILE_POOL_SCRIPT := preload("res://scripts/systems/ProjectilePool.gd")

func _ready() -> void:
	DataRegistry.load_all()
	GameState.reset_new_run(false)
	GameState.current_scene_id = "performance"
	GameState.current_route_id = "stress_test"
	await _run_stress_sample()
	get_tree().quit(0)

func _run_stress_sample() -> void:
	var pool := _create_projectile_pool()
	_spawn_lightweight_enemy_load(30)
	for i in range(200):
		var angle := float(i) / 200.0 * TAU
		var dir := Vector2.RIGHT.rotated(angle)
		pool.fire_projectile(Vector2(1600, 1200) + dir * 70.0, dir, 1, "stress_target")
	var start_usec := Time.get_ticks_usec()
	var frame_count := 90
	for _i in range(frame_count):
		await get_tree().physics_frame
	var elapsed := float(Time.get_ticks_usec() - start_usec) / 1000000.0
	var avg_ms := elapsed * 1000.0 / float(frame_count)
	var enemies := get_tree().get_nodes_in_group("enemy").size()
	var projectiles := pool.total_projectiles()
	var report := {
		"route": "projectile_pool_stress",
		"frames": frame_count,
		"elapsed_seconds": elapsed,
		"average_frame_ms": avg_ms,
		"estimated_fps": 1000.0 / max(0.001, avg_ms),
		"enemy_nodes": enemies,
		"active_projectiles": pool.active_count,
		"pooled_projectiles": projectiles,
	}
	var json := JSON.stringify(report, "\t")
	var path := ProjectSettings.globalize_path("res://docs/performance_report.json")
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file != null:
		file.store_string(json + "\n")
	print("[PERF] " + json)

func _create_projectile_pool() -> ProjectilePool:
	var pool: ProjectilePool = PROJECTILE_POOL_SCRIPT.new()
	pool.max_projectiles = 200
	add_child(pool)
	return pool

func _spawn_lightweight_enemy_load(count: int) -> void:
	for i in range(count):
		var body := CharacterBody2D.new()
		body.add_to_group("enemy")
		body.global_position = Vector2(700 + (i % 10) * 90, 650 + int(i / 10) * 100)
		var collision := CollisionShape2D.new()
		var shape := CircleShape2D.new()
		shape.radius = 18.0
		collision.shape = shape
		body.add_child(collision)
		add_child(body)
