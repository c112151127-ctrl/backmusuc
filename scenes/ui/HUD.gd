extends CanvasLayer

const MAP_VIEW := preload("res://scripts/ui/WorldMapView.gd")
const PIXEL := preload("res://scripts/utils/PixelArtFactory.gd")
const ASSET_LOADER := preload("res://scripts/utils/RuntimeAssetLoader.gd")

var root: Control
var status_panel: PanelContainer
var stats_label: Label
var hp_bar: ProgressBar
var ep_bar: ProgressBar
var quest_panel: PanelContainer
var quest_label: Label
var quick_bar_panel: PanelContainer
var quick_bar: HBoxContainer
var inventory_panel: PanelContainer
var inventory_list: VBoxContainer
var notice_label: Label
var notice_timer: Timer
var minimap_panel: PanelContainer
var minimap_title: Label
var map_view
var tutorial_panel: PanelContainer
var controls_hint: Label
var dialogue_panel: PanelContainer
var dialogue_portrait: TextureRect
var dialogue_speaker: Label
var dialogue_role: Label
var dialogue_body: Label
var dialogue_timer: Timer
var pause_panel: PanelContainer
var map_open := true
var map_fullscreen := false

func _ready() -> void:
	_build_hud()
	GameState.stats_changed.connect(_refresh)
	GameState.inventory_changed.connect(_refresh_inventory)
	GameState.equipment_changed.connect(_refresh_inventory)
	GameState.equipment_changed.connect(_refresh_hotbar)
	GameState.notification_requested.connect(_show_notice)
	GameState.dialogue_requested.connect(_show_dialogue)
	GameState.dialogue_closed.connect(_hide_dialogue)
	_refresh()
	_refresh_inventory()
	_refresh_overlay_visibility()
	_layout()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("open_inventory"):
		_set_inventory_visible(not inventory_panel.visible)
	if Input.is_action_just_pressed("toggle_minimap"):
		_toggle_map()
	if Input.is_action_just_pressed("toggle_help"):
		tutorial_panel.visible = not tutorial_panel.visible
		_refresh_overlay_visibility()
	_layout()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		if inventory_panel.visible:
			_set_inventory_visible(false)
		elif tutorial_panel.visible:
			tutorial_panel.visible = false
			_refresh_overlay_visibility()
		elif map_fullscreen:
			map_fullscreen = false
			_refresh_overlay_visibility()
		elif dialogue_panel.visible:
			_hide_dialogue()
		elif pause_panel.visible:
			_set_pause_visible(false)
		else:
			_set_pause_visible(true)

func _layout() -> void:
	var size := get_viewport().get_visible_rect().size
	if status_panel != null:
		status_panel.position = Vector2(size.x - 442.0, 18.0)
		status_panel.custom_minimum_size = Vector2(420, 96)
		status_panel.size = Vector2(420, 96)
	if quest_panel != null:
		var quest_size := Vector2(min(620.0, max(260.0, size.x - 500.0)), 78)
		quest_panel.position = Vector2(18, 18)
		quest_panel.custom_minimum_size = quest_size
		quest_panel.size = quest_size
	if quick_bar_panel != null:
		quick_bar_panel.position = Vector2(max(16, (size.x - 520.0) * 0.5), size.y - 82.0)
		quick_bar_panel.size = Vector2(520, 64)
	if controls_hint != null:
		controls_hint.position = Vector2(max(16, (size.x - controls_hint.size.x) * 0.5), size.y - 116.0)
	if dialogue_panel != null:
		dialogue_panel.position = Vector2(max(24, (size.x - 920.0) * 0.5), size.y - 238.0)
		dialogue_panel.size = Vector2(min(920.0, size.x - 48.0), 178)
	if minimap_panel != null:
		if map_fullscreen:
			minimap_panel.position = Vector2(48, 48)
			minimap_panel.custom_minimum_size = size - Vector2(96, 96)
			minimap_panel.size = size - Vector2(96, 96)
		else:
			minimap_panel.position = Vector2(size.x - 330.0, 126.0)
			minimap_panel.custom_minimum_size = Vector2(308, 210)
			minimap_panel.size = Vector2(308, 210)
	if inventory_panel != null:
		var inventory_size := Vector2(min(980.0, size.x - 44.0), min(660.0, size.y - 118.0))
		inventory_panel.position = Vector2(max(22, (size.x - 980.0) * 0.5), 76)
		inventory_panel.custom_minimum_size = inventory_size
		inventory_panel.size = inventory_size
	if tutorial_panel != null:
		var tutorial_size := Vector2(min(500.0, size.x - 44.0), 246)
		tutorial_panel.position = Vector2(22, max(118.0, size.y - 392.0))
		tutorial_panel.custom_minimum_size = tutorial_size
		tutorial_panel.size = tutorial_size
	if pause_panel != null:
		pause_panel.position = Vector2((size.x - 340.0) * 0.5, (size.y - 330.0) * 0.5)
		pause_panel.custom_minimum_size = Vector2(340, 330)
		pause_panel.size = Vector2(340, 330)

func _build_hud() -> void:
	root = Control.new()
	root.name = "HudRoot"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	_build_status_panel()
	_build_quest_panel()
	_build_inventory_panel()
	_add_quick_bar()
	_add_minimap()
	_add_tutorial()
	_add_controls_hint()
	_add_dialogue_box()
	_add_pause_menu()

	notice_label = Label.new()
	notice_label.position = Vector2(22, 106)
	notice_label.add_theme_font_size_override("font_size", 16)
	notice_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.68))
	notice_label.visible = false
	root.add_child(notice_label)
	notice_timer = Timer.new()
	notice_timer.one_shot = true
	notice_timer.timeout.connect(func() -> void: notice_label.visible = false)
	add_child(notice_timer)

func _build_status_panel() -> void:
	status_panel = PanelContainer.new()
	status_panel.name = "StatusPanel"
	status_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.04, 0.045, 0.045, 0.84), Color(0.74, 0.46, 0.28, 0.95), 2))
	root.add_child(status_panel)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 5)
	status_panel.add_child(stack)
	stats_label = Label.new()
	stats_label.add_theme_font_size_override("font_size", 15)
	stats_label.add_theme_color_override("font_color", Color(0.95, 0.92, 0.84))
	stack.add_child(stats_label)
	hp_bar = _make_bar(Color(0.86, 0.06, 0.04), Color(0.40, 0.0, 0.0))
	stack.add_child(_bar_row("HP", hp_bar))
	ep_bar = _make_bar(Color(0.06, 0.78, 0.92), Color(0.0, 0.20, 0.30))
	stack.add_child(_bar_row("EP", ep_bar))

func _build_quest_panel() -> void:
	quest_panel = PanelContainer.new()
	quest_panel.name = "QuestPanel"
	quest_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.03, 0.035, 0.035, 0.70), Color(0.30, 0.32, 0.30, 0.85), 1))
	root.add_child(quest_panel)
	quest_label = Label.new()
	quest_label.add_theme_font_size_override("font_size", 14)
	quest_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	quest_label.add_theme_color_override("font_color", Color(0.92, 0.90, 0.82))
	quest_panel.add_child(quest_label)

func _build_inventory_panel() -> void:
	inventory_panel = PanelContainer.new()
	inventory_panel.name = "InventoryPanel"
	inventory_panel.add_to_group("equipment_panel")
	inventory_panel.z_index = 80
	inventory_panel.visible = false
	inventory_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.025, 0.027, 0.026, 0.90), Color(0.82, 0.58, 0.24, 0.96), 2))
	root.add_child(inventory_panel)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(920, 600)
	inventory_panel.add_child(scroll)
	inventory_list = VBoxContainer.new()
	inventory_list.add_theme_constant_override("separation", 10)
	scroll.add_child(inventory_list)

func _add_quick_bar() -> void:
	quick_bar_panel = PanelContainer.new()
	quick_bar_panel.name = "QuickBarPanel"
	quick_bar_panel.custom_minimum_size = Vector2(520, 64)
	quick_bar_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.025, 0.025, 0.025, 0.78), Color(0.35, 0.32, 0.28, 0.85), 1))
	root.add_child(quick_bar_panel)
	quick_bar = HBoxContainer.new()
	quick_bar.name = "QuickBar"
	quick_bar.add_theme_constant_override("separation", 6)
	quick_bar_panel.add_child(quick_bar)

func _add_minimap() -> void:
	minimap_panel = PanelContainer.new()
	minimap_panel.name = "MiniMapPanel"
	minimap_panel.add_to_group("minimap_panel")
	minimap_panel.z_index = 45
	minimap_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.025, 0.030, 0.030, 0.90), Color(0.34, 0.42, 0.38, 0.92), 1))
	root.add_child(minimap_panel)
	var map_stack := VBoxContainer.new()
	map_stack.add_theme_constant_override("separation", 4)
	minimap_panel.add_child(map_stack)
	minimap_title = Label.new()
	minimap_title.text = "地圖 M"
	minimap_title.add_theme_font_size_override("font_size", 15)
	map_stack.add_child(minimap_title)
	map_view = MAP_VIEW.new()
	map_view.expand_requested.connect(_open_full_map)
	map_stack.add_child(map_view)

func _add_tutorial() -> void:
	tutorial_panel = PanelContainer.new()
	tutorial_panel.name = "TutorialPanel"
	tutorial_panel.add_to_group("tutorial_panel")
	tutorial_panel.custom_minimum_size = Vector2(500, 246)
	tutorial_panel.z_index = 72
	tutorial_panel.visible = false
	tutorial_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.025, 0.028, 0.030, 0.92), Color(0.70, 0.55, 0.30, 0.95), 2))
	root.add_child(tutorial_panel)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 8)
	tutorial_panel.add_child(stack)
	var title := Label.new()
	title.text = "R-17 基礎教學"
	title.add_theme_font_size_override("font_size", 18)
	stack.add_child(title)
	var body := Label.new()
	body.text = "WASD 移動。\n滑鼠左鍵依目前快捷裝備行動：刀會揮砍，槍會射擊，工具會掃描。\n右鍵或 K 連續射擊，空白鍵近戰，Q 切換快捷欄。\nE 與 NPC、建築或出口互動；Tab / I 開啟人物裝備與升級面板。\nM 開啟小地圖，再按一次或點擊小地圖可放大全屏地圖。\nF5 儲存，F9 讀檔，Esc 暫停。"
	body.add_theme_font_size_override("font_size", 13)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(body)

func _add_controls_hint() -> void:
	controls_hint = Label.new()
	controls_hint.text = "Tab 人物裝備｜H 教學｜M 地圖｜E 互動"
	controls_hint.add_theme_font_size_override("font_size", 14)
	controls_hint.add_theme_color_override("font_color", Color(0.95, 0.95, 0.88))
	root.add_child(controls_hint)

func _add_dialogue_box() -> void:
	dialogue_panel = PanelContainer.new()
	dialogue_panel.name = "DialoguePanel"
	dialogue_panel.add_to_group("dialogue_panel")
	dialogue_panel.custom_minimum_size = Vector2(920, 178)
	dialogue_panel.z_index = 90
	dialogue_panel.visible = false
	dialogue_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.018, 0.020, 0.020, 0.92), Color(0.86, 0.64, 0.26, 0.98), 2))
	root.add_child(dialogue_panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	dialogue_panel.add_child(row)
	dialogue_portrait = TextureRect.new()
	dialogue_portrait.custom_minimum_size = Vector2(122, 142)
	dialogue_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	dialogue_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(dialogue_portrait)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 4)
	row.add_child(stack)
	dialogue_speaker = Label.new()
	dialogue_speaker.add_theme_font_size_override("font_size", 19)
	dialogue_speaker.add_theme_color_override("font_color", Color(1.0, 0.86, 0.42))
	stack.add_child(dialogue_speaker)
	dialogue_role = Label.new()
	dialogue_role.add_theme_font_size_override("font_size", 13)
	dialogue_role.add_theme_color_override("font_color", Color(0.72, 0.92, 0.92))
	stack.add_child(dialogue_role)
	dialogue_body = Label.new()
	dialogue_body.add_theme_font_size_override("font_size", 17)
	dialogue_body.custom_minimum_size = Vector2(740, 70)
	dialogue_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(dialogue_body)
	var hint := Label.new()
	hint.text = "E 繼續互動｜Esc 關閉｜離開 NPC 範圍會自動關閉"
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color(0.72, 0.72, 0.68))
	stack.add_child(hint)
	dialogue_timer = Timer.new()
	dialogue_timer.one_shot = true
	dialogue_timer.timeout.connect(_hide_dialogue)
	add_child(dialogue_timer)

func _add_pause_menu() -> void:
	pause_panel = PanelContainer.new()
	pause_panel.name = "PausePanel"
	pause_panel.z_index = 100
	pause_panel.visible = false
	pause_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.015, 0.018, 0.018, 0.94), Color(0.82, 0.58, 0.24, 0.98), 2))
	root.add_child(pause_panel)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 10)
	pause_panel.add_child(stack)
	var title := Label.new()
	title.text = "暫停"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	stack.add_child(title)
	_add_pause_button(stack, "繼續遊戲", func() -> void: _set_pause_visible(false))
	_add_pause_button(stack, "儲存進度", func() -> void: SaveManager.save_game(true))
	_add_pause_button(stack, "讀取存檔", func() -> void: SaveManager.load_game(true, true))
	_add_pause_button(stack, "返回標題", func() -> void: SceneRouter.change_to("main", "default"))
	_add_pause_button(stack, "退出遊戲", func() -> void: get_tree().quit(0))

func _add_pause_button(container: VBoxContainer, text: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(290, 42)
	button.pressed.connect(callback)
	container.add_child(button)

func _toggle_map() -> void:
	if not map_open:
		map_open = true
		map_fullscreen = false
	elif not map_fullscreen:
		map_fullscreen = true
	else:
		map_open = false
		map_fullscreen = false
	_refresh_overlay_visibility()

func _open_full_map() -> void:
	if map_open and not inventory_panel.visible and not tutorial_panel.visible and not pause_panel.visible:
		map_fullscreen = true
		_refresh_overlay_visibility()

func _set_inventory_visible(is_visible: bool) -> void:
	inventory_panel.visible = is_visible
	if is_visible:
		map_fullscreen = false
		tutorial_panel.visible = false
		pause_panel.visible = false
		_refresh_inventory()
	_refresh_overlay_visibility()

func _set_pause_visible(is_visible: bool) -> void:
	pause_panel.visible = is_visible
	if is_visible:
		map_fullscreen = false
		inventory_panel.visible = false
		tutorial_panel.visible = false
		_hide_dialogue()
	_refresh_overlay_visibility()

func _refresh_overlay_visibility() -> void:
	var modal_open := inventory_panel.visible or tutorial_panel.visible or map_fullscreen or dialogue_panel.visible or pause_panel.visible
	quick_bar_panel.visible = not modal_open
	controls_hint.visible = not modal_open
	minimap_panel.visible = map_open and not inventory_panel.visible and not tutorial_panel.visible and not dialogue_panel.visible and not pause_panel.visible
	if map_view != null:
		map_view.set_full_screen(map_fullscreen)
	if minimap_title != null:
		minimap_title.text = "全屏地圖 Esc" if map_fullscreen else "地圖 M"
	_layout()

func _refresh() -> void:
	var route := DataRegistry.get_wasteland_route(GameState.current_route_id)
	var route_name := String(route.get("name", "村莊"))
	var max_hp := GameState.get_max_hp() if GameState.has_method("get_max_hp") else GameState.MAX_HP
	var max_ep := GameState.get_max_ep() if GameState.has_method("get_max_ep") else GameState.MAX_EP
	hp_bar.max_value = max_hp
	hp_bar.value = GameState.hp
	ep_bar.max_value = max_ep
	ep_bar.value = GameState.ep
	stats_label.text = "R-17 Lv.%d  XP %d/%d  彈藥 %d  廢鐵 %d  核心 %d" % [
		GameState.level,
		GameState.xp,
		GameState.xp_to_next_level(),
		GameState.ammo,
		GameState.scrap,
		GameState.cores
	]
	quest_label.text = "場景：%s｜路線：%s\n委託：%s" % [GameState.current_scene_id, route_name, GameState.active_quest_summary()]
	_refresh_hotbar()

func _refresh_hotbar() -> void:
	if quick_bar == null:
		return
	for child in quick_bar.get_children():
		child.queue_free()
	for i in range(GameState.quick_slots.size()):
		var item_id := String(GameState.quick_slots[i])
		var button := Button.new()
		button.name = "QuickSlot%d" % [i + 1]
		button.custom_minimum_size = Vector2(116, 48)
		button.add_to_group("hotbar_slot")
		button.set_meta("quick_slot_index", i)
		button.text = "%s%d" % ["> " if i == GameState.active_quick_slot else "", i + 1]
		button.tooltip_text = "%d：%s" % [i + 1, GameState.item_display_name(item_id)]
		button.icon = _item_icon(item_id)
		button.expand_icon = true
		button.add_theme_stylebox_override("normal", _button_style(i == GameState.active_quick_slot))
		button.pressed.connect(GameState.use_quick_slot.bind(i))
		quick_bar.add_child(button)

func _refresh_inventory() -> void:
	if inventory_list == null:
		return
	for child in inventory_list.get_children():
		child.queue_free()
	var title := Label.new()
	title.text = "人物裝備：R-17 回收機器人"
	title.add_theme_font_size_override("font_size", 24)
	inventory_list.add_child(title)

	var active := Label.new()
	active.text = "目前左鍵：%s（%s）｜升級點：%d" % [GameState.item_display_name(GameState.active_attack_item_id()), _attack_mode_label(GameState.active_attack_mode()), GameState.upgrade_points]
	active.add_theme_font_size_override("font_size", 16)
	inventory_list.add_child(active)

	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 18)
	inventory_list.add_child(body)

	var portrait_panel := PanelContainer.new()
	portrait_panel.custom_minimum_size = Vector2(230, 285)
	portrait_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.02, 0.02, 0.018, 0.70), Color(0.35, 0.48, 0.50, 0.80), 1))
	body.add_child(portrait_panel)
	var portrait_stack := VBoxContainer.new()
	portrait_stack.add_theme_constant_override("separation", 6)
	portrait_panel.add_child(portrait_stack)
	var portrait_title := Label.new()
	portrait_title.text = "R-17 維修艙"
	portrait_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	portrait_stack.add_child(portrait_title)
	var portrait := TextureRect.new()
	portrait.custom_minimum_size = Vector2(190, 170)
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture = _player_preview_texture()
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	portrait_stack.add_child(portrait)
	var vitals := Label.new()
	vitals.text = "HP %d/%d\nEP %d/%d\n攻擊 %+d  防禦 %+d  速度 %+d" % [
		GameState.hp,
		GameState.get_max_hp(),
		GameState.ep,
		GameState.get_max_ep(),
		GameState.get_stat_bonus("attack"),
		GameState.get_stat_bonus("defense"),
		GameState.get_stat_bonus("speed")
	]
	vitals.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	portrait_stack.add_child(vitals)

	var equipment_stack := VBoxContainer.new()
	equipment_stack.add_theme_constant_override("separation", 8)
	body.add_child(equipment_stack)
	_add_equipment_card(equipment_stack, "近戰武器", "weapon")
	_add_equipment_card(equipment_stack, "遠程武器", "ranged")
	_add_equipment_card(equipment_stack, "護甲", "armor")
	_add_equipment_card(equipment_stack, "工具", "tool")
	var upgrades := HBoxContainer.new()
	upgrades.add_theme_constant_override("separation", 6)
	equipment_stack.add_child(upgrades)
	_add_upgrade_button(upgrades, "HP", "hp")
	_add_upgrade_button(upgrades, "EP", "ep")
	_add_upgrade_button(upgrades, "攻擊", "attack")
	_add_upgrade_button(upgrades, "防禦", "defense")

	inventory_list.add_child(HSeparator.new())
	var bag_title := Label.new()
	bag_title.text = "背包物品（點擊裝備可穿戴）"
	bag_title.add_theme_font_size_override("font_size", 17)
	inventory_list.add_child(bag_title)
	var bag_grid := GridContainer.new()
	bag_grid.columns = 3
	bag_grid.add_theme_constant_override("h_separation", 8)
	bag_grid.add_theme_constant_override("v_separation", 8)
	inventory_list.add_child(bag_grid)
	for item_id in GameState.inventory.keys():
		_add_bag_button(bag_grid, String(item_id), int(GameState.inventory[item_id]))

func _add_equipment_card(container: VBoxContainer, label_text: String, slot: String) -> void:
	var item_id := String(GameState.equipment.get(slot, ""))
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(470, 66)
	card.add_theme_stylebox_override("panel", _panel_style(Color(0.03, 0.035, 0.035, 0.64), Color(0.22, 0.30, 0.32, 0.80), 1))
	container.add_child(card)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	card.add_child(row)
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(62, 52)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.texture = _item_icon(item_id)
	row.add_child(icon)
	var text := VBoxContainer.new()
	row.add_child(text)
	var label := Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(0.70, 0.82, 0.82))
	text.add_child(label)
	var value := Label.new()
	value.text = GameState.item_display_name(item_id)
	value.add_theme_font_size_override("font_size", 16)
	text.add_child(value)

func _add_upgrade_button(container: HBoxContainer, label_text: String, kind: String) -> void:
	var button := Button.new()
	button.text = label_text
	button.custom_minimum_size = Vector2(72, 34)
	button.disabled = GameState.upgrade_points <= 0
	button.pressed.connect(func() -> void:
		if GameState.spend_upgrade_point(kind):
			_refresh_inventory()
			_refresh()
	)
	container.add_child(button)

func _add_bag_button(container: GridContainer, item_id: String, amount: int) -> void:
	var button := Button.new()
	button.custom_minimum_size = Vector2(250, 62)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.text = "%s x%d" % [GameState.item_display_name(item_id), amount]
	button.icon = _item_icon(item_id)
	button.expand_icon = true
	button.pressed.connect(_equip_from_inventory.bind(item_id))
	container.add_child(button)

func _item_icon(item_id: String) -> Texture2D:
	var resource := DataRegistry.get_resource(item_id)
	var equipment := DataRegistry.get_equipment(item_id)
	var asset_id := String(resource.get("icon_asset_id", equipment.get("icon_asset_id", "")))
	if not asset_id.is_empty():
		var texture := ASSET_LOADER.load_png(DataRegistry.asset_path(asset_id))
		if texture != null:
			return texture
	return PIXEL.new().item_texture(item_id)

func _player_preview_texture() -> Texture2D:
	var atlas := ASSET_LOADER.load_png("res://assets/sprites/player/recycler_player_multiaction_8dir.png")
	if atlas == null:
		return PIXEL.new().player_texture(2, 0, 1)
	var texture := AtlasTexture.new()
	texture.atlas = atlas
	texture.region = Rect2(0, 2 * PixelArtFactory.PLAYER_FRAME_SIZE.y, PixelArtFactory.PLAYER_FRAME_SIZE.x, PixelArtFactory.PLAYER_FRAME_SIZE.y)
	return texture

func _equip_from_inventory(item_id: String) -> void:
	if not DataRegistry.get_equipment(item_id).is_empty():
		GameState.equip_item(item_id)
		_refresh_inventory()

func _attack_mode_label(mode: String) -> String:
	match mode:
		"ranged":
			return "遠程"
		"melee":
			return "近戰"
		"tool":
			return "工具"
		_:
			return "資源"

func _show_notice(message: String) -> void:
	notice_label.text = message
	notice_label.visible = true
	notice_timer.start(2.4)

func _show_dialogue(speaker: String, role: String, message: String) -> void:
	dialogue_speaker.text = speaker
	dialogue_role.text = role
	dialogue_body.text = message
	dialogue_portrait.texture = _portrait_for_speaker(speaker)
	dialogue_panel.visible = true
	dialogue_timer.start(10.0)
	_refresh_overlay_visibility()
	_layout()

func _portrait_for_speaker(speaker: String) -> Texture2D:
	for npc in DataRegistry.npcs:
		if String(npc.get("name", "")) == speaker:
			var asset_id := String(npc.get("portrait_asset_id", npc.get("sprite_asset_id", "")))
			var texture := ASSET_LOADER.load_png(DataRegistry.asset_portrait_path(asset_id, DataRegistry.asset_path(asset_id)))
			if texture != null:
				return texture
	return _player_preview_texture()

func _hide_dialogue() -> void:
	if dialogue_panel == null:
		return
	dialogue_panel.visible = false
	if dialogue_timer != null:
		dialogue_timer.stop()
	_refresh_overlay_visibility()

func _make_bar(fill_color: Color, bg_color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(330, 16)
	bar.show_percentage = false
	bar.add_theme_stylebox_override("background", _panel_style(bg_color, Color(0.10, 0.10, 0.10, 0.85), 1))
	bar.add_theme_stylebox_override("fill", _panel_style(fill_color, fill_color.lightened(0.25), 1))
	return bar

func _bar_row(label_text: String, bar: ProgressBar) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(34, 18)
	label.add_theme_font_size_override("font_size", 13)
	row.add_child(label)
	row.add_child(bar)
	return row

func _panel_style(bg: Color, border: Color, border_width := 1) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.border_width_left = border_width
	style.border_width_right = border_width
	style.border_width_top = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style

func _button_style(selected: bool) -> StyleBoxFlat:
	if selected:
		return _panel_style(Color(0.18, 0.18, 0.14, 0.92), Color(1.0, 0.72, 0.28, 1.0), 2)
	return _panel_style(Color(0.05, 0.05, 0.048, 0.82), Color(0.30, 0.28, 0.24, 0.88), 1)
