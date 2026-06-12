extends Node

const VILLAGE_SCENE := preload("res://scenes/levels/village/Village.tscn")
const GUILD_SCENE := preload("res://scenes/levels/guild/Guild.tscn")
const WASTELAND_SCENE := preload("res://scenes/levels/wasteland/Wasteland.tscn")

const REVIEW_TARGETS := {
	"village": VILLAGE_SCENE,
	"guild": GUILD_SCENE,
	"wasteland": WASTELAND_SCENE
}

var _active_scene: Node

func _ready() -> void:
	get_window().size = Vector2i(1280, 720)
	DataRegistry.load_all()
	print("[VISUAL] Visual review screenshots started")
	for scene_id in REVIEW_TARGETS.keys():
		await _capture_scene(String(scene_id), REVIEW_TARGETS[scene_id])
	for route_id in ["scrap_highway", "toxic_marsh", "crystal_scar", "old_factory"]:
		await _capture_wasteland_route(route_id)
	print("[VISUAL] Visual review screenshots complete")
	get_tree().quit(0)

func _capture_scene(scene_id: String, packed_scene: PackedScene) -> void:
	if _active_scene != null:
		_active_scene.queue_free()
		await get_tree().process_frame
	GameState.reset_new_run(false)
	GameState.current_scene_id = scene_id
	GameState.seed = 424242
	_active_scene = packed_scene.instantiate()
	add_child(_active_scene)
	for _i in range(8):
		await get_tree().process_frame
	_save_viewport_image("visual_review_%s" % scene_id)
	if scene_id == "village":
		await _capture_inventory_panel()
	if scene_id == "wasteland":
		await _capture_wasteland_road_area()
		await _capture_wasteland_boss_area()

func _capture_inventory_panel() -> void:
	var panels := get_tree().get_nodes_in_group("equipment_panel")
	if panels.is_empty():
		return
	var panel := panels[0] as Control
	panel.visible = true
	for _i in range(8):
		await get_tree().process_frame
	_save_viewport_image("visual_review_inventory_panel")

func _capture_wasteland_road_area() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return
	var player := players[0] as Node2D
	player.global_position = Vector2(2880, 3180)
	GameState.player_position = player.global_position
	for _i in range(12):
		await get_tree().process_frame
	_save_viewport_image("visual_review_wasteland_road")

func _capture_wasteland_boss_area() -> void:
	var bosses := get_tree().get_nodes_in_group("boss")
	var players := get_tree().get_nodes_in_group("player")
	if bosses.is_empty() or players.is_empty():
		return
	var boss := bosses[0] as Node2D
	var player := players[0] as Node2D
	player.global_position = boss.global_position + Vector2(180, 180)
	GameState.player_position = player.global_position
	for _i in range(12):
		await get_tree().process_frame
	_save_viewport_image("visual_review_wasteland_boss")

func _capture_wasteland_route(route_id: String) -> void:
	if _active_scene != null:
		_active_scene.queue_free()
		await get_tree().process_frame
	GameState.reset_new_run(false)
	GameState.current_scene_id = "wasteland"
	GameState.set_current_route(route_id)
	GameState.seed = 424242
	_active_scene = WASTELAND_SCENE.instantiate()
	add_child(_active_scene)
	for _i in range(10):
		await get_tree().process_frame
	_save_viewport_image("visual_review_route_%s" % route_id)

func _save_viewport_image(name: String) -> void:
	if DisplayServer.get_name().to_lower().contains("headless"):
		print("[VISUAL] Skipped " + name + " because headless mode has no rendered viewport image")
		return
	var viewport_texture: Texture2D = get_viewport().get_texture()
	if viewport_texture == null:
		print("[VISUAL] Skipped " + name + " because the current renderer has no viewport texture")
		return
	var image: Image = viewport_texture.get_image()
	if image == null:
		print("[VISUAL] Skipped " + name + " because the viewport image is unavailable")
		return
	_save_image(image, name)

func _save_image(image: Image, name: String) -> void:
	var path := ProjectSettings.globalize_path("res://docs/%s.png" % name)
	var error := image.save_png(path)
	if error == OK:
		print("[VISUAL] Saved " + path)
	else:
		push_error("[VISUAL] Failed to save " + path + " error=" + str(error))
