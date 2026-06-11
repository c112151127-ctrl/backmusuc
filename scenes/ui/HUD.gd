extends CanvasLayer

var stats_label: Label
var quest_label: Label
var quick_bar: HBoxContainer
var inventory_panel: PanelContainer
var inventory_list: VBoxContainer
var notice_label: Label
var notice_timer: Timer
var minimap_panel: PanelContainer
var tutorial_panel: PanelContainer

func _ready() -> void:
	_build_hud()
	GameState.stats_changed.connect(_refresh)
	GameState.inventory_changed.connect(_refresh_inventory)
	GameState.equipment_changed.connect(_refresh_inventory)
	GameState.equipment_changed.connect(_refresh_hotbar)
	GameState.notification_requested.connect(_show_notice)
	_refresh()
	_refresh_inventory()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("open_inventory"):
		inventory_panel.visible = not inventory_panel.visible
	if Input.is_action_just_pressed("toggle_minimap"):
		minimap_panel.visible = not minimap_panel.visible
	if Input.is_action_just_pressed("toggle_help"):
		tutorial_panel.visible = not tutorial_panel.visible

func _build_hud() -> void:
	var root := Control.new()
	root.name = "HudRoot"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	var top_bar := PanelContainer.new()
	top_bar.position = Vector2(16, 16)
	top_bar.custom_minimum_size = Vector2(700, 96)
	root.add_child(top_bar)

	var top_stack := VBoxContainer.new()
	top_bar.add_child(top_stack)

	stats_label = Label.new()
	stats_label.add_theme_font_size_override("font_size", 18)
	top_stack.add_child(stats_label)

	quest_label = Label.new()
	quest_label.add_theme_font_size_override("font_size", 16)
	quest_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	top_stack.add_child(quest_label)

	notice_label = Label.new()
	notice_label.position = Vector2(16, 122)
	notice_label.add_theme_font_size_override("font_size", 18)
	notice_label.visible = false
	root.add_child(notice_label)

	notice_timer = Timer.new()
	notice_timer.one_shot = true
	notice_timer.timeout.connect(func() -> void: notice_label.visible = false)
	add_child(notice_timer)

	inventory_panel = PanelContainer.new()
	inventory_panel.name = "InventoryPanel"
	inventory_panel.position = Vector2(16, 156)
	inventory_panel.custom_minimum_size = Vector2(420, 470)
	inventory_panel.visible = false
	root.add_child(inventory_panel)

	inventory_list = VBoxContainer.new()
	inventory_panel.add_child(inventory_list)

	_add_quick_bar(root)
	_add_minimap(root)
	_add_tutorial(root)
	_add_controls_hint(root)

func _add_quick_bar(root: Control) -> void:
	var panel := PanelContainer.new()
	panel.name = "QuickBarPanel"
	panel.position = Vector2(456, 646)
	panel.custom_minimum_size = Vector2(360, 58)
	root.add_child(panel)
	quick_bar = HBoxContainer.new()
	quick_bar.name = "QuickBar"
	quick_bar.add_theme_constant_override("separation", 6)
	panel.add_child(quick_bar)

func _add_minimap(root: Control) -> void:
	minimap_panel = PanelContainer.new()
	minimap_panel.name = "MiniMapPanel"
	minimap_panel.add_to_group("minimap_panel")
	minimap_panel.position = Vector2(1040, 18)
	minimap_panel.custom_minimum_size = Vector2(214, 154)
	minimap_panel.visible = false
	root.add_child(minimap_panel)
	var map_stack := VBoxContainer.new()
	minimap_panel.add_child(map_stack)
	var title := Label.new()
	title.text = "地圖  M"
	title.add_theme_font_size_override("font_size", 15)
	map_stack.add_child(title)
	var map := ColorRect.new()
	map.custom_minimum_size = Vector2(188, 96)
	map.color = Color(0.08, 0.09, 0.08, 0.88)
	map_stack.add_child(map)
	var hint := Label.new()
	hint.text = "村莊 ⇄ 公會 ⇄ 廢土"
	hint.add_theme_font_size_override("font_size", 13)
	map_stack.add_child(hint)

func _add_tutorial(root: Control) -> void:
	tutorial_panel = PanelContainer.new()
	tutorial_panel.name = "TutorialPanel"
	tutorial_panel.add_to_group("tutorial_panel")
	tutorial_panel.position = Vector2(820, 430)
	tutorial_panel.custom_minimum_size = Vector2(400, 188)
	tutorial_panel.visible = false
	root.add_child(tutorial_panel)
	var stack := VBoxContainer.new()
	tutorial_panel.add_child(stack)
	var title := Label.new()
	title.text = "廢土回收商：PC 操作"
	title.add_theme_font_size_override("font_size", 18)
	stack.add_child(title)
	var body := Label.new()
	body.text = "WASD 移動｜滑鼠左鍵按住射擊｜空白近戰\nE 互動｜I 背包｜Q 切換快捷欄｜1-4 選裝備\nM 地圖｜H 關閉教學\n流程：整備 → 接任務 → 進廢土 → 回村強化"
	body.add_theme_font_size_override("font_size", 14)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(body)

func _add_controls_hint(root: Control) -> void:
	var hint := Label.new()
	hint.text = "左鍵按住射擊｜空白近戰｜E 互動｜H 教學｜M 地圖"
	hint.position = Vector2(456, 614)
	hint.add_theme_font_size_override("font_size", 14)
	root.add_child(hint)

func _refresh() -> void:
	stats_label.text = "HP %d/%d   EP %d/%d   彈藥 %d   廢鐵 %d   核心 %d   場景 %s" % [
		GameState.hp,
		GameState.MAX_HP,
		GameState.ep,
		GameState.MAX_EP,
		GameState.ammo,
		GameState.scrap,
		GameState.cores,
		GameState.current_scene_id
	]
	quest_label.text = "委託：%s" % GameState.active_quest_summary()
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
		button.custom_minimum_size = Vector2(82, 44)
		button.add_to_group("hotbar_slot")
		button.set_meta("quick_slot_index", i)
		button.text = "%d %s" % [i + 1, _short_name(item_id)]
		if i == GameState.active_quick_slot:
			button.text = "> " + button.text
		button.pressed.connect(GameState.use_quick_slot.bind(i))
		quick_bar.add_child(button)

func _refresh_inventory() -> void:
	for child in inventory_list.get_children():
		child.queue_free()
	var title := Label.new()
	title.text = "背包 / 裝備  (I 開關，點裝備可裝上)"
	title.add_theme_font_size_override("font_size", 18)
	inventory_list.add_child(title)
	var equipped := Label.new()
	equipped.text = "目前裝備: %s" % JSON.stringify(GameState.equipment)
	equipped.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inventory_list.add_child(equipped)
	var quest := Label.new()
	quest.text = "委託進度: %s" % GameState.active_quest_summary()
	quest.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inventory_list.add_child(quest)
	for item_id in GameState.inventory.keys():
		var amount := int(GameState.inventory[item_id])
		var row := Button.new()
		row.text = "%s x%d" % [_display_name(String(item_id)), amount]
		row.alignment = HORIZONTAL_ALIGNMENT_LEFT
		row.pressed.connect(_equip_from_inventory.bind(String(item_id)))
		inventory_list.add_child(row)

func _equip_from_inventory(item_id: String) -> void:
	if DataRegistry.get_equipment(item_id).size() > 0:
		GameState.equip_item(item_id)

func _display_name(item_id: String) -> String:
	if DataRegistry.get_equipment(item_id).size() > 0:
		return String(DataRegistry.get_equipment(item_id).get("name", item_id))
	if DataRegistry.get_resource(item_id).size() > 0:
		return String(DataRegistry.get_resource(item_id).get("name", item_id))
	return item_id

func _short_name(item_id: String) -> String:
	var name := _display_name(item_id)
	if name.length() > 5:
		return name.substr(0, 5)
	return name

func _show_notice(message: String) -> void:
	notice_label.text = message
	notice_label.visible = true
	notice_timer.start(2.4)
