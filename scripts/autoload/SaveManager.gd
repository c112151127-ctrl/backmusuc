extends Node

const SAVE_PATH := "user://save_game.json"

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func save_game(show_notice := true) -> bool:
	var data := GameState.get_save_data()
	var payload := JSON.stringify(data)
	var wrapped := {
		"checksum": payload.sha256_text(),
		"payload": Marshalls.utf8_to_base64(payload)
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		if show_notice:
			GameState.notify("存檔失敗：無法寫入本機檔案。")
		return false
	file.store_string(JSON.stringify(wrapped, "\t"))
	if show_notice:
		GameState.notify("進度已存檔。")
	return true

func load_game(change_scene := true, show_notice := true) -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		if show_notice:
			GameState.notify("目前沒有可讀取的存檔。")
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var wrapped = JSON.parse_string(file.get_as_text())
	if typeof(wrapped) != TYPE_DICTIONARY:
		if show_notice:
			GameState.notify("讀檔失敗：存檔格式錯誤。")
		return false
	var payload_text := Marshalls.base64_to_utf8(String(wrapped.get("payload", "")))
	if payload_text.sha256_text() != String(wrapped.get("checksum", "")):
		if show_notice:
			GameState.notify("讀檔失敗：checksum 不一致。")
		return false
	var data = JSON.parse_string(payload_text)
	if typeof(data) != TYPE_DICTIONARY or not GameState.load_save_data(data):
		if show_notice:
			GameState.notify("讀檔失敗：資料無法套用。")
		return false
	if show_notice:
		GameState.notify("進度已讀取。")
	if change_scene:
		SceneRouter.change_to(GameState.current_scene_id, GameState.active_spawn_point)
	return true

func load_or_new() -> bool:
	if has_save():
		return load_game(true, true)
	GameState.reset_new_run(true)
	SceneRouter.change_to("village", "default")
	return true
