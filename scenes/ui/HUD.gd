extends CanvasLayer

var stats_label: Label
var quest_label: Label
var quick_bar: HBoxContainer
var inventory_panel: PanelContainer
var inventory_list: VBoxContainer
var notice_label: Label
var notice_timer: Timer

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
	_add_touch_dpad(root)
	_add_action_buttons(root)

func _add_quick_bar(root: Control) -> void:
	var panel := PanelContainer.new()
	panel.name = "QuickBarPanel"
	panel.position = Vector2(430, 646)
	panel.custom_minimum_size = Vector2(360, 58)
	root.add_child(panel)
	quick_bar = HBoxContainer.new()
	quick_bar.name = "QuickBar"
	quick_bar.add_theme_constant_override("separation", 6)
	panel.add_child(quick_bar)

func _add_touch_dpad(root: Control) -> void:
	var dpad := GridContainer.new()
	dpad.name = "TouchMoveDPad"
	dpad.columns = 3
	dpad.position = Vector2(28, 516)
	dpad.add_theme_constant_override("h_separation", 4)
	dpad.add_theme_constant_override("v_separation", 4)
	root.add_child(dpad)
	_add_dpad_spacer(dpad)
	_add_hold_button(dpad, "上", "move_up")
	_add_dpad_spacer(dpad)
	_add_hold_button(dpad, "左", "move_left")
	_add_dpad_spacer(dpad)
	_add_hold_button(dpad, "右", "move_right")
	_add_dpad_spacer(dpad)
	_add_hold_button(dpad, "下", "move_down")
	_add_dpad_spacer(dpad)

func _add_action_buttons(root: Control) -> void:
	var touch_box := HBoxContainer.new()
	touch_box.name = "TouchActionButtons"
	touch_box.position = Vector2(800, 610)
	touch_box.add_theme_constant_override("separation", 8)
	root.add_child(touch_box)
	_add_touch_button(touch_box, "近戰", "attack_melee")
	_add_touch_button(touch_box, "射擊", "attack_ranged")
	_add_touch_button(touch_box, "切換", "swap_weapon")
	_add_touch_button(touch_box, "互動", "interact")
	_add_touch_button(touch_box, "背包", "open_inventory")
	_add_touch_button(touch_box, "存檔", "save_game")

func _add_dpad_spacer(parent: Control) -> void:
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(58, 52)
	parent.add_child(spacer)

func _add_hold_button(parent: Control, label: String, action: String) -> void:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size = Vector2(58, 52)
	button.add_to_group("touch_control")
	button.add_to_group("touch_move_control")
	button.set_meta("input_action", action)
	button.button_down.connect(_hold_action.bind(action))
	button.button_up.connect(_release_action.bind(action))
	parent.add_child(button)

func _add_touch_button(parent: Control, label: String, action: String) -> void:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size = Vector2(72, 48)
	button.add_to_group("touch_control")
	button.add_to_group("touch_action_control")
	button.set_meta("input_action", action)
	button.pressed.connect(_pulse_action.bind(action))
	parent.add_child(button)

func _pulse_action(action: String) -> void:
	Input.action_press(action)
	await get_tree().create_timer(0.08).timeout
	Input.action_release(action)

func _hold_action(action: String) -> void:
	Input.action_press(action)

func _release_action(action: String) -> void:
	Input.action_release(action)

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
