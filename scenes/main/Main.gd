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
	title_layer = CanvasLayer.new()
	add_child(title_layer)

	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	title_layer.add_child(root)

	var backdrop := ColorRect.new()
	backdrop.color = Color(0.02, 0.018, 0.015, 0.96)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(backdrop)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(660, 380)
	panel.position = Vector2(330, 170)
	root.add_child(panel)

	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 14)
	panel.add_child(stack)

	var title := Label.new()
	title.text = "廢土回收商"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 40)
	stack.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "R-17 是村莊重啟的回收機器人。探索四條廢土路線、擊倒污染體、回收資源，讓據點重新運轉。"
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
	help.text = "WASD 移動｜滑鼠左鍵依裝備行動｜E 互動｜Tab 人物裝備｜M 地圖"
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
	backdrop.color = Color(0.015, 0.014, 0.012, 0.97)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(backdrop)

	var panel := PanelContainer.new()
	panel.position = Vector2(220, 150)
	panel.custom_minimum_size = Vector2(860, 430)
	root.add_child(panel)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 16)
	panel.add_child(stack)

	var title := Label.new()
	title.text = "開場：R-17 甦醒"
	title.add_theme_font_size_override("font_size", 30)
	stack.add_child(title)

	var body := Label.new()
	body.text = "一場核心污染讓舊工廠、排水區與公路全部失控。村莊只剩下最後一台可修復的回收機器人：R-17。\n\n你要從維修艙甦醒，接下公會委託，從四個出口進入廢土，回收廢鐵、彈藥與晶核。每次回村整備，都會讓下一趟探索更深入。"
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", 20)
	stack.add_child(body)

	var start_button := Button.new()
	start_button.text = "開始任務"
	start_button.pressed.connect(_start_new_run_after_intro)
	stack.add_child(start_button)

func _start_new_run_after_intro() -> void:
	GameState.mark_intro_seen()
	SaveManager.save_game(false)
	if title_layer != null:
		title_layer.queue_free()
	SceneRouter.change_to("village", "default")
