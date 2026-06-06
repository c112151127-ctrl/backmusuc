extends Node

const SCENES := {
	"main": "res://scenes/main/Main.tscn",
	"village": "res://scenes/levels/village/Village.tscn",
	"wasteland": "res://scenes/levels/wasteland/Wasteland.tscn",
	"guild": "res://scenes/levels/guild/Guild.tscn"
}

func change_to(scene_id: String, spawn_point := "default") -> void:
	if not SCENES.has(scene_id):
		GameState.notify("未知場景: %s" % scene_id)
		return
	GameState.set_scene(scene_id, spawn_point)
	get_tree().change_scene_to_file(SCENES[scene_id])
