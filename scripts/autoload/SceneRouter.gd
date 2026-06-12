extends Node

const SCENES := {
	"main": "res://scenes/main/Main.tscn",
	"village": "res://scenes/levels/village/Village.tscn",
	"wasteland": "res://scenes/levels/wasteland/Wasteland.tscn",
	"guild": "res://scenes/levels/guild/Guild.tscn"
}

var _pending_scene_id := ""

func change_to(scene_id: String, spawn_point := "default") -> void:
	if not SCENES.has(scene_id):
		GameState.notify("未知場景：%s" % scene_id)
		return
	_pending_scene_id = scene_id
	GameState.set_scene(scene_id, spawn_point)
	if scene_id != "main":
		SaveManager.save_game(false)
	call_deferred("_change_scene_deferred")

func _change_scene_deferred() -> void:
	if _pending_scene_id.is_empty():
		return
	var scene_id := _pending_scene_id
	_pending_scene_id = ""
	get_tree().change_scene_to_file(SCENES[scene_id])
