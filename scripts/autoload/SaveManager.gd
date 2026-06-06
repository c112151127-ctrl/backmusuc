extends Node

const SAVE_PATH := "user://save_game.json"

func save_game() -> bool:
	var data := GameState.get_save_data()
	var payload := JSON.stringify(data)
	var wrapped := {
		"checksum": payload.sha256_text(),
		"payload": Marshalls.utf8_to_base64(payload)
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		GameState.notify("存檔失敗")
		return false
	file.store_string(JSON.stringify(wrapped, "\t"))
	GameState.notify("已存檔")
	return true

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		GameState.notify("找不到存檔")
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var wrapped = JSON.parse_string(file.get_as_text())
	if typeof(wrapped) != TYPE_DICTIONARY:
		GameState.notify("存檔格式錯誤")
		return false
	var payload_text := Marshalls.base64_to_utf8(String(wrapped.get("payload", "")))
	if payload_text.sha256_text() != String(wrapped.get("checksum", "")):
		GameState.notify("存檔驗證失敗")
		return false
	var data = JSON.parse_string(payload_text)
	if typeof(data) != TYPE_DICTIONARY or not GameState.load_save_data(data):
		GameState.notify("讀檔失敗")
		return false
	GameState.notify("讀檔完成")
	SceneRouter.change_to(GameState.current_scene_id, GameState.active_spawn_point)
	return true
