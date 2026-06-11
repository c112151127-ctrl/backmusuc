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
	var image := get_viewport().get_texture().get_image()
	var path := ProjectSettings.globalize_path("res://docs/visual_review_%s.png" % scene_id)
	var error := image.save_png(path)
	if error == OK:
		print("[VISUAL] Saved " + path)
	else:
		push_error("[VISUAL] Failed to save " + path + " error=" + str(error))
