extends Node2D

var title_layer: CanvasLayer

func _ready() -> void:
	if not OS.has_feature("headless"):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	print("Waste Recycler Main scene loaded")
	DataRegistry.load_all()
	await get_tree().process_frame
	if OS.has_feature("headless"):
		SceneRouter.change_to("village", "default")
	else:
		_build_title_screen()

func _build_title_screen() -> void:
	AudioManager.play_music("intro")
	title_layer = CanvasLayer.new()
	add_child(title_layer)

	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	title_layer.add_child(root)

	var backdrop := ColorRect.new()
	backdrop.color = Color(0.018, 0.016, 0.014, 0.98)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(backdrop)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(720, 420)
	panel.position = Vector2(300, 150)
	panel.add_theme_stylebox_override("panel", _panel_style())
	root.add_child(panel)

	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 14)
	panel.add_child(stack)

	var title := Label.new()
	title.text = "廢土回收商"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 42)
	stack.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "人類文明崩壞後，資源被污染區吞沒。R-17 在維修艙甦醒，必須回收廢鐵、核心與晶體，替村莊換取下一天的能源。"
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 18)
	stack.add_child(subtitle)

	var continue_button := Button.new()
	continue_button.text = "繼續遊戲"
	continue_button.disabled = not SaveManager.has_save()
	continue_button.pressed.connect(_continue_game)
	stack.add_child(continue_button)

	var new_button := Button.new()
	new_button.text = "新遊戲"
	new_button.pressed.connect(_new_game)
	stack.add_child(new_button)

	var help := Label.new()
	help.text = "WASD 移動｜滑鼠左鍵依裝備攻擊｜E 互動｜Tab 人物裝備｜M 地圖｜Esc 暫停"
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	help.add_theme_font_size_override("font_size", 14)
	stack.add_child(help)

func _continue_game() -> void:
	if title_layer != null:
		title_layer.queue_free()
	SaveManager.load_game(true, true)

func _new_game() -> void:
	GameState.reset_new_run(true)
	_show_intro()

func _show_intro() -> void:
	for child in title_layer.get_children():
		child.queue_free()
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	title_layer.add_child(root)

	var backdrop := ColorRect.new()
	backdrop.color = Color(0.012, 0.012, 0.014, 0.98)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(backdrop)

	var panel := PanelContainer.new()
	panel.position = Vector2(220, 140)
	panel.custom_minimum_size = Vector2(900, 470)
	panel.add_theme_stylebox_override("panel", _panel_style())
	root.add_child(panel)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 16)
	panel.add_child(stack)

	var title := Label.new()
	title.text = "開場：R-17 甦醒"
	title.add_theme_font_size_override("font_size", 30)
	stack.add_child(title)

	var body := Label.new()
	body.text = "最後一座村莊的能源只剩七天。\n\n污染雨摧毀了農地，舊工廠仍在夜裡噴出毒霧。人類倖存者把最後一台回收機器人 R-17 推進維修艙，重新接上記憶核心。\n\n你的任務很簡單：出村、戰鬥、回收、升級，然後把資源帶回來。廢土不會等你準備好。"
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", 20)
	stack.add_child(body)

	var start_button := Button.new()
	start_button.text = "開始行動"
	start_button.pressed.connect(_start_new_run_after_intro)
	stack.add_child(start_button)

	var skip := Label.new()
	skip.text = "開場只會在新遊戲第一次出現；存檔會記錄已看過。"
	skip.add_theme_font_size_override("font_size", 13)
	stack.add_child(skip)

func _start_new_run_after_intro() -> void:
	GameState.mark_intro_seen()
	SaveManager.save_game(false)
	if title_layer != null:
		title_layer.queue_free()
	SceneRouter.change_to("village", "default")

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.027, 0.026, 0.92)
	style.border_color = Color(0.80, 0.58, 0.26, 0.96)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	return style
